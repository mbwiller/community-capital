//
//  AuthenticationReducer.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import ComposableArchitecture
import Foundation

struct AuthenticationReducer: Reducer {
    struct State: Equatable {
        var phoneNumber = ""
        var verificationCode = ""
        var isLoading = false
        var showVerification = false
        var error: String?
    }
    
    enum Action: Equatable {
        case setPhoneNumber(String)
        case setVerificationCode(String)
        case sendVerificationCode
        case verifyCode
        case backToPhoneEntry
        case loginResponse(Result<User, APIError>)
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .setPhoneNumber(phone):
            state.phoneNumber = phone
            return .none
            
        case let .setVerificationCode(code):
            state.verificationCode = code
            return .none
            
        case .sendVerificationCode:
            state.isLoading = true
            state.showVerification = true
            // Mock for now
            state.isLoading = false
            return .none
            
        case .verifyCode:
            state.isLoading = true
            // Mock success for code "123456"
            if state.verificationCode == "123456" {
                return .send(.loginResponse(.success(User.mock)))
            } else {
                state.error = "Invalid code"
                state.isLoading = false
                return .none
            }
            
        case .backToPhoneEntry:
            state.showVerification = false
            state.verificationCode = ""
            return .none
            
        case .loginResponse(.success):
            state.isLoading = false
            return .none
            
        case .loginResponse(.failure):
            state.isLoading = false
            state.error = "Login failed"
            return .none
        }
    }
}
