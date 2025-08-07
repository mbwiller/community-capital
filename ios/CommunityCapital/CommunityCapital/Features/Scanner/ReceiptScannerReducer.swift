//
//  ReceiptScannerReducer.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import ComposableArchitecture
import UIKit

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
        case removeItem(String)
        case addItem(BillItem)
        case createEvent
        case eventCreated(Result<BillEvent, APIError>)
        case dismissError
        case reset
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
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
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
                        try await ReceiptParser.shared.parse(image)
                    }
                ))
            }
            
        case let .receiptProcessed(.success(parsed)):
            state.isProcessing = false
            state.parsedItems = parsed.items
            state.restaurantName = parsed.merchantName ?? ""
            state.confidenceScore = parsed.confidence
            
            AnalyticsManager.shared.track("receipt_scanned", properties: [
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
            
        case let .removeItem(id):
            state.parsedItems.removeAll { $0.id == id }
            return .none
            
        case let .addItem(item):
            state.parsedItems.append(item)
            return .none
            
        case .createEvent:
            let items = state.parsedItems
            let eventName = state.eventName
            let restaurantName = state.restaurantName
            
            return .run { send in
                await send(.eventCreated(
                    Result {
                        try await APIClient.shared.createEvent(
                            name: eventName,
                            restaurant: restaurantName,
                            items: items
                        )
                    }
                ))
            }
            
        case .eventCreated(.success):
            return .none
            
        case let .eventCreated(.failure(error)):
            state.errorMessage = error.localizedDescription
            return .none
            
        case .dismissError:
            state.errorMessage = nil
            return .none
            
        case .reset:
            state = State()
            return .none
        }
    }
}
