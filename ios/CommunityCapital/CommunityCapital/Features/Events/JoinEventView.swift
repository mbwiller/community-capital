// JoinEventView.swift
import SwiftUI
import ComposableArchitecture

struct JoinEventView: View {
    @Binding var code: String
    
    var body: some View {
        VStack(spacing: 30) {
            Text("Enter Event Code")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Ask the event creator for the 6-digit code")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            // Code Input
            HStack(spacing: 10) {
                ForEach(0..<6, id: \.self) { index in
                    CodeDigitView(
                        digit: getDigit(at: index),
                        isActive: code.count == index
                    )
                }
            }
            .padding()
            
            Spacer()
        }
    }
    
    private func getDigit(at index: Int) -> String {
        guard index < code.count else { return "" }
        let stringIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[stringIndex])
    }
}

struct JoinEventReducer: Reducer {
    struct State: Equatable {
        var code = ""
        var isLoading = false
        var error: String?
        var joinedEvent: BillEvent?
    }
    
    enum Action: Equatable {
        case setCode(String)
        case joinEvent
        case joinEventResponse(Result<BillEvent, APIError>)
        case clearError
    }
    
    @Dependency(\.apiClient) var apiClient
    @Dependency(\.analytics) var analytics
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setCode(code):
                state.code = code
                // Clear error when user starts typing
                if state.error != nil {
                    state.error = nil
                }
                return .none
                
            case .joinEvent:
                guard state.code.count == 6 else {
                    state.error = "Please enter a 6-digit code"
                    return .none
                }
                
                state.isLoading = true
                state.error = nil
                
                return .run { [code = state.code] send in
                    do {
                        let event = try await apiClient.joinEvent(code)
                        await send(.joinEventResponse(.success(event)))
                    } catch {
                        await send(.joinEventResponse(.failure(error as? APIError ?? .serverError(error.localizedDescription))))
                    }
                }
                
            case let .joinEventResponse(.success(event)):
                state.isLoading = false
                state.joinedEvent = event
                
                // Track successful join
                analytics.track("event_joined", [
                    "event_id": event.id,
                    "event_name": event.eventName,
                    "participant_count": event.participants.count
                ])
                
                return .none
                
            case let .joinEventResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case .clearError:
                state.error = nil
                return .none
            }
        }
    }
}

struct CodeDigitView: View {
    let digit: String
    let isActive: Bool
    
    var body: some View {
        Text(digit)
            .font(.title)
            .fontWeight(.bold)
            .frame(width: 45, height: 55)
            .background(Color.gray.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isActive ? Color.green : Color.gray.opacity(0.3), lineWidth: 2)
            )
            .cornerRadius(8)
    }
}
