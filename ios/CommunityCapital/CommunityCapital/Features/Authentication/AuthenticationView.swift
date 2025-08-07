//
//  AuthenticationView.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import SwiftUI
import ComposableArchitecture

struct AuthenticationView: View {
    let store: StoreOf<AuthenticationReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ZStack {
                CCDesign.backgroundPrimary.ignoresSafeArea()
                
                if viewStore.showVerification {
                    VerificationView(store: store)
                        .transition(.move(edge: .trailing))
                } else {
                    PhoneEntryView(store: store)
                        .transition(.opacity)
                }
            }
            .animation(.spring(), value: viewStore.showVerification)
        }
    }
}

struct PhoneEntryView: View {
    let store: StoreOf<AuthenticationReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 32) {
                Spacer()
                
                VStack(spacing: 12) {
                    Text("Welcome to")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(CCDesign.textSecondary)
                    
                    Text("Community Capital")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    Text("Split bills. Build wealth. Together.")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(CCDesign.textSecondary)
                }
                
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your phone number")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CCDesign.textSecondary)
                        
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(CCDesign.primaryGreen)
                            
                            TextField("(555) 123-4567", text: viewStore.binding(
                                get: \.phoneNumber,
                                send: AuthenticationReducer.Action.setPhoneNumber
                            ))
                            .keyboardType(.phonePad)
                        }
                        .padding()
                        .background(Color.white)
                        .cornerRadius(12)
                    }
                    
                    if let error = viewStore.error {
                        Text(error)
                            .font(.system(size: 14))
                            .foregroundColor(CCDesign.error)
                    }
                    
                    PrimaryActionButton(
                        title: "Get Started",
                        isLoading: viewStore.isLoading,
                        isEnabled: viewStore.phoneNumber.count >= 10
                    ) {
                        viewStore.send(.sendVerificationCode)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
        }
    }
}
