// AuthenticationView.swift
import SwiftUI
import ComposableArchitecture

struct AuthenticationView: View {
    let store: StoreOf<AuthenticationReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                VStack {
                    if viewStore.showVerification {
                        VerificationView(store: store, phoneNumber: viewStore.phoneNumber)
                    } else {
                        OnboardingView(store: store)
                    }
                }
                .background(CCDesign.backgroundPrimary)
                .navigationBarHidden(true)
            }
            .onReceive(viewStore.publisher) { state in
                // Handle state changes
            }
        }
    }
}

// MARK: - Authentication Reducer
struct AuthenticationReducer: Reducer {
    struct State: Equatable {
        var phoneNumber = ""
        var verificationCode = ""
        var isLoading = false
        var error: String?
        var showVerification = false
        var otpSent = false
    }
    
    enum Action: Equatable {
        case setPhoneNumber(String)
        case setVerificationCode(String)
        case sendVerificationCode
        case verifyCode
        case loginResponse(Result<User, APIError>)
        case dismissError
    }
    
    var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case let .setPhoneNumber(phone):
                state.phoneNumber = phone
                return .none
                
            case let .setVerificationCode(code):
                state.verificationCode = code
                return .none
                
            case .sendVerificationCode:
                state.isLoading = true
                state.error = nil
                
                return .run { [phone = state.phoneNumber] send in
                    do {
                        let _ = try await AuthenticationClient.shared.sendOTP(phoneNumber: phone)
                        await send(.loginResponse(.success(User(
                            id: "",
                            name: "",
                            email: "",
                            phoneNumber: phone,
                            profileImageURL: nil,
                            linkedBankToken: nil,
                            stripeCustomerId: nil
                        ))))
                    } catch {
                        await send(.loginResponse(.failure(error as? APIError ?? .serverError(error.localizedDescription))))
                    }
                }
                
            case .verifyCode:
                state.isLoading = true
                state.error = nil
                
                return .run { [phone = state.phoneNumber, code = state.verificationCode] send in
                    do {
                        let user = try await AuthenticationClient.shared.verifyOTP(phoneNumber: phone, code: code)
                        await send(.loginResponse(.success(user)))
                    } catch {
                        await send(.loginResponse(.failure(error as? APIError ?? .serverError(error.localizedDescription))))
                    }
                }
                
            case let .loginResponse(.success(user)):
                state.isLoading = false
                if !state.otpSent {
                    state.otpSent = true
                    state.showVerification = true
                }
                // Success is handled by parent reducer
                return .none
                
            case let .loginResponse(.failure(error)):
                state.isLoading = false
                state.error = error.localizedDescription
                return .none
                
            case .dismissError:
                state.error = nil
                return .none
            }
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    let store: StoreOf<AuthenticationReducer>
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 30) {
                Spacer()
                
                // Logo and title
                VStack(spacing: 20) {
                    Circle()
                        .fill(CCDesign.primaryGradient)
                        .frame(width: 100, height: 100)
                        .overlay(
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        )
                    
                    VStack(spacing: 8) {
                        Text("Welcome to Community Capital")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(CCDesign.textPrimary)
                        
                        Text("Split bills. Build wealth. Together.")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(CCDesign.textSecondary)
                    }
                }
                
                Spacer()
                
                // Phone number input
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter your phone number")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CCDesign.textSecondary)
                        
                        HStack {
                            Image(systemName: "phone.fill")
                                .foregroundColor(CCDesign.primaryGreen)
                                .frame(width: 20)
                            
                            TextField("(555) 123-4567", text: viewStore.binding(
                                get: \.phoneNumber,
                                send: AuthenticationReducer.Action.setPhoneNumber
                            ))
                            .font(.system(size: 17, weight: .regular))
                            .keyboardType(.phonePad)
                        }
                        .padding(.horizontal, 16)
                        .frame(height: 52)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(CCDesign.primaryGreen.opacity(0.3), lineWidth: 1)
                                )
                        )
                    }
                    
                    if let error = viewStore.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(CCDesign.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    PrimaryActionButton(
                        "Get Started",
                        icon: "arrow.right",
                        isLoading: viewStore.isLoading,
                        isEnabled: viewStore.phoneNumber.count >= 10
                    ) {
                        viewStore.send(.sendVerificationCode)
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.vertical, 40)
        }
    }
}

// MARK: - Verification View
struct VerificationView: View {
    let store: StoreOf<AuthenticationReducer>
    let phoneNumber: String
    @State private var timeRemaining = 60
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 16) {
                    Button(action: {
                        viewStore.send(.dismissError)
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(CCDesign.textPrimary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    VStack(spacing: 12) {
                        Text("Verify your number")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(CCDesign.textPrimary)
                        
                        Text("We sent a code to \(phoneNumber)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(CCDesign.textSecondary)
                    }
                }
                
                Spacer()
                
                // Verification code input
                VStack(spacing: 32) {
                    VStack(spacing: 16) {
                        Text("Enter the 6-digit code")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CCDesign.textSecondary)
                        
                        // Code input fields
                        HStack(spacing: 12) {
                            ForEach(0..<6, id: \.self) { index in
                                CodeDigitField(
                                    digit: getDigit(at: index, from: viewStore.verificationCode),
                                    isActive: viewStore.verificationCode.count == index
                                )
                            }
                        }
                        
                        // Hidden text field for actual input
                        TextField("", text: viewStore.binding(
                            get: \.verificationCode,
                            send: AuthenticationReducer.Action.setVerificationCode
                        ))
                        .keyboardType(.numberPad)
                        .opacity(0)
                        .frame(height: 1)
                    }
                    
                    if let error = viewStore.error {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.orange)
                            Text(error)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(CCDesign.textPrimary)
                            Spacer()
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.orange.opacity(0.1))
                        .cornerRadius(8)
                    }
                    
                    VStack(spacing: 16) {
                        PrimaryActionButton(
                            "Verify",
                            isLoading: viewStore.isLoading,
                            isEnabled: viewStore.verificationCode.count == 6
                        ) {
                            viewStore.send(.verifyCode)
                        }
                        
                        if timeRemaining > 0 {
                            Text("Resend code in \(timeRemaining)s")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(CCDesign.textTertiary)
                        } else {
                            Button("Resend code") {
                                viewStore.send(.sendVerificationCode)
                                timeRemaining = 60
                            }
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CCDesign.primaryGreen)
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .padding(.vertical, 40)
            .onAppear {
                startTimer()
            }
        }
    }
    
    private func startTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timeRemaining > 0 {
                timeRemaining -= 1
            } else {
                timer.invalidate()
            }
        }
    }
    
    func getDigit(at index: Int, from code: String) -> String {
        if index < code.count {
            let stringIndex = code.index(code.startIndex, offsetBy: index)
            return String(code[stringIndex])
        }
        return ""
    }
}

// MARK: - Code Digit Field
struct CodeDigitField: View {
    let digit: String
    let isActive: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isActive ? CCDesign.primaryGreen : CCDesign.primaryGreen.opacity(0.3), lineWidth: 2)
                )
                .frame(width: 48, height: 56)
            
            Text(digit)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(CCDesign.textPrimary)
        }
    }
}

