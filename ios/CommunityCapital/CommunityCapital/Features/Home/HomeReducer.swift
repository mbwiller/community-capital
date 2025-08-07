//
//  HomeReducer.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import ComposableArchitecture

struct HomeReducer: Reducer {
    struct State: Equatable {
        var recentActivity: [BillEvent] = []
        var isLoading = false
        @PresentationState var destination: Destination.State?
    }
    
    enum Action: Equatable {
        case startScanTapped
        case joinEventTapped
        case loadRecentActivity
        case recentActivityLoaded([BillEvent])
        case destination(PresentationAction<Destination.Action>)
    }
    
    struct Destination: Reducer {
        enum State: Equatable {
            case scanner(ReceiptScannerReducer.State)
            case joinEvent(JoinEventReducer.State)
        }
        
        enum Action: Equatable {
            case scanner(ReceiptScannerReducer.Action)
            case joinEvent(JoinEventReducer.Action)
        }
        
        var body: some ReducerOf<Self> {
            Scope(state: /State.scanner, action: /Action.scanner) {
                ReceiptScannerReducer()
            }
            Scope(state: /State.joinEvent, action: /Action.joinEvent) {
                JoinEventReducer()
            }
        }
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startScanTapped:
                state.destination = .scanner(ReceiptScannerReducer.State())
                return .none
                
            case .joinEventTapped:
                state.destination = .joinEvent(JoinEventReducer.State())
                return .none
                
            case .loadRecentActivity:
                state.isLoading = true
                return .run { send in
                    let events = try await APIClient.shared.fetchRecentEvents()
                    await send(.recentActivityLoaded(events))
                }
                
            case let .recentActivityLoaded(events):
                state.recentActivity = events
                state.isLoading = false
                return .none
                
            default:
                return .none
            }
        }
        .ifLet(\.$destination, action: /Action.destination) {
            Destination()
        }
    }
}
