//
//  AppReducer.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import ComposableArchitecture

struct AppReducer: Reducer {
    struct State: Equatable {
        var authentication = AuthenticationReducer.State()
        var main = MainReducer.State()
        var isAuthenticated = false
        var isLoading = true
    }
    
    enum Action: Equatable {
        case authentication(AuthenticationReducer.Action)
        case main(MainReducer.Action)
        case onAppear
        case checkAuthenticationStatus
        case setAuthenticated(Bool)
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.authentication, action: /Action.authentication) {
            AuthenticationReducer()
        }
        
        Scope(state: \.main, action: /Action.main) {
            MainReducer()
        }
        
        Reduce { state, action in
            switch action {
            case .onAppear:
                return .run { send in
                    await send(.checkAuthenticationStatus)
                }
                
            case .checkAuthenticationStatus:
                return .run { send in
                    let isAuthenticated = await AuthenticationClient.shared.checkAuthentication()
                    await send(.setAuthenticated(isAuthenticated))
                }
                
            case let .setAuthenticated(isAuthenticated):
                state.isAuthenticated = isAuthenticated
                state.isLoading = false
                return .none
                
            case .authentication(.loginResponse(.success)):
                state.isAuthenticated = true
                return .none
                
            case .main(.profile(.signOut)):
                state.isAuthenticated = false
                state.authentication = AuthenticationReducer.State()
                return .none
                
            default:
                return .none
            }
        }
    }
}
