//
//  ProfileView.swift
//  CommunityCapital
//
//  Created by Matt on 8/7/25.
//

import SwiftUI
import ComposableArchitecture

struct ProfileView: View {
    let store: StoreOf<ProfileReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ScrollView {
                    VStack(spacing: 20) {
                        Text("Profile")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(CCDesign.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        if let user = viewStore.user {
                            VStack(spacing: 16) {
                                Circle()
                                    .fill(CCDesign.primaryGradient)
                                    .frame(width: 100, height: 100)
                                    .overlay(
                                        Text(user.name.prefix(1).uppercased())
                                            .font(.system(size: 40, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                Text(user.name)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundColor(CCDesign.textPrimary)
                                
                                Text(user.phoneNumber)
                                    .font(.system(size: 16))
                                    .foregroundColor(CCDesign.textSecondary)
                            }
                            .padding(.vertical, 20)
                            
                            Button(action: {
                                viewStore.send(.signOut)
                            }) {
                                Text("Sign Out")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(CCDesign.error)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(CCDesign.error, lineWidth: 1)
                                    )
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 100)
                }
                .navigationBarHidden(true)
            }
            .onAppear {
                viewStore.send(.loadProfile)
                // Mock load profile
                viewStore.send(.profileLoaded(User.mock))
            }
        }
    }
}
