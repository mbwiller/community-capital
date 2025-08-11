// EventsView.swift
import SwiftUI
import ComposableArchitecture

struct EventsView: View {
    let store: StoreOf<EventsReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack {
                // Segment Control
                Picker("Events", selection: viewStore.binding(
                    get: \.selectedSegment,
                    send: EventsReducer.Action.setSelectedSegment
                )) {
                    Text("Active").tag(0)
                    Text("Completed").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                if viewStore.selectedSegment == 0 {
                    ActiveEventsList(events: viewStore.activeEvents)
                } else {
                    CompletedEventsList(events: viewStore.completedEvents)
                }
            }
            .navigationTitle("Events")
        }
    }
}

struct EventsReducer: Reducer {
    struct State: Equatable {
        var selectedSegment = 0
        var activeEvents: [BillEvent] = []
        var completedEvents: [BillEvent] = []
    }
    
    @CasePathable
    enum Action: Equatable {
        case setSelectedSegment(Int)
        case loadEvents
        case eventsLoadedSuccess([BillEvent], [BillEvent])  // active, completed
        case eventsLoadedFailure(APIError)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setSelectedSegment(segment):
                state.selectedSegment = segment
                return .none
                
            case .loadEvents:
                return .run { send in
                    do {
                        let events = try await APIClient.shared.fetchRecentEvents()
                        let activeEvents = events.filter { $0.status != .completed && $0.status != .failed }
                        let completedEvents = events.filter { $0.status == .completed || $0.status == .failed }
                        await send(.eventsLoadedSuccess(activeEvents, completedEvents))
                    } catch {
                        await send(.eventsLoadedFailure(error as? APIError ?? .serverError(error.localizedDescription)))
                    }
                }
                
            case let .eventsLoadedSuccess(active, completed):
                state.activeEvents = active
                state.completedEvents = completed
                return .none
                
            case .eventsLoadedFailure:
                // Handle error if needed
                return .none
            }
        }
    }
}

struct ActiveEventsList: View {
    let events: [BillEvent]
    
    var body: some View {
        if events.isEmpty {
            EmptyStateView(
                icon: "clock",
                title: "No Active Events",
                message: "Start a new split or join an existing event"
            )
        } else {
            List(events) { event in
                EventRow(event: event)
            }
        }
    }
}

struct CompletedEventsList: View {
    let events: [BillEvent]
    
    var body: some View {
        if events.isEmpty {
            EmptyStateView(
                icon: "checkmark.circle",
                title: "No Completed Events",
                message: "Your completed bill splits will appear here"
            )
        } else {
            List(events) { event in
                EventRow(event: event)
            }
        }
    }
}

struct EventRow: View {
    let event: BillEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.eventName)
                        .font(.headline)
                    
                    Text(event.restaurantName)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                StatusBadge(status: event.status)
            }
            
            HStack {
                Label("\(event.participants.count) people", systemImage: "person.2.fill")
                    .font(.caption)
                
                Spacer()
                
                Text("$\(event.totalAmount, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }
}

struct StatusBadge: View {
    let status: BillEvent.EventStatus
    
    var color: Color {
        switch status {
        case .draft: return .gray
        case .awaitingParticipants: return .orange
        case .itemsClaimed: return .blue
        case .paymentPending: return .yellow
        case .completed: return .green
        case .failed: return .red
        }
    }
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.2))
            .foregroundColor(color)
            .cornerRadius(6)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            VStack(spacing: 8) {
                Text(title)
                    .font(.title3)
                    .fontWeight(.semibold)
                
                Text(message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
}
