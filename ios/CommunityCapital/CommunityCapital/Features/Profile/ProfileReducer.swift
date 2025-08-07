//
//  ProfileReducer.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import ComposableArchitecture

struct ProfileReducer: Reducer {
    struct State: Equatable {
        var user: User?
        var isLoading = false
    }
    
    enum Action: Equatable {
        case loadProfile
        case profileLoaded(User)
        case signOut
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .loadProfile:
            state.isLoading = true
            return .none
            
        case let .profileLoaded(user):
            state.user = user
            state.isLoading = false
            return .none
            
        case .signOut:
            state.user = nil
            return .none
        }
    }
}
