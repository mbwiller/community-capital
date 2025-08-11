// APIClient.swift
import Foundation

final class APIClient {
    static let shared = APIClient()
    private let backendService = BackendService.shared
    
    private init() {}
    
    // MARK: - Event Management
    func fetchRecentEvents() async throws -> [BillEvent] {
        guard let currentUser = AuthenticationClient.shared.getCurrentUser() else {
            throw APIError.unauthorized
        }
        
        return try await backendService.fetchRecentEvents(for: currentUser.id)
    }
    
    func createEvent(eventName: String, restaurantName: String, items: [BillItem]) async throws -> BillEvent {
        guard let currentUser = AuthenticationClient.shared.getCurrentUser() else {
            throw APIError.unauthorized
        }
        
        let event = BillEvent(
            id: UUID().uuidString,
            creatorId: currentUser.id,
            eventName: eventName,
            restaurantName: restaurantName,
            totalAmount: items.reduce(0) { $0 + $1.price },
            tax: 0,
            tipPercentage: 18,
            receiptImageURL: nil,
            items: items,
            participants: [],
            status: .draft,
            createdAt: Date(),
            virtualCardId: nil
        )
        
        return try await backendService.createEvent(event)
    }
    
    func createEventFromBillEvent(_ event: BillEvent) async throws -> BillEvent {
        return try await backendService.createEvent(event)
    }
    
    func joinEvent(code: String) async throws -> BillEvent {
        return try await backendService.joinEvent(code: code)
    }
    
    func updateEvent(_ event: BillEvent) async throws {
        try await backendService.updateEvent(event)
    }
    
    // MARK: - Real-time Updates
    func listenToEvent(_ eventId: String, completion: @escaping (BillEvent?) -> Void) {
        backendService.listenToEvent(eventId, completion: completion)
    }
    
    func stopListeningToEvent(_ eventId: String) {
        backendService.stopListeningToEvent(eventId)
    }
}


