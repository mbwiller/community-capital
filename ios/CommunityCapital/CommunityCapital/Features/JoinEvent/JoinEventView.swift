//
//  JoinEventView.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import SwiftUI
import ComposableArchitecture

struct JoinEventView: View {
    let store: StoreOf<JoinEventReducer>
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Text("Join Event")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(CCDesign.textPrimary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event Code")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CCDesign.textSecondary)
                    
                    WithViewStore(self.store, observe: { $0 }) { viewStore in
                        TextField("Enter 6-digit code", text: viewStore.binding(
                            get: \.eventCode,
                            send: JoinEventReducer.Action.setEventCode
                        ))
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                        
                        if let error = viewStore.error {
                            Text(error)
                                .font(.system(size: 14))
                                .foregroundColor(CCDesign.error)
                        }
                        
                        PrimaryActionButton(
                            title: "Join Event",
                            isLoading: viewStore.isLoading,
                            isEnabled: viewStore.eventCode.count >= 4
                        ) {
                            viewStore.send(.joinEvent)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(CCDesign.primaryGreen)
                }
            }
        }
    }
}
