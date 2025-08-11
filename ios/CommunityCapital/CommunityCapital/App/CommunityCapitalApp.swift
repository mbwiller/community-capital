// CommunityCapitalApp.swift
import SwiftUI
import ComposableArchitecture
import Vision
import UIKit
import Firebase

@main
struct CommunityCapitalApp: App {
    init() {
        // Initialize Firebase
        FirebaseApp.configure()
    }
    
    let store = Store(initialState: AppReducer.State()) {
        AppReducer()
            ._printChanges()
    }
    
    var body: some Scene {
        WindowGroup {
            AppView(store: store)
        }
    }
}

// MARK: - App Reducer (Root)
struct AppReducer: Reducer {
    struct State: Equatable {
        var authentication = AuthenticationReducer.State()
        var main = MainReducer.State()
        var isAuthenticated = false
        var isLoading = true
    }
    
    @CasePathable
    enum Action: Equatable {
        case authentication(AuthenticationReducer.Action)
        case main(MainReducer.Action)
        case onAppear
        case checkAuthenticationStatus
        case setAuthenticated(Bool)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.authentication, action: \.authentication) {
            AuthenticationReducer()
        }
        
        Scope(state: \.main, action: \.main) {
            MainReducer()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.checkAuthenticationStatus)
                }
                
            case .checkAuthenticationStatus:
                return .run { send in
                    let isAuthenticated = await AuthenticationClient.shared.checkAuthentication()
                    await send(.setAuthenticated(isAuthenticated))
                }
                
            case let .setAuthenticated(isAuthenticated):
                state.isAuthenticated = isAuthenticated
                state.isLoading = false
                return .none
                
            case .authentication(.loginResponse(.success)):
                state.isAuthenticated = true
                return .none
                
            case .main(.profile(.signOut)):
                state.isAuthenticated = false
                return .none
                
            default:
                return .none
            }
        }
    }
}

// MARK: - App View
struct AppView: View {
    let store: StoreOf<AppReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Group {
                if viewStore.isLoading {
                    SplashView()
                } else if viewStore.isAuthenticated {
                    MainView(
                        store: store.scope(
                            state: \.main,
                            action: \.main
                        )
                    )
                } else {
                    AuthenticationView(
                        store: store.scope(
                            state: \.authentication,
                            action: \.authentication
                        )
                    )
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
        }
    }
}

// MARK: - Main Tab Reducer
struct MainReducer: Reducer {
    struct State: Equatable {
        var selectedTab = 0
        var home = HomeReducer.State()
        var events = EventsReducer.State()
        var profile = ProfileReducer.State()
        
        // Shared state
        var currentUser: User?
        var activeEvent: BillEvent?
    }
    
    @CasePathable
    enum Action: Equatable {
        case home(HomeReducer.Action)
        case events(EventsReducer.Action)
        case profile(ProfileReducer.Action)
        case setSelectedTab(Int)
        case receiptScanned(ReceiptData)
        case eventCreated(BillEvent)
        case syncState
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.home, action: \.home) {
            HomeReducer()
        }
        
        Scope(state: \.events, action: \.events) {
            EventsReducer()
        }
        
        Scope(state: \.profile, action: \.profile) {
            ProfileReducer()
        }
        
        Reduce { state, action in
            switch action {
            case let .setSelectedTab(tab):
                state.selectedTab = tab
                return .none
                
            case let .receiptScanned(receiptData):
                // Navigate to splitting view
                state.selectedTab = 1
                return .none
                
            case let .eventCreated(event):
                state.activeEvent = event
                state.events.activeEvents.append(event)
                return .none
                
            case .syncState:
                return .run { send in
                    // Real-time sync via WebSocket
                    await WebSocketClient.shared.connect()
                }
                
            default:
                return .none
            }
        }
    }
}

// MARK: - Main View
struct MainView: View {
    let store: StoreOf<MainReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: \.selectedTab) { viewStore in
            TabView(selection: viewStore.binding(
                send: MainReducer.Action.setSelectedTab
            )) {
                HomeView(
                    store: store.scope(
                        state: \.home,
                        action: \.home
                    )
                )
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                
                EventsView(
                    store: store.scope(
                        state: \.events,
                        action: \.events
                    )
                )
                .tabItem {
                    Label("Events", systemImage: "person.3.fill")
                }
                .tag(1)
                
                ProfileView(
                    store: store.scope(
                        state: \.profile,
                        action: \.profile
                    )
                )
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
            }
            .tint(.green)
        }
    }
}

// MARK: - Home Reducer
struct HomeReducer: Reducer {
    struct State: Equatable {
        var isScanning = false
        var showJoinEvent = false
        var joinCode = ""
        var recentActivity: [BillEvent] = []
        var scannerState = ReceiptScannerReducer.State()
        @PresentationState var destination: Destination.State?
    }
    
    @CasePathable
    enum Action: Equatable {
        case startScanTapped
        case joinEventTapped
        case scanner(ReceiptScannerReducer.Action)
        case setJoinCode(String)
        case joinEvent
        case loadRecentActivity
        case recentActivityLoaded([BillEvent])
        case destination(PresentationAction<Destination.Action>)
    }
    
    struct Destination: Reducer {
        @CasePathable
        enum State: Equatable {
            case scanner(ReceiptScannerReducer.State)
            case joinEvent(JoinEventReducer.State)
        }
        
        @CasePathable
        enum Action: Equatable {
            case scanner(ReceiptScannerReducer.Action)
            case joinEvent(JoinEventReducer.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: \.scanner, action: \.scanner) {
                ReceiptScannerReducer()
            }
            Scope(state: \.joinEvent, action: \.joinEvent) {
                JoinEventReducer()
            }
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startScanTapped:
                state.destination = .scanner(ReceiptScannerReducer.State())
                return .none
                
            case .joinEventTapped:
                state.destination = .joinEvent(JoinEventReducer.State())
                return .none
                
            case .loadRecentActivity:
                return .run { send in
                    let events = try await APIClient.shared.fetchRecentEvents()
                    await send(.recentActivityLoaded(events))
                }
                
            case let .recentActivityLoaded(events):
                state.recentActivity = events
                return .none
                
            default:
                return .none
            }
        }
        .ifLet(\.$destination, action: \.destination) {
            Destination()
        }
    }
}

// MARK: - Receipt Scanner Reducer
struct ReceiptScannerReducer: Reducer {
    struct State: Equatable {
        var scannedImage: UIImage?
        var parsedItems: [BillItem] = []
        var isProcessing = false
        var eventName = ""
        var restaurantName = ""
        var errorMessage: String?
        var confidenceScore: Double = 0.0
        
        var selectedItemsTotal: Double {
            parsedItems.filter { $0.isSelected }.reduce(0) { $0 + $1.price * Double($1.quantity) }
        }
    }
    
    enum Action: Equatable {
        case imageCaptured(UIImage)
        case processReceipt
        case receiptProcessed(Result<ParsedReceipt, ReceiptError>)
        case setEventName(String)
        case setRestaurantName(String)
        case itemEdited(id: String, BillItem)
        case toggleItemSelection(Int)
        case manualItemsAdded([BillItem])
        case createEvent
        case eventCreated(Result<BillEvent, APIError>)
        case dismissError
    }
    
    @Dependency(\.receiptParser) var receiptParser
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.analytics) var analytics
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .imageCaptured(image):
                state.scannedImage = image
                return .send(.processReceipt)
                
            case .processReceipt:
                guard let image = state.scannedImage else { return .none }
                state.isProcessing = true
                
                return .run { send in
                    do {
                        let result = try await receiptParser.parse(image)
                        await send(.receiptProcessed(.success(result)))
                    } catch let error as ReceiptError {
                        await send(.receiptProcessed(.failure(error)))
                    } catch {
                        await send(.receiptProcessed(.failure(.parsingFailed)))
                    }
                }
                
            case let .receiptProcessed(.success(parsed)):
                state.isProcessing = false
                state.parsedItems = parsed.items
                state.restaurantName = parsed.merchantName ?? ""
                state.confidenceScore = parsed.confidence
                
                // Track successful scan
                analytics.track("receipt_scanned", [
                    "item_count": parsed.items.count,
                    "confidence": parsed.confidence
                ])
                
                return .none
                
            case let .receiptProcessed(.failure(error)):
                state.isProcessing = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case let .setEventName(name):
                state.eventName = name
                return .none
                
            case let .setRestaurantName(name):
                state.restaurantName = name
                return .none
                
            case let .itemEdited(id, updatedItem):
                if let index = state.parsedItems.firstIndex(where: { $0.id == id }) {
                    state.parsedItems[index] = updatedItem
                }
                return .none
                
            case let .toggleItemSelection(index):
                guard index < state.parsedItems.count else { return .none }
                state.parsedItems[index].isSelected.toggle()
                return .none
                
            case let .manualItemsAdded(items):
                state.parsedItems = items
                state.isProcessing = false
                return .none
                
            case .createEvent:
                guard !state.eventName.isEmpty && state.selectedItemsTotal > 0 else { return .none }
                
                let selectedItems = state.parsedItems.filter { $0.isSelected }
                let event = BillEvent(
                    id: UUID().uuidString,
                    creatorId: "current_user_id",
                    eventName: state.eventName,
                    restaurantName: state.restaurantName,
                    totalAmount: state.selectedItemsTotal,
                    tax: 0,
                    tipPercentage: 18,
                    receiptImageURL: nil,
                    items: selectedItems,
                    participants: [],
                    status: .draft,
                    createdAt: Date(),
                    virtualCardId: nil
                )
                
                return .run { send in
                    do {
                        let createdEvent = try await apiClient.createEventFromBillEvent(event)
                        await send(.eventCreated(.success(createdEvent)))
                    } catch {
                        await send(.eventCreated(.failure(error as? APIError ?? .serverError(error.localizedDescription))))
                    }
                }
                
            case let .eventCreated(.success(event)):
                // Event created successfully, could navigate to event details
                analytics.track("event_created", [
                    "event_id": event.id,
                    "item_count": event.items.count,
                    "total_amount": event.totalAmount
                ])
                return .none
                
            case let .eventCreated(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none
                
            case .dismissError:
                state.errorMessage = nil
                return .none
            }
        }
    }
}

// MARK: - Enhanced Receipt Parser with ML
struct EnhancedReceiptParser {
    func parse(_ image: UIImage) async throws -> ParsedReceipt {
        // Use Vision framework for OCR
        let textRecognition = VNRecognizeTextRequest()
        textRecognition.recognitionLevel = .accurate
        textRecognition.usesLanguageCorrection = true
        
        // Process image
        guard let cgImage = image.cgImage else {
            throw ReceiptError.invalidImage
        }
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([textRecognition])
        
        // Extract text
        let observations = textRecognition.results ?? []
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        
        // ML-enhanced parsing with confidence scoring
        let items = parseItemsWithConfidence(from: lines)
        let merchantName = extractMerchantName(from: lines)
        let confidence = calculateConfidence(items: items, lines: lines)
        
        // Store for training data
        await storeTrainingData(image: image, items: items, confidence: confidence)
        
        return ParsedReceipt(
            items: items,
            merchantName: merchantName,
            confidence: confidence,
            rawText: lines
        )
    }
    
    private func parseItemsWithConfidence(from lines: [String]) -> [BillItem] {
        var items: [BillItem] = []
        let pricePattern = #"\$?(\d+\.\d{2})"#
        let priceRegex = try! NSRegularExpression(pattern: pricePattern)
        
        for line in lines {
            let range = NSRange(location: 0, length: line.utf16.count)
            if let match = priceRegex.firstMatch(in: line, range: range) {
                let priceRange = Range(match.range(at: 1), in: line)!
                let price = Double(line[priceRange]) ?? 0
                
                // Extract item name (everything before the price)
                let itemName = String(line[..<line.index(line.startIndex, offsetBy: match.range.location)])
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !itemName.isEmpty && price > 0 {
                    items.append(BillItem(
                        id: UUID().uuidString,
                        name: itemName,
                        price: price,
                        quantity: 1,
                        claimedBy: [],
                        isSharedByTable: false,
                        isSelected: true
                    ))
                }
            }
        }
        
        return items
    }
    
    private func calculateConfidence(items: [BillItem], lines: [String]) -> Double {
        var score = 0.0
        
        // Check if we found items
        if !items.isEmpty { score += 0.3 }
        
        // Check for common receipt keywords
        let keywords = ["total", "subtotal", "tax", "tip"]
        let keywordCount = lines.filter { line in
            keywords.contains { line.lowercased().contains($0) }
        }.count
        score += min(Double(keywordCount) * 0.1, 0.3)
        
        // Check price format consistency
        let validPrices = items.filter { $0.price > 0 && $0.price < 1000 }.count
        score += min(Double(validPrices) / Double(items.count) * 0.4, 0.4)
        
        return min(score, 1.0)
    }
    
    private func extractMerchantName(from lines: [String]) -> String? {
        guard !lines.isEmpty else { return nil }
        
        for line in lines.prefix(5) {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if !trimmed.isEmpty &&
                !trimmed.contains(where: { $0.isNumber }) &&
                trimmed.count > 3 {
                return trimmed
            }
        }
        
        return nil
    }
    
    private func storeTrainingData(image: UIImage, items: [BillItem], confidence: Double) async {
        let trainingData = TrainingData(
            imageData: image.jpegData(compressionQuality: 0.8),
            items: items,
            confidence: confidence,
            timestamp: Date()
        )
        
        await AnalyticsManager.shared.logTrainingData(trainingData)
    }
}

// MARK: - Models with Equatable Conformance
struct User: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var email: String
    var phoneNumber: String
    var profileImageURL: String?
    var linkedBankToken: String?
    var stripeCustomerId: String?
}

struct BillEvent: Identifiable, Codable, Equatable {
    var id: String
    var creatorId: String
    var eventName: String
    var restaurantName: String
    var totalAmount: Double
    var tax: Double
    var tipPercentage: Double
    var receiptImageURL: String?
    var items: [BillItem]
    var participants: [EventParticipant]
    var status: EventStatus
    var createdAt: Date
    var virtualCardId: String?
    
    enum EventStatus: String, Codable, Equatable {
        case draft, awaitingParticipants, itemsClaimed, paymentPending, completed, failed
    }
}

struct BillItem: Identifiable, Codable, Equatable {
    let id: String
    var name: String
    var price: Double
    var quantity: Int
    var claimedBy: [String]
    var isSharedByTable: Bool
    var isSelected: Bool = false
    
    var pricePerPerson: Double {
        guard !claimedBy.isEmpty else { return price }
        return price / Double(claimedBy.count)
    }
}

struct EventParticipant: Identifiable, Codable, Equatable {
    let id: String
    var userId: String
    var userName: String
    var subtotal: Double
    var taxAmount: Double
    var tipAmount: Double
    var totalOwed: Double
    var paymentStatus: PaymentStatus
    var paymentIntentId: String?
    
    enum PaymentStatus: String, Codable, Equatable {
        case pending, processing, completed, failed
    }
}

struct ParsedReceipt: Equatable {
    let items: [BillItem]
    let merchantName: String?
    let confidence: Double
    let rawText: [String]
}

struct ReceiptData: Equatable {
    let image: UIImage
    let items: [BillItem]
}

struct TrainingData: Codable {
    let imageData: Data?
    let items: [BillItem]
    let confidence: Double
    let timestamp: Date
}

enum ReceiptError: Error, LocalizedError, Equatable {
    case invalidImage
    case parsingFailed
    case lowConfidence
    
    var errorDescription: String? {
        switch self {
        case .invalidImage: return "Invalid image format"
        case .parsingFailed: return "Could not parse receipt"
        case .lowConfidence: return "Low confidence in parsed results"
        }
    }
}

enum APIError: Error, LocalizedError, Equatable {
    case networkError
    case invalidResponse
    case serverError(String)
    case notFound
    case unauthorized
    
    var errorDescription: String? {
        switch self {
        case .networkError: return "Network connection error"
        case .invalidResponse: return "Invalid server response"
        case .serverError(let message): return message
        case .notFound: return "Resource not found"
        case .unauthorized: return "Unauthorized"
        }
    }
}

// MARK: - WebSocket Client (placeholder)
final class WebSocketClient {
    static let shared = WebSocketClient()
    
    private init() {}
    
    func connect() async {
        // In production, this would establish WebSocket connection
        print("🔌 WebSocket connected")
    }
}
