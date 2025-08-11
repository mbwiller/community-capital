// ProfileView.swift
import SwiftUI
import ComposableArchitecture

struct ProfileView: View {
    let store: StoreOf<ProfileReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    ProfileHeaderView(user: viewStore.currentUser)
                    
                    // Bank Account Section
                    BankAccountSection(
                        linkedAccount: viewStore.linkedBankAccount,
                        onLinkAccount: {
                            viewStore.send(.linkBankTapped)
                        }
                    )
                    
                    // Settings Options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Settings")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        VStack(spacing: 8) {
                            SettingRow(
                                icon: "bell.fill",
                                title: "Notifications"
                            ) {
                                // Handle notifications
                            }
                            
                            SettingRow(
                                icon: "questionmark.circle.fill",
                                title: "Help & Support"
                            ) {
                                // Handle support
                            }
                            
                            SettingRow(
                                icon: "arrow.right.square.fill",
                                title: "Sign Out"
                            ) {
                                viewStore.send(.signOut)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
        }
    }
}

struct ProfileReducer: Reducer {
    struct State: Equatable {
        var currentUser: User?
        var linkedBankAccount: LinkedBankAccount?
        var isLoading = false
    }
    
    enum Action: Equatable {
        case linkBankTapped
        case signOut
        case userUpdated(User?)
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .linkBankTapped:
                // Handle bank linking
                return .none
                
            case .signOut:
                // Parent reducer handles this
                return .none
                
            case let .userUpdated(user):
                state.currentUser = user
                return .none
            }
        }
    }
}

struct ProfileHeaderView: View {
    let user: User?
    
    var body: some View {
        VStack(spacing: 12) {
            // Profile Image
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.green, Color.blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Text(user?.name.prefix(2).uppercased() ?? "CC")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(user?.name ?? "Community Capital User")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(user?.phoneNumber ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct BankAccountSection: View {
    let linkedAccount: LinkedBankAccount?
    let onLinkAccount: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.headline)
                .padding(.horizontal)
            
            if let account = linkedAccount {
                HStack {
                    Image(systemName: "building.columns.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(account.institutionName)
                            .font(.headline)
                        Text(account.accountName)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                }
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            } else {
                Button(action: onLinkAccount) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                        
                        Text("Link Bank Account")
                            .fontWeight(.medium)
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
        }
    }
}

struct SettingRow: View {
    let icon: String
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(.gray)
                    .frame(width: 30)
                
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
            .background(Color.gray.opacity(0.05))
            .cornerRadius(10)
        }
    }
}

struct LinkedBankAccount: Equatable {
    let id: String
    let institutionName: String
    let accountName: String
    let accountMask: String
    let stripeBankToken: String
    let plaidAccessToken: String
}