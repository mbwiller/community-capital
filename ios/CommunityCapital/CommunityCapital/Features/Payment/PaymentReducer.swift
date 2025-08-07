//
//  PaymentReducer.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import ComposableArchitecture

struct PaymentReducer: Reducer {
    struct State: Equatable {
        var amountOwed: Double = 0
        var eventName: String?
        var linkedAccounts: [PaymentMethod] = []
        var selectedPaymentMethod: PaymentMethod?
        var paymentStep: PaymentStep = .selectSource
        var isLoading = false
        var errorMessage: String?
        var claimedItems: [BillItem] = []
        var taxAmount: Double = 0
        var tipAmount: Double = 0
        var totalAmount: Double = 0
        var transactionId: String?
    }
    
    enum PaymentStep: Equatable {
        case selectSource
        case linkBank
        case confirmAmount
        case processing
        case completed
        case failed
    }
    
    enum Action: Equatable {
        case selectPaymentMethod(PaymentMethod)
        case linkNewBank
        case bankLinked(PaymentMethod)
        case proceedToConfirmation
        case initiatePayment
        case paymentCompleted(String)
        case paymentFailed(String)
        case retryPayment
        case changePaymentMethod
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .selectPaymentMethod(method):
            state.selectedPaymentMethod = method
            return .none
            
        case .linkNewBank:
            state.paymentStep = .linkBank
            return .none
            
        case let .bankLinked(method):
            state.linkedAccounts.append(method)
            state.selectedPaymentMethod = method
            state.paymentStep = .selectSource
            return .none
            
        case .proceedToConfirmation:
            state.paymentStep = .confirmAmount
            return .none
            
        case .initiatePayment:
            state.paymentStep = .processing
            // Simulate payment processing
            return .run { send in
                try await Task.sleep(nanoseconds: 3_000_000_000)
                await send(.paymentCompleted("TXN-\(UUID().uuidString.prefix(8))"))
            }
            
        case let .paymentCompleted(txnId):
            state.transactionId = txnId
            state.paymentStep = .completed
            return .none
            
        case let .paymentFailed(error):
            state.errorMessage = error
            state.paymentStep = .failed
            return .none
            
        case .retryPayment:
            state.paymentStep = .confirmAmount
            state.errorMessage = nil
            return .none
            
        case .changePaymentMethod:
            state.paymentStep = .selectSource
            return .none
        }
    }
}
