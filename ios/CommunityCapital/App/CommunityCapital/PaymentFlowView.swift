// PaymentFlowView.swift
import SwiftUI
import ComposableArchitecture
// MARK: - Payment Flow View
struct PaymentFlowView: View {
    let store: StoreOf<PaymentReducer>
    @Environment(.dismiss) var dismiss
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    CCDesign.backgroundPrimary.ignoresSafeArea()
                    
                    switch viewStore.paymentStep {
                    case .selectSource:
                        PaymentSourceSelectionView(store: store)
                    case .linkBank:
                        PlaidLinkView(store: store)
                    case .confirmAmount:
                        ConfirmPaymentView(store: store)
                    case .processing:
                        ProcessingPaymentView()
                    case .completed:
                        PaymentSuccessView(store: store)
                    case .failed:
                        PaymentFailedView(store: store)
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if viewStore.paymentStep != .processing {
                            Button("Cancel") {
                                dismiss()
                            }
                            .foregroundColor(CCDesign.primaryGreen)
                        }
                    }
                    
                    ToolbarItem(placement: .principal) {
                        Text("Payment")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
            }
        }
    }
}

// MARK: - Payment Source Selection
struct PaymentSourceSelectionView: View {
    let store: StoreOf<PaymentReducer>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 24) {
                // Amount summary
                VStack(spacing: 8) {
                    Text("Your Share")
                        .font(.system(size: 16))
                        .foregroundColor(CCDesign.textSecondary)
                    
                    Text(String(format: "$%.2f", viewStore.amountOwed))
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    if viewStore.eventName != nil {
                        Text(viewStore.eventName ?? "")
                            .font(.system(size: 14))
                            .foregroundColor(CCDesign.textSecondary)
                    }
                }
                .padding(.top, 40)
                
                Spacer()
                
                // Payment methods
                VStack(spacing: 16) {
                    Text("Select Payment Method")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(CCDesign.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Linked bank accounts
                    if !viewStore.linkedAccounts.isEmpty {
                        ForEach(viewStore.linkedAccounts) { account in
                            BankAccountCard(
                                account: account,
                                isSelected: viewStore.selectedPaymentMethod?.id == account.id,
                                onSelect: {
                                    viewStore.send(.selectPaymentMethod(account))
                                }
                            )
                        }
                    }
                    
                    // Add bank account
                    Button(action: {
                        viewStore.send(.linkNewBank)
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(CCDesign.primaryGreen)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Link Bank Account")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(CCDesign.textPrimary)
                                Text("Connect via Plaid")
                                    .font(.system(size: 12))
                                    .foregroundColor(CCDesign.textSecondary)
                            }
                            
                            Spacer()
                            
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14))
                                .foregroundColor(CCDesign.textTertiary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(CCDesign.primaryGreen.opacity(0.3), lineWidth: 1)
                                .background(CCDesign.lightGreen.cornerRadius(12))
                        )
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Continue button
                PrimaryActionButton(
                    title: "Continue",
                    isEnabled: viewStore.selectedPaymentMethod != nil
                ) {
                    viewStore.send(.proceedToConfirmation)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Plaid Link View (Mock for now)
struct PlaidLinkView: View {
    let store: StoreOf<PaymentReducer>
    @State private var isLinking = false
    var body: some View {
        VStack(spacing: 32) {
            // Plaid logo placeholder
            Image(systemName: "building.columns.fill")
                .font(.system(size: 60))
                .foregroundColor(CCDesign.primaryGreen)
            
            Text("Connect Your Bank")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(CCDesign.textPrimary)
            
            Text("Securely link your bank account with Plaid")
                .font(.system(size: 16))
                .foregroundColor(CCDesign.textSecondary)
                .multilineTextAlignment(.center)
            
            // Security badges
            HStack(spacing: 20) {
                SecurityBadge(icon: "lock.shield.fill", text: "Bank-level\nEncryption")
                SecurityBadge(icon: "eye.slash.fill", text: "Private &\nSecure")
                SecurityBadge(icon: "checkmark.shield.fill", text: "Verified by\nPlaid")
            }
            
            Spacer()
            
            if isLinking {
                VStack(spacing: 16) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: CCDesign.primaryGreen))
                    
                    Text("Connecting to your bank...")
                        .font(.system(size: 14))
                        .foregroundColor(CCDesign.textSecondary)
                }
            } else {
                PrimaryActionButton(
                    title: "Connect Bank Account",
                    icon: "link"
                ) {
                    simulatePlaidLink()
                }
                .padding(.horizontal, 20)
            }
            
            Text("Your login details are never stored")
                .font(.system(size: 12))
                .foregroundColor(CCDesign.textSecondary)
                .padding(.bottom, 20)
        }
        .padding(.horizontal, 20)
    }
    
    func simulatePlaidLink() {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            isLinking = true
            
            // Simulate Plaid Link process
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                // Create mock linked account
                let mockAccount = PaymentMethod(
                    id: UUID().uuidString,
                    type: .bankAccount,
                    last4: "4321",
                    bankName: "Chase",
                    accountType: "Checking",
                    isDefault: viewStore.linkedAccounts.isEmpty
                )
                
                viewStore.send(.bankLinked(mockAccount))
                isLinking = false
            }
        }
    }
}

// MARK: - Confirm Payment View
struct ConfirmPaymentView: View {
    let store: StoreOf<PaymentReducer>
    @State private var acceptedTerms = false
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 24) {
                        // Event details
                        VStack(spacing: 16) {
                            Text("Payment Summary")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(CCDesign.textPrimary)
                            
                            PaymentSummaryCard(
                                eventName: viewStore.eventName ?? "Bill Split",
                                items: viewStore.claimedItems,
                                subtotal: viewStore.amountOwed,
                                tax: viewStore.taxAmount,
                                tip: viewStore.tipAmount,
                                total: viewStore.totalAmount
                            )
                        }
                        .padding(.top, 20)
                        
                        // Payment method
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Payment Method")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(CCDesign.textSecondary)
                            
                            if let method = viewStore.selectedPaymentMethod {
                                BankAccountCard(
                                    account: method,
                                    isSelected: true,
                                    showCheckmark: false,
                                    onSelect: {}
                                )
                            }
                        }
                        
                        // Terms
                        HStack {
                            Button(action: { acceptedTerms.toggle() }) {
                                Image(systemName: acceptedTerms ? "checkmark.square.fill" : "square")
                                    .foregroundColor(acceptedTerms ? CCDesign.primaryGreen : CCDesign.textTertiary)
                            }
                            
                            Text("I authorize this payment and agree to the ")
                                .font(.system(size: 14))
                                .foregroundColor(CCDesign.textSecondary) +
                            Text("terms of service")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(CCDesign.primaryGreen)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 20)
                }
                
                // Pay button
                VStack(spacing: 16) {
                    PrimaryActionButton(
                        title: String(format: "Pay $%.2f", viewStore.totalAmount),
                        icon: "lock.fill",
                        isEnabled: acceptedTerms
                    ) {
                        viewStore.send(.initiatePayment)
                    }
                    
                    Text("Payment processed by Stripe")
                        .font(.system(size: 12))
                        .foregroundColor(CCDesign.textSecondary)
                }
                .padding(20)
                .background(Color.white)
            }
        }
    }
}

// MARK: - Processing Payment View
struct ProcessingPaymentView: View {
    @State private var step = 0
    let steps = [
        "Initiating payment...",
        "Verifying with bank...",
        "Processing transaction...",
        "Updating balances...",
        "Almost done..."
    ]
    
    var body: some View {
        VStack(spacing: 32) {
            // Animated checkmark
            ZStack {
                Circle()
                    .stroke(CCDesign.primaryGreen.opacity(0.2), lineWidth: 4)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(step + 1) / CGFloat(steps.count))
                    .stroke(CCDesign.primaryGreen, lineWidth: 4)
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: step)
                
                Image(systemName: "creditcard.fill")
                    .font(.system(size: 50))
                    .foregroundColor(CCDesign.primaryGreen)
            }
            
            VStack(spacing: 12) {
                Text("Processing Payment")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(CCDesign.textPrimary)
                
                if step < steps.count {
                    Text(steps[step])
                        .font(.system(size: 16))
                        .foregroundColor(CCDesign.textSecondary)
                        .transition(.opacity)
                }
            }
            
            // Security note
            HStack {
                Image(systemName: "lock.shield.fill")
                    .foregroundColor(CCDesign.success)
                Text("Secured by Stripe")
                    .font(.system(size: 14))
                    .foregroundColor(CCDesign.textSecondary)
            }
        }
        .padding(40)
        .onAppear {
            animateSteps()
        }
    }
    
    func animateSteps() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            withAnimation {
                if step < steps.count - 1 {
                    step += 1
                } else {
                    timer.invalidate()
                }
            }
        }
    }
}

// MARK: - Payment Success View
struct PaymentSuccessView: View {
    let store: StoreOf<PaymentReducer>
    @State private var showConfetti = false
    @Environment(.dismiss) var dismiss
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 32) {
                Spacer()
                
                // Success animation
                ZStack {
                    Circle()
                        .fill(CCDesign.success.opacity(0.1))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showConfetti ? 1.2 : 0.8)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: showConfetti)
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(CCDesign.success)
                        .scaleEffect(showConfetti ? 1 : 0)
                        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2), value: showConfetti)
                }
                
                VStack(spacing: 12) {
                    Text("Payment Successful!")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    Text(String(format: "$%.2f paid", viewStore.totalAmount))
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(CCDesign.textSecondary)
                }
                
                // Transaction details
                VStack(spacing: 12) {
                    TransactionDetail(label: "Event", value: viewStore.eventName ?? "Bill Split")
                    TransactionDetail(label: "Payment Method", value: viewStore.selectedPaymentMethod?.displayName ?? "Bank Account")
                    TransactionDetail(label: "Transaction ID", value: viewStore.transactionId ?? "CC-\(UUID().uuidString.prefix(8))")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CCDesign.lightGreen)
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    PrimaryActionButton(title: "Done") {
                        dismiss()
                    }
                    
                    SecondaryActionButton(title: "View Receipt", icon: "doc.text") {
                        // View receipt
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .onAppear {
                withAnimation {
                    showConfetti = true
                }
                
                // Haptic feedback
                let notificationFeedback = UINotificationFeedbackGenerator()
                notificationFeedback.notificationOccurred(.success)
            }
        }
    }
}

// MARK: - Payment Failed View
struct PaymentFailedView: View {
    let store: StoreOf<PaymentReducer>
    @Environment(.dismiss) var dismiss
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            VStack(spacing: 32) {
                Spacer()
                
                // Error icon
                ZStack {
                    Circle()
                        .fill(CCDesign.error.opacity(0.1))
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(CCDesign.error)
                }
                
                VStack(spacing: 12) {
                    Text("Payment Failed")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    Text(viewStore.errorMessage ?? "We couldn't process your payment")
                        .font(.system(size: 16))
                        .foregroundColor(CCDesign.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                // Error details
                VStack(alignment: .leading, spacing: 16) {
                    Text("What to do next:")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    ErrorStep(number: "1", text: "Check your bank account has sufficient funds")
                    ErrorStep(number: "2", text: "Verify your bank connection is active")
                    ErrorStep(number: "3", text: "Try a different payment method")
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(CCDesign.error.opacity(0.05))
                )
                .padding(.horizontal, 20)
                
                Spacer()
                
                // Actions
                VStack(spacing: 12) {
                    PrimaryActionButton(title: "Try Again") {
                        viewStore.send(.retryPayment)
                    }
                    
                    SecondaryActionButton(title: "Use Different Method") {
                        viewStore.send(.changePaymentMethod)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
        }
    }
}

// MARK: - Supporting Components
struct BankAccountCard: View {
    let account: PaymentMethod
    let isSelected: Bool
    var showCheckmark: Bool = true
    let onSelect: () -> Void
    var body: some View {
        Button(action: onSelect) {
            HStack {
                // Bank icon
                ZStack {
                    Circle()
                        .fill(CCDesign.primaryGreen.opacity(0.1))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "building.columns.fill")
                        .font(.system(size: 20))
                        .foregroundColor(CCDesign.primaryGreen)
                }
                
                // Account details
                VStack(alignment: .leading, spacing: 4) {
                    Text(account.bankName ?? "Bank Account")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    Text("\(account.accountType ?? "Account") ••••\(account.last4)")
                        .font(.system(size: 14))
                        .foregroundColor(CCDesign.textSecondary)
                }
                
                Spacer()
                
                // Selection indicator
                if showCheckmark {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? CCDesign.primaryGreen : CCDesign.textTertiary)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? CCDesign.lightGreen : Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? CCDesign.primaryGreen : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct PaymentSummaryCard: View {
    let eventName: String
    let items: [BillItem]
    let subtotal: Double
    let tax: Double
    let tip: Double
    let total: Double
    var body: some View {
        VStack(spacing: 16) {
            // Event name
            Text(eventName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(CCDesign.textPrimary)
            
            Divider()
            
            // Items
            VStack(alignment: .leading, spacing: 8) {
                Text("Your Items (\(items.count))")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(CCDesign.textSecondary)
                
                ForEach(items.prefix(3)) { item in
                    HStack {
                        Text(item.name)
                            .font(.system(size: 14))
                            .foregroundColor(CCDesign.textPrimary)
                        Spacer()
                        Text(String(format: "$%.2f", item.price))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(CCDesign.textPrimary)
                    }
                }
                
                if items.count > 3 {
                    Text("+ \(items.count - 3) more items")
                        .font(.system(size: 12))
                        .foregroundColor(CCDesign.textSecondary)
                }
            }
            
            Divider()
            
            // Totals
            VStack(spacing: 8) {
                SummaryRow(label: "Subtotal", amount: subtotal)
                SummaryRow(label: "Tax", amount: tax)
                SummaryRow(label: "Tip", amount: tip)
                
                Divider()
                
                HStack {
                    Text("Total")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(CCDesign.textPrimary)
                    Spacer()
                    Text(String(format: "$%.2f", total))
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(CCDesign.textPrimary)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: CCDesign.cardShadow, radius: 8, x: 0, y: 2)
        )
    }
}

struct SummaryRow: View {
    let label: String
    let amount: Double
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(CCDesign.textSecondary)
            Spacer()
            Text(String(format: "$%.2f", amount))
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(CCDesign.textPrimary)
        }
    }
}

struct SecurityBadge: View {
    let icon: String
    let text: String
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(CCDesign.primaryGreen)
            
            Text(text)
                .font(.system(size: 11))
                .foregroundColor(CCDesign.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(width: 80)
    }
}

struct TransactionDetail: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundColor(CCDesign.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(CCDesign.textPrimary)
        }
    }
}

struct ErrorStep: View {
    let number: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(CCDesign.error)
                .frame(width: 20, height: 20)
                .background(Circle().fill(CCDesign.error.opacity(0.1)))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(CCDesign.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
