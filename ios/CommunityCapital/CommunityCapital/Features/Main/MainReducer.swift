//
//  MainReducer.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import ComposableArchitecture

struct MainReducer: Reducer {
    struct State: Equatable {
        var selectedTab = 0
        var home = HomeReducer.State()
        var events = EventsReducer.State()
        var profile = ProfileReducer.State()
        var currentUser: User?
        var activeEvent: BillEvent?
    }
    
    enum Action: Equatable {
        case home(HomeReducer.Action)
        case events(EventsReducer.Action)
        case profile(ProfileReducer.Action)
        case setSelectedTab(Int)
        case receiptScanned(ParsedReceipt)
        case eventCreated(BillEvent)
        case syncState
    }
    
    var body: some ReducerOf<Self> {
        Scope(state: \.home, action: /Action.home) {
            HomeReducer()
        }
        
        Scope(state: \.events, action: /Action.events) {
            EventsReducer()
        }
        
        Scope(state: \.profile, action: /Action.profile) {
            ProfileReducer()
        }
        
        Reduce { state, action in
            switch action {
            case let .setSelectedTab(tab):
                state.selectedTab = tab
                return .none
                
            case let .receiptScanned(receiptData):
                state.selectedTab = 1
                return .none
                
            case let .eventCreated(event):
                state.activeEvent = event
                state.events.activeEvents.append(event)
                return .none
                
            case .syncState:
                return .run { send in
                    await WebSocketClient.shared.connect()
                }
                
            default:
                return .none
            }
        }
    }
}
