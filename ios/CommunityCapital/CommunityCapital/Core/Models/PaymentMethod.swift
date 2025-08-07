//
//  PaymentMethod.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import Foundation

struct PaymentMethod: Identifiable, Equatable, Codable {
    let id: String
    let type: PaymentType
    let last4: String
    let bankName: String?
    let accountType: String?
    let isDefault: Bool
    
    enum PaymentType: String, Codable {
        case bankAccount
        case debitCard
        case creditCard
    }
    
    var displayName: String {
        if let bankName = bankName {
            return "\(bankName) ••••\(last4)"
        }
        return "Account ••••\(last4)"
    }
}
