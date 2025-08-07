//
//  EventParticipant.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import Foundation

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
        case pending
        case processing
        case completed
        case failed
    }
}
