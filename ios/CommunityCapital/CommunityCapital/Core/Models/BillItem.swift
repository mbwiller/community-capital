//
//  BillItem.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import Foundation

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
