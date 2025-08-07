//
//  APIClient.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import Foundation

class APIClient {
    static let shared = APIClient()
    
    func fetchRecentEvents() async throws -> [BillEvent] {
        // Mock implementation
        return []
    }
    
    func createEvent(name: String, restaurant: String, items: [BillItem]) async throws -> BillEvent {
        // Mock implementation
        return BillEvent(
            id: UUID().uuidString,
            creatorId: "user1",
            eventName: name,
            restaurantName: restaurant,
            totalAmount: 0,
            tax: 0,
            tipPercentage: 0,
            receiptImageURL: nil,
            items: items,
            participants: [],
            status: .draft,
            createdAt: Date(),
            virtualCardId: nil
        )
    }
}
