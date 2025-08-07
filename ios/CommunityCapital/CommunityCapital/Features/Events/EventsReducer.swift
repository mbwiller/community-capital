//
//  EventsReducer.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import ComposableArchitecture

struct EventsReducer: Reducer {
    struct State: Equatable {
        var activeEvents: [BillEvent] = []
        var isLoading = false
    }
    
    enum Action: Equatable {
        case loadEvents
        case eventsLoaded([BillEvent])
    }
    
    func reduce(into state: inout State, action: Action) -> Effect<Action> {
        switch action {
        case .loadEvents:
            state.isLoading = true
            return .none
            
        case let .eventsLoaded(events):
            state.activeEvents = events
            state.isLoading = false
            return .none
        }
    }
}
