//
//  HomeView.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    let store: StoreOf<HomeReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Welcome back!")
                                    .font(.system(size: 14))
                                    .foregroundColor(CCDesign.textSecondary)
                                
                                Text("Let's split something")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundColor(CCDesign.textPrimary)
                            }
                            Spacer()
                        }
                        .padding(.top, 20)
                        
                        // Quick Actions
                        HStack(spacing: 12) {
                            QuickActionCard(
                                icon: "camera.fill",
                                title: "Scan Receipt",
                                subtitle: "Quick split"
                            ) {
                                viewStore.send(.startScanTapped)
                            }
                            
                            QuickActionCard(
                                icon: "qrcode",
                                title: "Join Event",
                                subtitle: "Enter code"
                            ) {
                                viewStore.send(.joinEventTapped)
                            }
                        }
                        
                        // Recent Activity
                        if !viewStore.recentActivity.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Recent Activity")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(CCDesign.textPrimary)
                                
                                ForEach(viewStore.recentActivity) { event in
                                    EventCard(event: event)
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .navigationBarHidden(true)
            }
            .sheet(
                store: self.store.scope(
                    state: \.$destination,
                    action: { .destination($0) }
                ),
                state: /HomeReducer.Destination.State.scanner,
                action: HomeReducer.Destination.Action.scanner
            ) { scannerStore in
                ReceiptScannerView(store: scannerStore)
            }
            .sheet(
                store: self.store.scope(
                    state: \.$destination,
                    action: { .destination($0) }
                ),
                state: /HomeReducer.Destination.State.joinEvent,
                action: HomeReducer.Destination.Action.joinEvent
            ) { joinStore in
                JoinEventView(store: joinStore)
            }
            .onAppear {
                viewStore.send(.loadRecentActivity)
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .padding(16)
            .background(CCDesign.primaryGradient)
            .cornerRadius(20)
        }
    }
}

struct EventCard: View {
    let event: BillEvent
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.eventName)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CCDesign.textPrimary)
                
                Text(event.restaurantName)
                    .font(.system(size: 14))
                    .foregroundColor(CCDesign.textSecondary)
            }
            
            Spacer()
            
            Text(String(format: "$%.2f", event.totalAmount))
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(CCDesign.textPrimary)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: CCDesign.cardShadow, radius: 4, x: 0, y: 2)
    }
}
