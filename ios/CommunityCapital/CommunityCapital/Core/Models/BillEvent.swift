//
//  BillEvent.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import Foundation

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
        case draft
        case awaitingParticipants
        case itemsClaimed
        case paymentPending
        case completed
        case failed
    }
}
