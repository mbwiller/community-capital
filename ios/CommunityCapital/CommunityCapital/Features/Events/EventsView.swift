//
//  EventsView.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import SwiftUI
import ComposableArchitecture

struct EventsView: View {
    let store: StoreOf<EventsReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Events")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(CCDesign.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        if viewStore.activeEvents.isEmpty {
                            VStack(spacing: 16) {
                                Image(systemName: "calendar.badge.exclamationmark")
                                    .font(.system(size: 60))
                                    .foregroundColor(CCDesign.textTertiary)
                                
                                Text("No active events")
                                    .font(.system(size: 18))
                                    .foregroundColor(CCDesign.textSecondary)
                            }
                            .padding(.top, 100)
                        } else {
                            ForEach(viewStore.activeEvents) { event in
                                EventRow(event: event)
                                    .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
                .navigationBarHidden(true)
            }
            .onAppear {
                viewStore.send(.loadEvents)
            }
        }
    }
}

struct EventRow: View {
    let event: BillEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(event.eventName)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(CCDesign.textPrimary)
                
                Spacer()
                
                StatusBadge(status: event.status)
            }
            
            Text(event.restaurantName)
                .font(.system(size: 14))
                .foregroundColor(CCDesign.textSecondary)
            
            HStack {
                Label("\(event.participants.count) people", systemImage: "person.2.fill")
                    .font(.system(size: 12))
                    .foregroundColor(CCDesign.textSecondary)
                
                Spacer()
                
                Text(String(format: "$%.2f", event.totalAmount))
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(CCDesign.textPrimary)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        .shadow(color: CCDesign.cardShadow, radius: 4, x: 0, y: 2)
    }
}

struct StatusBadge: View {
    let status: BillEvent.EventStatus
    
    var statusConfig: (text: String, color: Color) {
        switch status {
        case .completed: return ("Settled", CCDesign.success)
        case .paymentPending: return ("Pending", CCDesign.warning)
        case .itemsClaimed: return ("Splitting", CCDesign.info)
        case .awaitingParticipants: return ("Waiting", CCDesign.textSecondary)
        case .draft: return ("Draft", CCDesign.textTertiary)
        case .failed: return ("Failed", CCDesign.error)
        }
    }
    
    var body: some View {
        Text(statusConfig.text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(statusConfig.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(statusConfig.color.opacity(0.1))
            )
    }
}
