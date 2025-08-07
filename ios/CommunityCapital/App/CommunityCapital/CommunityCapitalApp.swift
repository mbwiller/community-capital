// CommunityCapitalApp.swift
import SwiftUI
import ComposableArchitecture

@main
struct CommunityCapitalApp: App {
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
    
    enum Action: Equatable {
        case authentication(AuthenticationReducer.Action)
        case main(MainReducer.Action)
        case onAppear
        case checkAuthenticationStatus
        case setAuthenticated(Bool)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.authentication, action: /Action.authentication) {
            AuthenticationReducer()
        }
        
        Scope(state: \.main, action: /Action.main) {
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
                            action: AppReducer.Action.main
                        )
                    )
                } else {
                    AuthenticationView(
                        store: store.scope(
                            state: \.authentication,
                            action: AppReducer.Action.authentication
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
        Scope(state: \.home, action: /Action.home) {
            HomeReducer()
        }
        
        Scope(state: \.events, action: /Action.events) {
            EventsReducer()
        }
        
        Scope(state: \.profile, action: /Action.profile) {
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
                        action: MainReducer.Action.home
                    )
                )
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                
                EventsView(
                    store: store.scope(
                        state: \.events,
                        action: MainReducer.Action.events
                    )
                )
                .tabItem {
                    Label("Events", systemImage: "person.3.fill")
                }
                .tag(1)
                
                ProfileView(
                    store: store.scope(
                        state: \.profile,
                        action: MainReducer.Action.profile
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
    
    enum Destination: Reducer {
        enum State: Equatable {
            case scanner(ReceiptScannerReducer.State)
            case joinEvent(JoinEventReducer.State)
        }
        
        enum Action: Equatable {
            case scanner(ReceiptScannerReducer.Action)
            case joinEvent(JoinEventReducer.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.scanner, action: /Action.scanner) {
                ReceiptScannerReducer()
            }
            Scope(state: /State.joinEvent, action: /Action.joinEvent) {
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
        .ifLet(\.$destination, action: /Action.destination) {
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
    }
    
    enum Action: Equatable {
        case imageCaptured(UIImage)
        case processReceipt
        case receiptProcessed(Result<ParsedReceipt, ReceiptError>)
        case setEventName(String)
        case setRestaurantName(String)
        case itemEdited(id: String, BillItem)
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
                    await send(.receiptProcessed(
                        Result {
                            try await receiptParser.parse(image)
                        }
                    ))
                }
                
            case let .receiptProcessed(.success(parsed)):
                state.isProcessing = false
                state.parsedItems = parsed.items
                state.restaurantName = parsed.merchantName ?? ""
                state.confidenceScore = parsed.confidence
                
                // Track successful scan
                analytics.track("receipt_scanned", properties: [
                    "item_count": parsed.items.count,
                    "confidence": parsed.confidence
                ])
                
                return .none
                
            case let .receiptProcessed(.failure(error)):
                state.isProcessing = false
                state.errorMessage = error.localizedDescription
                return .none
                
            case .createEvent:
                let items = state.parsedItems
                let eventName = state.eventName
                let restaurantName = state.restaurantName
                
                return .run { send in
                    await send(.eventCreated(
                        Result {
                            try await apiClient.createEvent(
                                name: eventName,
                                restaurant: restaurantName,
                                items: items
                            )
                        }
                    ))
                }
                
            case let .eventCreated(.success(event)):
                // Success handled by parent
                return .none
                
            case let .eventCreated(.failure(error)):
                state.errorMessage = error.localizedDescription
                return .none
                
            default:
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
        let pricePattern = #"\\$?(\d+\.\d{2})"#
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
                        isSharedByTable: false
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
    
    private func storeTrainingData(image: UIImage, items: [BillItem], confidence: Double) async {
        // Store for future ML training
        let trainingData = TrainingData(
            imageData: image.jpegData(compressionQuality: 0.8),
            items: items,
            confidence: confidence,
            timestamp: Date()
        )
        
        await AnalyticsManager.shared.logTrainingData(trainingData)
    }
}

// MARK: - Models
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
    let id: String
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
    
    enum EventStatus: String, Codable {
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
    
    enum PaymentStatus: String, Codable {
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

enum ReceiptError: Error, LocalizedError {
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

enum APIError: Error, LocalizedError {
    case networkError
    case invalidResponse
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .networkError: return "Network connection error"
        case .invalidResponse: return "Invalid server response"
        case .serverError(let message): return message
        }
    }
}
