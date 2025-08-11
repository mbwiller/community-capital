// Dependencies.swift
// CommunityCapital
//
// Created by Matt on 8/7/25.
//

// MARK: - Dependencies for The Composable Architecture
// Add this to Core/Dependencies/Dependencies.swift

import ComposableArchitecture
import Foundation
import UIKit
import Vision

// MARK: - Receipt Parser Dependency
struct ReceiptParserDependency {
    var parse: @Sendable (UIImage) async throws -> ParsedReceipt
}

extension ReceiptParserDependency: DependencyKey {
    static let liveValue = Self(
        parse: { image in
            let parser = EnhancedReceiptParser()
            return try await parser.parse(image)
        }
    )
    
    static let testValue = Self(
        parse: { _ in
            ParsedReceipt(
                items: [
                    BillItem(
                        id: "1",
                        name: "Burger",
                        price: 12.99,
                        quantity: 1,
                        claimedBy: [],
                        isSharedByTable: false,
                        isSelected: true
                    ),
                    BillItem(
                        id: "2",
                        name: "Fries",
                        price: 4.99,
                        quantity: 1,
                        claimedBy: [],
                        isSharedByTable: false,
                        isSelected: true
                    )
                ],
                merchantName: "Test Restaurant",
                confidence: 0.85,
                rawText: ["Burger $12.99", "Fries $4.99"]
            )
        }
    )
}

extension DependencyValues {
    var receiptParser: ReceiptParserDependency {
        get { self[ReceiptParserDependency.self] }
        set { self[ReceiptParserDependency.self] = newValue }
    }
}

// MARK: - Analytics Dependency
struct AnalyticsDependency {
    var track: @Sendable (String, [String: Any]) -> Void
}

extension AnalyticsDependency: DependencyKey {
    static let liveValue = Self(
        track: { event, properties in
            // In production, this would send to analytics service
            print("📊 Analytics: \(event) - \(properties)")
        }
    )
    
    static let testValue = Self(
        track: { _, _ in }
    )
}

extension DependencyValues {
    var analytics: AnalyticsDependency {
        get { self[AnalyticsDependency.self] }
        set { self[AnalyticsDependency.self] = newValue }
    }
}

// MARK: - API Client Dependency
struct APIClientDependency {
    var fetchRecentEvents: @Sendable () async throws -> [BillEvent]
    var createEvent: @Sendable (String, String, [BillItem]) async throws -> BillEvent
    var createEventFromBillEvent: @Sendable (BillEvent) async throws -> BillEvent
    var joinEvent: @Sendable (String) async throws -> BillEvent
}

extension APIClientDependency: DependencyKey {
    static let liveValue = Self(
        fetchRecentEvents: {
            try await APIClient.shared.fetchRecentEvents()
        },
        createEvent: { name, restaurant, items in
            try await APIClient.shared.createEvent(
                eventName: name,
                restaurantName: restaurant,
                items: items
            )
        },
        createEventFromBillEvent: { event in
            try await APIClient.shared.createEventFromBillEvent(event)
        },
        joinEvent: { code in
            try await APIClient.shared.joinEvent(code: code)
        }
    )
    
    static let testValue = Self(
        fetchRecentEvents: { [] },
        createEvent: { name, restaurant, items in
            BillEvent(
                id: UUID().uuidString,
                creatorId: "test",
                eventName: name,
                restaurantName: restaurant,
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
        },
        createEventFromBillEvent: { event in
            event
        },
        joinEvent: { code in
            BillEvent(
                id: UUID().uuidString,
                creatorId: "test",
                eventName: "Test Event",
                restaurantName: "Test Restaurant",
                totalAmount: 50.0,
                tax: 4.0,
                tipPercentage: 18,
                receiptImageURL: nil,
                items: [],
                participants: [],
                status: .awaitingParticipants,
                createdAt: Date(),
                virtualCardId: nil
            )
        }
    )
}

extension DependencyValues {
    var apiClient: APIClientDependency {
        get { self[APIClientDependency.self] }
        set { self[APIClientDependency.self] = newValue }
    }
}

// MARK: - Analytics Manager (for training data)
// Note: logTrainingData method is already defined in AnalyticsManager.swift
