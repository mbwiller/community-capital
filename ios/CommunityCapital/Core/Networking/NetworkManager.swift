// NetworkManager.swift
import Foundation
import Combine

// MARK: - Enhanced Network Manager with Retry Logic
final class NetworkManager: ObservableObject {
    static let shared = NetworkManager()
    
    private let session: URLSession
    private let baseURL: String
    private var cancellables = Set<AnyCancellable>()
    
    // Retry configuration
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 1.0
    private let exponentialBackoff = true
    
    // Circuit breaker pattern
    private var failureCount = 0
    private let failureThreshold = 5
    private var circuitBreakerOpenUntil: Date?
    
    init() {
        // Configure URLSession with timeout and caching
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = URLCache(
            memoryCapacity: 10 * 1024 * 1024,  // 10 MB
            diskCapacity: 50 * 1024 * 1024,     // 50 MB
            diskPath: "community_capital_cache"
        )
        
        self.session = URLSession(configuration: config)
        
        #if DEBUG
        self.baseURL = "http://localhost:3000/api"
        #else
        self.baseURL = "https://api.communitycapital.app/api"
        #endif
    }
    
    // MARK: - Generic Request with Retry Logic
    func request<T: Decodable>(
        _ endpoint: Endpoint,
        retryCount: Int = 0
    ) async throws -> T {
        // Check circuit breaker
        if let openUntil = circuitBreakerOpenUntil, Date() < openUntil {
            throw NetworkError.circuitBreakerOpen
        }
        
        do {
            // Build request
            var request = try buildRequest(for: endpoint)
            
            // Add authentication if available
            if let token = KeychainManager.shared.getToken() {
                request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            }
            
            // Add request ID for tracking
            let requestId = UUID().uuidString
            request.setValue(requestId, forHTTPHeaderField: "X-Request-ID")
            
            // Log request
            logRequest(request, id: requestId)
            
            // Perform request
            let (data, response) = try await session.data(for: request)
            
            // Validate response
            try validateResponse(response, data: data)
            
            // Decode response
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let result = try decoder.decode(T.self, from: data)
            
            // Reset circuit breaker on success
            failureCount = 0
            circuitBreakerOpenUntil = nil
            
            // Log success
            logResponse(response, data: data, id: requestId)
            
            // Store data for ML training if applicable
            await storeForTraining(endpoint: endpoint, response: result)
            
            return result
            
        } catch {
            // Handle retry logic
            if shouldRetry(error: error, retryCount: retryCount) {
                let delay = calculateRetryDelay(retryCount: retryCount)
                
                logRetry(endpoint: endpoint, retryCount: retryCount, delay: delay)
                
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                return try await request(endpoint, retryCount: retryCount + 1)
            }
            
            // Update circuit breaker
            handleFailure()
            
            throw mapError(error)
        }
    }
    
    // MARK: - Multipart Upload (for receipts)
    func uploadReceipt(
        image: UIImage,
        eventId: String
    ) async throws -> ReceiptUploadResponse {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw NetworkError.invalidInput
        }
        
        let boundary = UUID().uuidString
        var request = try buildRequest(for: .uploadReceipt(eventId: eventId))
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        // Build multipart body
        var body = Data()
        
        // Add image data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"receipt\"; filename=\"receipt.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add metadata
        let metadata = ["eventId": eventId, "timestamp": ISO8601DateFormatter().string(from: Date())]
        for (key, value) in metadata {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"\(key)\"\r\n\r\n".data(using: .utf8)!)
            body.append("\(value)\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        request.httpBody = body
        
        return try await request(.uploadReceipt(eventId: eventId))
    }
    
    // MARK: - WebSocket for Real-time Updates
    func connectWebSocket() -> AnyPublisher<WebSocketMessage, Never> {
        let subject = PassthroughSubject<WebSocketMessage, Never>()
        
        let url = URL(string: baseURL.replacingOccurrences(of: "http", with: "ws"))!
            .appendingPathComponent("ws")
        
        let task = session.webSocketTask(with: url)
        
        func receive() {
            task.receive { result in
                switch result {
                case .success(let message):
                    switch message {
                    case .string(let text):
                        if let data = text.data(using: .utf8),
                           let wsMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                            subject.send(wsMessage)
                        }
                    case .data(let data):
                        if let wsMessage = try? JSONDecoder().decode(WebSocketMessage.self, from: data) {
                            subject.send(wsMessage)
                        }
                    @unknown default:
                        break
                    }
                    receive() // Continue receiving
                    
                case .failure(let error):
                    logError(error)
                    // Attempt reconnection after delay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.connectWebSocket()
                            .sink { _ in }
                            .store(in: &self.cancellables)
                    }
                }
            }
        }
        
        task.resume()
        receive()
        
        // Send ping every 30 seconds to keep connection alive
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                task.sendPing { error in
                    if let error = error {
                        self.logError(error)
                    }
                }
            }
            .store(in: &cancellables)
        
        return subject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Helper Methods
    
    private func buildRequest(for endpoint: Endpoint) throws -> URLRequest {
        guard let url = URL(string: baseURL)?.appendingPathComponent(endpoint.path) else {
            throw NetworkError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("iOS/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")", 
                        forHTTPHeaderField: "User-Agent")
        
        // Add body if needed
        if let body = endpoint.body {
            request.httpBody = try JSONEncoder().encode(body)
        }
        
        // Add query parameters if needed
        if let queryItems = endpoint.queryItems {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.queryItems = queryItems
            request.url = components?.url
        }
        
        return request
    }
    
    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return
        case 401:
            throw NetworkError.unauthorized
        case 403:
            throw NetworkError.forbidden
        case 404:
            throw NetworkError.notFound
        case 429:
            throw NetworkError.rateLimited
        case 500...599:
            throw NetworkError.serverError(httpResponse.statusCode)
        default:
            // Try to decode error message
            if let errorResponse = try? JSONDecoder().decode(ErrorResponse.self, from: data) {
                throw NetworkError.apiError(errorResponse.message)
            }
            throw NetworkError.unknown(httpResponse.statusCode)
        }
    }
    
    private func shouldRetry(error: Error, retryCount: Int) -> Bool {
        guard retryCount < maxRetryAttempts else { return false }
        
        switch error {
        case let networkError as NetworkError:
            switch networkError {
            case .serverError, .rateLimited, .timeout:
                return true
            default:
                return false
            }
        case is URLError:
            return true
        default:
            return false
        }
    }
    
    private func calculateRetryDelay(retryCount: Int) -> TimeInterval {
        if exponentialBackoff {
            return retryDelay * pow(2.0, Double(retryCount))
        } else {
            return retryDelay
        }
    }
    
    private func handleFailure() {
        failureCount += 1
        
        if failureCount >= failureThreshold {
            // Open circuit breaker for 30 seconds
            circuitBreakerOpenUntil = Date().addingTimeInterval(30)
            logError(NetworkError.circuitBreakerOpen)
        }
    }
    
    private func mapError(_ error: Error) -> Error {
        if let networkError = error as? NetworkError {
            return networkError
        } else if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return NetworkError.noConnection
            case .timedOut:
                return NetworkError.timeout
            default:
                return NetworkError.unknown(urlError.code.rawValue)
            }
        }
        return NetworkError.unknown(0)
    }
    
    // MARK: - Logging
    
    private func logRequest(_ request: URLRequest, id: String) {
        #if DEBUG
        print("📤 [\(id)] \(request.httpMethod ?? "GET") \(request.url?.absoluteString ?? "")")
        if let headers = request.allHTTPHeaderFields {
            print("   Headers: \(headers)")
        }
        if let body = request.httpBody,
           let bodyString = String(data: body, encoding: .utf8) {
            print("   Body: \(bodyString)")
        }
        #endif
    }
    
    private func logResponse(_ response: URLResponse, data: Data, id: String) {
        #if DEBUG
        if let httpResponse = response as? HTTPURLResponse {
            print("📥 [\(id)] Status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("   Response: \(responseString)")
            }
        }
        #endif
    }
    
    private func logRetry(endpoint: Endpoint, retryCount: Int, delay: TimeInterval) {
        #if DEBUG
        print("🔄 Retrying \(endpoint.path) (attempt \(retryCount + 1)/\(maxRetryAttempts)) after \(delay)s")
        #endif
    }
    
    private func logError(_ error: Error) {
        #if DEBUG
        print("❌ Network Error: \(error.localizedDescription)")
        #endif
        
        // Send to analytics
        AnalyticsManager.shared.trackError(error)
    }
    
    // MARK: - ML Training Data Collection
    
    private func storeForTraining<T>(endpoint: Endpoint, response: T) async {
        // Store successful API responses for ML training
        guard endpoint.shouldStoreForTraining else { return }
        
        let trainingEntry = NetworkTrainingData(
            endpoint: endpoint.path,
            timestamp: Date(),
            responseTime: Date().timeIntervalSince1970,
            success: true
        )
        
        await AnalyticsManager.shared.logNetworkTraining(trainingEntry)
    }
}

// MARK: - Endpoint Definition
enum Endpoint {
    case login(phoneNumber: String)
    case verifyOTP(code: String)
    case createEvent(CreateEventRequest)
    case getEvent(id: String)
    case joinEvent(code: String)
    case claimItems(eventId: String, items: [String])
    case linkBank(plaidToken: String)
    case createPayment(PaymentRequest)
    case uploadReceipt(eventId: String)
    case getUserProfile
    case updateProfile(UpdateProfileRequest)
    
    var path: String {
        switch self {
        case .login: return "/auth/login"
        case .verifyOTP: return "/auth/verify"
        case .createEvent: return "/events"
        case .getEvent(let id): return "/events/\(id)"
        case .joinEvent: return "/events/join"
        case .claimItems(let eventId, _): return "/events/\(eventId)/claim"
        case .linkBank: return "/payments/link-bank"
        case .createPayment: return "/payments/charge"
        case .uploadReceipt(let eventId): return "/receipts/\(eventId)"
        case .getUserProfile: return "/users/profile"
        case .updateProfile: return "/users/profile"
        }
    }
    
    var method: HTTPMethod {
        switch self {
        case .getEvent, .getUserProfile:
            return .get
        case .updateProfile:
            return .patch
        default:
            return .post
        }
    }
    
    var body: Encodable? {
        switch self {
        case .login(let phoneNumber):
            return ["phoneNumber": phoneNumber]
        case .verifyOTP(let code):
            return ["code": code]
        case .createEvent(let request):
            return request
        case .joinEvent(let code):
            return ["code": code]
        case .claimItems(_, let items):
            return ["items": items]
        case .linkBank(let token):
            return ["publicToken": token]
        case .createPayment(let request):
            return request
        case .updateProfile(let request):
            return request
        default:
            return nil
        }
    }
    
    var queryItems: [URLQueryItem]? {
        return nil
    }
    
    var shouldStoreForTraining: Bool {
        switch self {
        case .claimItems, .createPayment, .uploadReceipt:
            return true
        default:
            return false
        }
    }
}

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

// MARK: - Network Errors
enum NetworkError: Error, LocalizedError {
    case invalidURL
    case invalidInput
    case invalidResponse
    case noConnection
    case timeout
    case unauthorized
    case forbidden
    case notFound
    case rateLimited
    case serverError(Int)
    case apiError(String)
    case circuitBreakerOpen
    case unknown(Int)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidInput:
            return "Invalid input data"
        case .invalidResponse:
            return "Invalid server response"
        case .noConnection:
            return "No internet connection"
        case .timeout:
            return "Request timed out"
        case .unauthorized:
            return "Please sign in again"
        case .forbidden:
            return "Access denied"
        case .notFound:
            return "Resource not found"
        case .rateLimited:
            return "Too many requests. Please try again later"
        case .serverError(let code):
            return "Server error (\(code))"
        case .apiError(let message):
            return message
        case .circuitBreakerOpen:
            return "Service temporarily unavailable"
        case .unknown(let code):
            return "Unknown error (\(code))"
        }
    }
}

// MARK: - Response Models
struct ErrorResponse: Codable {
    let message: String
    let code: String?
}

struct ReceiptUploadResponse: Codable {
    let id: String
    let url: String
    let parsedItems: [BillItem]?
}

struct CreateEventRequest: Codable {
    let name: String
    let restaurant: String
    let items: [BillItem]
    let receiptImageId: String?
}

struct PaymentRequest: Codable {
    let eventId: String
    let amount: Double
    let paymentMethodId: String
}

struct UpdateProfileRequest: Codable {
    let name: String?
    let email: String?
}

struct WebSocketMessage: Codable {
    let type: MessageType
    let payload: Data
    
    enum MessageType: String, Codable {
        case eventUpdate
        case itemClaimed
        case participantJoined
        case paymentProcessed
    }
}

struct NetworkTrainingData {
    let endpoint: String
    let timestamp: Date
    let responseTime: TimeInterval
    let success: Bool
}