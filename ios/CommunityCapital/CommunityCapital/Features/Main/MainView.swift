//
//  MainView.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import SwiftUI
import ComposableArchitecture

struct MainView: View {
    let store: StoreOf<MainReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: \.selectedTab) { viewStore in
            TabView(selection: viewStore.binding(send: MainReducer.Action.setSelectedTab)) {
                HomeView(
                    store: store.scope(
                        state: \.home,
                        action: MainReducer.Action.home
                    )
                )
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
                
                EventsView(
                    store: store.scope(
                        state: \.events,
                        action: MainReducer.Action.events
                    )
                )
                .tabItem {
                    Label("Events", systemImage: "person.3.fill")
                }
                .tag(1)
                
                ProfileView(
                    store: store.scope(
                        state: \.profile,
                        action: MainReducer.Action.profile
                    )
                )
                .tabItem {
                    Label("Profile", systemImage: "person.crop.circle.fill")
                }
                .tag(2)
            }
            .tint(CCDesign.primaryGreen)
        }
    }
}
