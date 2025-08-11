import Foundation
import SwiftUI

struct Config {
    // Backend API Configuration
    static let baseURL = "http://localhost:3000/api"
    
    // For testing on physical device, replace localhost with your Mac's IP:
    // static let baseURL = "http://YOUR_MAC_IP:3000/api"
    // To find your Mac's IP: System Settings → Network → Wi-Fi → Details
    
    // Stripe Configuration (Test Mode)
    // Get your test key from: https://dashboard.stripe.com/test/apikeys
    static let stripePublishableKey = "pk_test_51RsYTRFqqgZ0ydP8oymhadMQN2Gnsf8R9s03UcVRonAP7iDobzlvEYsuAu17RcX1BeH1nMk1LEQCgdrRyp9mO0Ox00staWEM3U"
    
    // Plaid Configuration (Sandbox Mode)
    // Get your sandbox key from: https://dashboard.plaid.com/developers/keys
    static let plaidPublicKey = "fbfe1ca26c505d86f92b140f3ac981"
    
    // Environment Detection
    static let isDebug: Bool = {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }()
    
    // WebSocket Configuration
    static let websocketURL = "ws://localhost:3000"
    
    // Feature Flags
    static let enableMockData = true  // Use mock data when backend is not running
    static let enableLogging = isDebug
    static let enableCrashReporting = !isDebug
    
    // Timeouts
    static let apiTimeout: TimeInterval = 30.0
    static let uploadTimeout: TimeInterval = 60.0
}

// MARK: - Design System
struct CCDesign {
    // Colors
    static let backgroundPrimary = Color(.systemBackground)
    static let textPrimary = Color(.label)
    static let textSecondary = Color(.secondaryLabel)
    static let textTertiary = Color(.tertiaryLabel)
    static let primaryGreen = Color.green
    static let primaryGradient = LinearGradient(
        colors: [Color.green, Color.green.opacity(0.8)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Animations
    static let springAnimation = Animation.spring(response: 0.6, dampingFraction: 0.8)
}

// MARK: - UI Components
struct PrimaryActionButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void
    
    init(_ title: String, icon: String? = nil, isLoading: Bool = false, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.isEnabled = isEnabled
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else {
                    Text(title)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(isEnabled ? CCDesign.primaryGradient : LinearGradient(colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
            .cornerRadius(12)
            .shadow(color: isEnabled ? CCDesign.primaryGreen.opacity(0.3) : Color.clear, radius: 8, x: 0, y: 4)
        }
        .disabled(isLoading || !isEnabled)
    }
}
