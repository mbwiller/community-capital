//
//  ReceiptParser.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import Foundation
import Vision
import UIKit

struct ParsedReceipt: Equatable {
    let items: [BillItem]
    let merchantName: String?
    let confidence: Double
    let rawText: [String]
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

class ReceiptParser {
    static let shared = ReceiptParser()
    
    func parse(_ image: UIImage) async throws -> ParsedReceipt {
        guard let cgImage = image.cgImage else {
            throw ReceiptError.invalidImage
        }
        
        let textRecognition = VNRecognizeTextRequest()
        textRecognition.recognitionLevel = .accurate
        textRecognition.usesLanguageCorrection = true
        
        let handler = VNImageRequestHandler(cgImage: cgImage)
        try handler.perform([textRecognition])
        
        let observations = textRecognition.results ?? []
        let lines = observations.compactMap { $0.topCandidates(1).first?.string }
        
        let items = parseItems(from: lines)
        let merchantName = extractMerchantName(from: lines)
        let confidence = calculateConfidence(items: items, lines: lines)
        
        return ParsedReceipt(
            items: items,
            merchantName: merchantName,
            confidence: confidence,
            rawText: lines
        )
    }
    
    private func parseItems(from lines: [String]) -> [BillItem] {
        var items: [BillItem] = []
        let pricePattern = #"\$?(\d+\.\d{2})"#
        let priceRegex = try! NSRegularExpression(pattern: pricePattern)
        
        for line in lines {
            let range = NSRange(location: 0, length: line.utf16.count)
            if let match = priceRegex.firstMatch(in: line, range: range) {
                let priceRange = Range(match.range(at: 1), in: line)!
                let price = Double(line[priceRange]) ?? 0
                
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
    
    private func extractMerchantName(from lines: [String]) -> String? {
        // Simple heuristic: first non-empty line is often the merchant name
        return lines.first { !$0.isEmpty && !$0.contains("$") }
    }
    
    private func calculateConfidence(items: [BillItem], lines: [String]) -> Double {
        var score = 0.0
        
        if !items.isEmpty { score += 0.3 }
        
        let keywords = ["total", "subtotal", "tax", "tip"]
        let keywordCount = lines.filter { line in
            keywords.contains { line.lowercased().contains($0) }
        }.count
        score += min(Double(keywordCount) * 0.1, 0.3)
        
        let validPrices = items.filter { $0.price > 0 && $0.price < 1000 }.count
        if !items.isEmpty {
            score += min(Double(validPrices) / Double(items.count) * 0.4, 0.4)
        }
        
        return min(score, 1.0)
    }
}
