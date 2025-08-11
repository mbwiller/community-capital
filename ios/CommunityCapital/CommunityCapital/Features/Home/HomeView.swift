// HomeView.swift
import SwiftUI
import ComposableArchitecture

struct HomeView: View {
    let store: StoreOf<HomeReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 20) {
                    // Welcome Card
                    WelcomeCard(userName: "User")
                    
                    // Quick Actions
                    HStack(spacing: 16) {
                        QuickActionButton(
                            title: "Start Split",
                            icon: "camera.fill",
                            color: .green
                        ) {
                            viewStore.send(.startScanTapped)
                        }
                        
                        QuickActionButton(
                            title: "Join Event",
                            icon: "person.badge.plus.fill",
                            color: .blue
                        ) {
                            viewStore.send(.joinEventTapped)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity
                    if !viewStore.recentActivity.isEmpty {
                        RecentActivitySection(events: viewStore.recentActivity)
                    }
                }
            }
            .navigationTitle("Community Capital")
            .onAppear {
                viewStore.send(.loadRecentActivity)
            }
        }
    }
}

struct WelcomeCard: View {
    let userName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Welcome back, \(userName)!")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("Ready to split your next bill?")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.green.opacity(0.3), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

struct RecentActivitySection: View {
    let events: [BillEvent]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .padding(.horizontal)
            
            ForEach(events.prefix(5)) { event in
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(event.eventName)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        
                        Text(event.createdAt, style: .date)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Text("$\(event.totalAmount, specifier: "%.2f")")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding()
                .background(Color.gray.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal)
            }
        }
    }
}
