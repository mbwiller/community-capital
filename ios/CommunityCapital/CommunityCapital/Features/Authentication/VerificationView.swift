//
//  VerificationView.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import SwiftUI
import ComposableArchitecture

struct VerificationView: View {
    let store: StoreOf<AuthenticationReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 32) {
                HStack {
                    Button(action: {
                        viewStore.send(.backToPhoneEntry)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(CCDesign.primaryGreen)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                Spacer()
                
                VStack(spacing: 20) {
                    Text("Verify Your Number")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    Text("Enter the code sent to \(viewStore.phoneNumber)")
                        .font(.system(size: 16))
                        .foregroundColor(CCDesign.textSecondary)
                    
                    TextField("123456", text: viewStore.binding(
                        get: \.verificationCode,
                        send: AuthenticationReducer.Action.setVerificationCode
                    ))
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .padding()
                    .background(Color.white)
                    .cornerRadius(12)
                    
                    Text("💡 Dev Mode: Use 123456")
                        .font(.system(size: 12))
                        .foregroundColor(.blue.opacity(0.8))
                    
                    if let error = viewStore.error {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(CCDesign.error)
                    }
                    
                    PrimaryActionButton(
                        title: "Verify",
                        isLoading: viewStore.isLoading,
                        isEnabled: viewStore.verificationCode.count == 6
                    ) {
                        viewStore.send(.verifyCode)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}
