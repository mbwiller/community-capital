// ContentView.swift
import SwiftUI
import ComposableArchitecture
struct ContentView: View {
    let store: StoreOf<AppReducer>
    var body: some View {
        AppView(store: store)
    }
}

// MARK: - Root App View
struct AppView: View {
    let store: StoreOf<AppReducer>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            Group {
                if viewStore.isLoading {
                    SplashView()
                } else if viewStore.isAuthenticated {
                    MainView(
                        store: store.scope(
                            state: \.main,
                            action: AppReducer.Action.main
                        )
                    )
                } else {
                    AuthenticationRootView(
                        store: store.scope(
                            state: \.authentication,
                            action: AppReducer.Action.authentication
                        )
                    )
                }
            }
            .onAppear {
                viewStore.send(.onAppear)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewStore.isAuthenticated)
            .animation(.spring(response: 0.5, dampingFraction: 0.8), value: viewStore.isLoading)
        }
    }
}

// MARK: - Splash Screen
struct SplashView: View {
    @State private var animateGradient = false
    @State private var logoScale: CGFloat = 0.8
    var body: some View {
        ZStack {
            // Animated gradient background
            LinearGradient(
                colors: [
                    CCDesign.lightGreen,
                    CCDesign.backgroundPrimary,
                    Color.white
                ],
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .ignoresSafeArea()
            .onAppear {
                withAnimation(.easeInOut(duration: 3).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    logoScale = 1.0
                }
            }
            
            VStack(spacing: 24) {
                // Logo
                ZStack {
                    Circle()
                        .fill(CCDesign.primaryGradient)
                        .frame(width: 120, height: 120)
                        .shadow(color: CCDesign.primaryGreen.opacity(0.3), radius: 30, x: 0, y: 15)
                    
                    Image(systemName: "person.3.fill")
                        .font(.system(size: 50, weight: .medium))
                        .foregroundColor(.white)
                }
                .scaleEffect(logoScale)
                
                VStack(spacing: 8) {
                    Text("Community Capital")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(CCDesign.textPrimary)
                    
                    Text("Loading your financial future...")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(CCDesign.textSecondary)
                }
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: CCDesign.primaryGreen))
                    .scaleEffect(1.2)
            }
        }
    }
}

// MARK: - Authentication Root View
struct AuthenticationRootView: View {
    let store: StoreOf<AuthenticationReducer>
    struct ViewState: Equatable {
        let phoneNumber: String
        let verificationCode: String
        let isLoading: Bool
        let showVerification: Bool
        let error: String?
    }
    
    var body: some View {
        WithViewStore(self.store, observe: { state in
            ViewState(
                phoneNumber: state.phoneNumber,
                verificationCode: state.verificationCode,
                isLoading: state.isLoading,
                showVerification: state.showVerification,
                error: state.error
            )
        }) { viewStore in
            ZStack {
                CCDesign.backgroundPrimary.ignoresSafeArea()
                
                if viewStore.showVerification {
                    VerificationView(
                        store: store,
                        phoneNumber: viewStore.phoneNumber
                    )
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .leading).combined(with: .opacity)
                    ))
                } else {
                    OnboardingView(store: store)
                        .transition(.opacity)
                }
            }
            .animation(CCDesign.springAnimation, value: viewStore.showVerification)
        }
    }
}

// MARK: - Onboarding View
struct OnboardingView: View {
    let store: StoreOf<AuthenticationReducer>
    @State private var animateElements = false
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            ScrollView {
                VStack(spacing: 0) {
                    // Header with logo
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(CCDesign.primaryGradient)
                                .frame(width: 100, height: 100)
                                .shadow(color: CCDesign.primaryGreen.opacity(0.3), radius: 20, x: 0, y: 10)
                                .scaleEffect(animateElements ? 1 : 0.8)
                                .opacity(animateElements ? 1 : 0)
                            
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 40, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
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
                                .opacity(animateElements ? 1 : 0)
                        }
                    }
                    .padding(.top, 80)
                    .padding(.bottom, 40)
                    
                    // Features showcase
                    VStack(spacing: 16) {
                        FeatureCard(
                            icon: "camera.fill",
                            title: "Smart Scanning",
                            description: "AI-powered receipt scanning",
                            color: CCDesign.primaryGreen
                        )
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        
                        FeatureCard(
                            icon: "person.3.fill",
                            title: "Instant Splits",
                            description: "Fair and automatic calculations",
                            color: CCDesign.info
                        )
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(CCDesign.springAnimation.delay(0.1), value: animateElements)
                        
                        FeatureCard(
                            icon: "creditcard.fill",
                            title: "Virtual Cards",
                            description: "One payment, multiple sources",
                            color: CCDesign.accentOrange
                        )
                        .opacity(animateElements ? 1 : 0)
                        .offset(y: animateElements ? 0 : 20)
                        .animation(CCDesign.springAnimation.delay(0.2), value: animateElements)
                    }
                    .padding(.horizontal, 20)
                    
                    // Phone input
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
                                .font(.system(size: 17, weight: .regular, design: .rounded))
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
                            ErrorBanner(message: error)
                        }
                        
                        PrimaryActionButton(
                            title: "Get Started",
                            icon: "arrow.right",
                            isLoading: viewStore.isLoading,
                            isEnabled: viewStore.phoneNumber.count >= 10
                        ) {
                            viewStore.send(.sendVerificationCode)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 40)
                }
            }
            .onAppear {
                withAnimation(CCDesign.springAnimation) {
                    animateElements = true
                }
            }
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
            VStack(spacing: 0) {
                // Back button
                HStack {
                    Button(action: {
                        viewStore.send(.backToPhoneEntry)
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "chevron.left")
                            Text("Back")
                        }
                        .foregroundColor(CCDesign.primaryGreen)
                        .font(.system(size: 16, weight: .medium))
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Verify Your Number")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(CCDesign.textPrimary)
                        
                        Text("Enter the code sent to")
                            .font(.system(size: 16))
                            .foregroundColor(CCDesign.textSecondary)
                        
                        Text(phoneNumber)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(CCDesign.textPrimary)
                    }
                    
                    // OTP Input
                    VStack(spacing: 16) {
                        HStack(spacing: 12) {
                            ForEach(0..<6) { index in
                                OTPDigitField(
                                    digit: getDigit(at: index, from: viewStore.verificationCode),
                                    isActive: index == viewStore.verificationCode.count
                                )
                            }
                        }
                        
                        TextField("", text: viewStore.binding(
                            get: \.verificationCode,
                            send: AuthenticationReducer.Action.setVerificationCode
                        ))
                        .keyboardType(.numberPad)
                        .frame(width: 0, height: 0)
                        .opacity(0)
                    }
                    
                    // Dev hint
                    Text("💡 Dev Mode: Use 123456")
                        .font(.system(size: 12))
                        .foregroundColor(.blue.opacity(0.8))
                    
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
    
    func getDigit(at index: Int, from code: String) -> String {
        if index < code.count {
            let stringIndex = code.index(code.startIndex, offsetBy: index)
            return String(code[stringIndex])
        }
        return ""
    }
}

// MARK: - Main View
struct MainView: View {
    let store: StoreOf<MainReducer>
    var body: some View {
        WithViewStore(self.store, observe: \.selectedTab) { viewStore in
            ZStack {
                CCDesign.backgroundPrimary.ignoresSafeArea()
                
                TabView(selection: viewStore.binding(
                    send: MainReducer.Action.setSelectedTab
                )) {
                    HomeView(
                        store: store.scope(
                            state: \.home,
                            action: MainReducer.Action.home
                        )
                    )
                    .tag(0)
                    
                    EventsView(
                        store: store.scope(
                            state: \.events,
                            action: MainReducer.Action.events
                        )
                    )
                    .tag(1)
                    
                    ProfileView(
                        store: store.scope(
                            state: \.profile,
                            action: MainReducer.Action.profile
                        )
                    )
                    .tag(2)
                }
                
                // Custom Tab Bar Overlay
                VStack {
                    Spacer()
                    CustomTabBar(selectedTab: viewStore.binding(
                        send: MainReducer.Action.setSelectedTab
                    ))
                }
            }
        }
    }
}

// MARK: - Home View
struct HomeView: View {
    let store: StoreOf<HomeReducer>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        HomeHeaderView()
                        
                        // Quick Actions
                        QuickActionsSection(store: store)
                        
                        // Balance Overview
                        BalanceOverviewCard()
                        
                        // Recent Activity
                        if !viewStore.recentActivity.isEmpty {
                            RecentActivitySection(
                                events: viewStore.recentActivity
                            )
                        }
                        
                        // Achievement Progress
                        AchievementProgressCard()
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .navigationBarHidden(true)
            }
            .sheet(
                store: self.store.scope(
                    state: \.$destination,
                    action: { .destination($0) }
                ),
                state: /HomeReducer.Destination.State.scanner,
                action: HomeReducer.Destination.Action.scanner
            ) { scannerStore in
                ReceiptScannerView(store: scannerStore)
            }
            .sheet(
                store: self.store.scope(
                    state: \.$destination,
                    action: { .destination($0) }
                ),
                state: /HomeReducer.Destination.State.joinEvent,
                action: HomeReducer.Destination.Action.joinEvent
            ) { joinStore in
                JoinEventView(store: joinStore)
            }
            .onAppear {
                viewStore.send(.loadRecentActivity)
            }
        }
    }
}

// MARK: - Home Header
struct HomeHeaderView: View {
    @State private var showNotifications = false
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Welcome back!")
                    .font(.system(size: 14))
                    .foregroundColor(CCDesign.textSecondary)
                
                Text("Let's split something")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(CCDesign.textPrimary)
            }
            
            Spacer()
            
            NotificationButton(hasUnread: true) {
                showNotifications.toggle()
            }
        }
        .padding(.top, 60)
    }
}

// MARK: - Quick Actions Section
struct QuickActionsSection: View {
    let store: StoreOf<HomeReducer>
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            HStack(spacing: 12) {
                QuickActionCard(
                    icon: "camera.fill",
                    title: "Scan Receipt",
                    subtitle: "Quick split",
                    gradient: CCDesign.primaryGradient
                ) {
                    viewStore.send(.startScanTapped)
                }
                
                QuickActionCard(
                    icon: "qrcode",
                    title: "Join Event",
                    subtitle: "Enter code",
                    gradient: LinearGradient(
                        colors: [CCDesign.info, CCDesign.info.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                ) {
                    viewStore.send(.joinEventTapped)
                }
            }
        }
    }
}

// MARK: - Balance Overview Card
struct BalanceOverviewCard: View {
    @State private var animateBalance = false
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Total Balance with animation
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Balance")
                        .font(.system(size: 14))
                        .foregroundColor(CCDesign.textSecondary)
                    
                    HStack(spacing: 4) {
                        Text("$")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                        
                        Text("247")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        
                        Text(".83")
                            .font(.system(size: 24, weight: .medium, design: .rounded))
                    }
                    .foregroundColor(CCDesign.textPrimary)
                    .scaleEffect(animateBalance ? 1 : 0.9)
                    .opacity(animateBalance ? 1 : 0)
                }
                
                Spacer()
                
                // Trend indicator
                TrendIndicator(value: 12.5, isPositive: true)
            }
            
            // Balance breakdown
            HStack(spacing: 16) {
                BalanceMetric(
                    title: "You're Owed",
                    amount: "$389.45",
                    color: CCDesign.success,
                    icon: "arrow.down.circle.fill"
                )
                
                BalanceMetric(
                    title: "You Owe",
                    amount: "$141.62",
                    color: CCDesign.warning,
                    icon: "arrow.up.circle.fill"
                )
            }
            
            // Progress to next level
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Split Streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(CCDesign.textSecondary)
                    
                    Spacer()
                    
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 14))
                            .foregroundColor(CCDesign.accentOrange)
                        Text("7 days")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(CCDesign.textPrimary)
                    }
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(CCDesign.lightGreen)
                            .frame(height: 8)
                        
                        RoundedRectangle(cornerRadius: 4)
                            .fill(CCDesign.primaryGradient)
                            .frame(width: geometry.size.width * 0.7, height: 8)
                    }
                }
                .frame(height: 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: CCDesign.cardShadow, radius: 12, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(CCDesign.springAnimation.delay(0.2)) {
                animateBalance = true
            }
        }
    }
}

// MARK: - Recent Activity Section
struct RecentActivitySection: View {
    let events: [BillEvent]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Activity")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CCDesign.textPrimary)
                
                Spacer()
                
                Button(action: {}) {
                    Text("See All")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(CCDesign.primaryGreen)
                }
            }
            
            VStack(spacing: 12) {
                ForEach(events.prefix(3)) { event in
                    EventCard(event: event)
                }
            }
        }
    }
}

// MARK: - Event Card
struct EventCard: View {
    let event: BillEvent
    @State private var isExpanded = false
    var body: some View {
        VStack(spacing: 0) {
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(statusColor(for: event.status).opacity(0.1))
                            .frame(width: 44, height: 44)
                        
                        Image(systemName: "receipt")
                            .font(.system(size: 20))
                            .foregroundColor(statusColor(for: event.status))
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(event.eventName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(CCDesign.textPrimary)
                        
                        HStack(spacing: 8) {
                            Label("\(event.participants.count)", systemImage: "person.2.fill")
                                .font(.system(size: 12))
                                .foregroundColor(CCDesign.textSecondary)
                            
                            Text("•")
                                .foregroundColor(CCDesign.textTertiary)
                            
                            Text(event.restaurantName)
                                .font(.system(size: 12))
                                .foregroundColor(CCDesign.textSecondary)
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(String(format: "$%.2f", event.totalAmount))
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(CCDesign.textPrimary)
                        
                        EventStatusBadge(status: event.status)
                    }
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundColor(CCDesign.textTertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding(16)
            }
            .buttonStyle(PlainButtonStyle())
            
            if isExpanded {
                VStack(spacing: 12) {
                    Divider()
                    
                    // Participants preview
                    HStack {
                        ForEach(event.participants.prefix(3)) { participant in
                            ParticipantAvatar(name: participant.userName)
                        }
                        
                        if event.participants.count > 3 {
                            Text("+\(event.participants.count - 3)")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(CCDesign.textSecondary)
                                .frame(width: 32, height: 32)
                                .background(Circle().fill(CCDesign.lightGreen))
                        }
                        
                        Spacer()
                        
                        Button(action: {}) {
                            Text("View Details")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(CCDesign.primaryGreen)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: CCDesign.cardShadow, radius: 8, x: 0, y: 2)
        )
    }
    
    func statusColor(for status: BillEvent.EventStatus) -> Color {
        switch status {
        case .completed: return CCDesign.success
        case .paymentPending: return CCDesign.warning
        case .itemsClaimed: return CCDesign.info
        case .awaitingParticipants: return CCDesign.textSecondary
        case .draft: return CCDesign.textTertiary
        case .failed: return CCDesign.error
        }
    }
}

// MARK: - Achievement Progress Card
struct AchievementProgressCard: View {
    let achievements = [
        ("First Split", true, "trophy.fill"),
        ("Week Streak", true, "flame.fill"),
        ("Social Splitter", false, "person.3.fill"),
        ("Power User", false, "bolt.fill")
    ]
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CCDesign.textPrimary)
                
                Spacer()
                
                Text("2 of 4")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(CCDesign.textSecondary)
            }
            
            HStack(spacing: 12) {
                ForEach(achievements, id: \.0) { achievement in
                    AchievementBadge(
                        title: achievement.0,
                        isUnlocked: achievement.1,
                        icon: achievement.2
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: CCDesign.cardShadow, radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Supporting Components
struct FeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let color: Color
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.1))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CCDesign.textPrimary)
                
                Text(description)
                    .font(.system(size: 14))
                    .foregroundColor(CCDesign.textSecondary)
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: CCDesign.cardShadow, radius: 8, x: 0, y: 2)
        )
    }
}

struct OTPDigitField: View {
    let digit: String
    let isActive: Bool
    var body: some View {
        Text(digit)
            .font(.system(size: 24, weight: .semibold, design: .rounded))
            .foregroundColor(digit.isEmpty ? CCDesign.textSecondary : CCDesign.textPrimary)
            .frame(width: 48, height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isActive ? CCDesign.primaryGreen : Color.gray.opacity(0.3), lineWidth: isActive ? 2 : 1)
                    .background(Color.white.cornerRadius(12))
            )
            .animation(.easeInOut(duration: 0.1), value: isActive)
    }
}

struct NotificationButton: View {
    let hasUnread: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 44, height: 44)
                    .shadow(color: CCDesign.cardShadow, radius: 4, x: 0, y: 2)
                
                Image(systemName: "bell.fill")
                    .font(.system(size: 20))
                    .foregroundColor(CCDesign.primaryGreen)
                
                if hasUnread {
                    Circle()
                        .fill(CCDesign.error)
                        .frame(width: 10, height: 10)
                        .offset(x: 12, y: -12)
                }
            }
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let subtitle: String
    let gradient: LinearGradient
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 120)
            .padding(16)
            .background(gradient)
            .cornerRadius(20)
        }
    }
}

struct TrendIndicator: View {
    let value: Double
    let isPositive: Bool
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 14, weight: .semibold))
            
            Text(String(format: "%.1f%%", abs(value)))
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(isPositive ? CCDesign.success : CCDesign.error)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill((isPositive ? CCDesign.success : CCDesign.error).opacity(0.1))
        )
    }
}

struct BalanceMetric: View {
    let title: String
    let amount: String
    let color: Color
    let icon: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(CCDesign.textSecondary)
            }
            
            Text(amount)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(CCDesign.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.05))
        )
    }
}

struct EventStatusBadge: View {
    let status: BillEvent.EventStatus
    var statusConfig: (text: String, color: Color) {
        switch status {
        case .completed: return ("Settled", CCDesign.success)
        case .paymentPending: return ("Pending", CCDesign.warning)
        case .itemsClaimed: return ("Splitting", CCDesign.info)
        case .awaitingParticipants: return ("Waiting", CCDesign.textSecondary)
        case .draft: return ("Draft", CCDesign.textTertiary)
        case .failed: return ("Failed", CCDesign.error)
        }
    }
    
    var body: some View {
        Text(statusConfig.text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(statusConfig.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(statusConfig.color.opacity(0.1))
            )
    }
}

struct ParticipantAvatar: View {
    let name: String
    var initials: String {
        name.components(separatedBy: " ")
            .compactMap { $0.first }
            .map { String($0) }
            .joined()
            .uppercased()
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(CCDesign.primaryGreen.opacity(0.2))
                .frame(width: 32, height: 32)
            
            Text(initials)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(CCDesign.primaryGreen)
        }
    }
}

struct AchievementBadge: View {
    let title: String
    let isUnlocked: Bool
    let icon: String
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(isUnlocked ? CCDesign.primaryGradient : Color.gray.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(isUnlocked ? .white : Color.gray.opacity(0.5))
            }
            
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(isUnlocked ? CCDesign.textPrimary : CCDesign.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: Int
    var body: some View {
        HStack(spacing: 0) {
            TabBarButton(
                icon: "house.fill",
                title: "Home",
                isSelected: selectedTab == 0
            ) {
                selectedTab = 0
            }
            
            TabBarButton(
                icon: "calendar",
                title: "Events",
                isSelected: selectedTab == 1
            ) {
                selectedTab = 1
            }
            
            // Center action button
            Button(action: {}) {
                ZStack {
                    Circle()
                        .fill(CCDesign.primaryGradient)
                        .frame(width: 56, height: 56)
                        .shadow(color: CCDesign.primaryGreen.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "plus")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .offset(y: -8)
            
            TabBarButton(
                icon: "chart.line.uptrend.xyaxis",
                title: "Activity",
                isSelected: false
            ) {}
            
            TabBarButton(
                icon: "person.fill",
                title: "Profile",
                isSelected: selectedTab == 2
            ) {
                selectedTab = 2
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            Color.white
                .shadow(color: CCDesign.cardShadow, radius: 20, x: 0, y: -5)
        )
    }
}

struct TabBarButton: View {
    let icon: String
    let title: String
    let isSelected: Bool
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 22))
                
                Text(title)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundColor(isSelected ? CCDesign.primaryGreen : CCDesign.textSecondary)
            .frame(maxWidth: .infinity)
        }
    }
}

// MARK: - Events View Placeholder
struct EventsView: View {
    let store: StoreOf<EventsReducer>
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Events")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(CCDesign.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                    
                    // Active events section will go here
                }
                .padding(.bottom, 100)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Profile View Placeholder
struct ProfileView: View {
    let store: StoreOf<ProfileReducer>
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Profile")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(CCDesign.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)
                        .padding(.top, 60)
                    
                    // Profile content will go here
                }
                .padding(.bottom, 100)
            }
            .navigationBarHidden(true)
        }
    }
}

// MARK: - Join Event View
struct JoinEventView: View {
    let store: StoreOf<JoinEventReducer>
    @Environment(.dismiss) var dismiss
    
    var body: some View {
        WithViewStore(self.store, observe: { $0 }) { viewStore in
            NavigationView {
                ZStack {
                    CCDesign.backgroundPrimary.ignoresSafeArea()
                    
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(CCDesign.primaryGradient)
                                    .frame(width: 80, height: 80)
                                
                                Image(systemName: "qrcode.viewfinder")
                                    .font(.system(size: 32, weight: .medium))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Join Event")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(CCDesign.textPrimary)
                                
                                Text("Enter the 6-digit event code")
                                    .font(.system(size: 16))
                                    .foregroundColor(CCDesign.textSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Code Input
                        VStack(spacing: 20) {
                            HStack(spacing: 12) {
                                ForEach(0..<6, id: \.self) { index in
                                    CodeDigitView(
                                        digit: getDigit(at: index, from: viewStore.code),
                                        isActive: viewStore.code.count == index,
                                        isError: viewStore.error != nil
                                    )
                                }
                            }
                            
                            // Hidden text field for keyboard input
                            TextField("", text: viewStore.binding(
                                get: \.code,
                                send: JoinEventReducer.Action.setCode
                            ))
                            .keyboardType(.numberPad)
                            .textContentType(.oneTimeCode)
                            .opacity(0)
                            .frame(height: 1)
                            .onChange(of: viewStore.code) { newValue in
                                // Limit to 6 digits
                                if newValue.count > 6 {
                                    viewStore.send(.setCode(String(newValue.prefix(6))))
                                }
                            }
                        }
                        
                        // Error message
                        if let error = viewStore.error {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(CCDesign.error)
                                
                                Text(error)
                                    .font(.system(size: 14))
                                    .foregroundColor(CCDesign.error)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(CCDesign.error.opacity(0.1))
                            )
                        }
                        
                        Spacer()
                        
                        // Join button
                        PrimaryActionButton(
                            title: "Join Event",
                            icon: "person.badge.plus.fill",
                            isLoading: viewStore.isLoading,
                            isEnabled: viewStore.code.count == 6 && viewStore.error == nil
                        ) {
                            viewStore.send(.joinEvent)
                        }
                        .padding(.horizontal, 20)
                        
                        // Alternative options
                        VStack(spacing: 16) {
                            Button(action: {
                                // TODO: Implement QR code scanning
                            }) {
                                HStack {
                                    Image(systemName: "qrcode.viewfinder")
                                        .font(.system(size: 18))
                                    
                                    Text("Scan QR Code")
                                        .font(.system(size: 16, weight: .medium))
                                }
                                .foregroundColor(CCDesign.primaryGreen)
                                .padding(.vertical, 12)
                                .padding(.horizontal, 20)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(CCDesign.primaryGreen, lineWidth: 1.5)
                                )
                            }
                            
                            Button(action: {
                                // TODO: Implement link sharing
                            }) {
                                HStack {
                                    Image(systemName: "link")
                                        .font(.system(size: 16))
                                    
                                    Text("Join via Link")
                                        .font(.system(size: 14))
                                }
                                .foregroundColor(CCDesign.textSecondary)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                    .padding(.horizontal, 20)
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                        .foregroundColor(CCDesign.primaryGreen)
                    }
                }
                .onAppear {
                    // Auto-focus the text field
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        // This would focus the hidden text field
                    }
                }
            }
        }
    }
    
    private func getDigit(at index: Int, from code: String) -> String {
        guard index < code.count else { return "" }
        let stringIndex = code.index(code.startIndex, offsetBy: index)
        return String(code[stringIndex])
    }
}

// MARK: - Code Digit View
struct CodeDigitView: View {
    let digit: String
    let isActive: Bool
    let isError: Bool
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: 2)
                )
                .frame(width: 50, height: 60)
            
            if digit.isEmpty {
                if isActive {
                    Rectangle()
                        .fill(CCDesign.primaryGreen)
                        .frame(width: 2, height: 24)
                        .opacity(0.8)
                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isActive)
                }
            } else {
                Text(digit)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(CCDesign.textPrimary)
            }
        }
    }
    
    private var borderColor: Color {
        if isError {
            return CCDesign.error
        } else if isActive {
            return CCDesign.primaryGreen
        } else {
            return CCDesign.primaryGreen.opacity(0.3)
        }
    }
}
