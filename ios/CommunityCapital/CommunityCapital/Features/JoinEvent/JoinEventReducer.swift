//
//  JoinEventReducer.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import ComposableArchitecture

struct JoinEventReducer: Reducer {
    struct State: Equatable {
        var eventCode = ""
        var isLoading = false
        var error: String?
    }
    
    enum Action: Equatable {
        case setEventCode(String)
        case joinEvent
        case joinSuccess(BillEvent)
        case joinFailure(String)
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case let .setEventCode(code):
            state.eventCode = code
            return .none
            
        case .joinEvent:
            state.isLoading = true
            return .none
            
        case .joinSuccess:
            state.isLoading = false
            return .none
            
        case let .joinFailure(error):
            state.isLoading = false
            state.error = error
            return .none
        }
    }
}
