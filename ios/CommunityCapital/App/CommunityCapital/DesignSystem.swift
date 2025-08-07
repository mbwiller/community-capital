// DesignSystem.swift
import SwiftUI
// MARK: - Design System
struct CCDesign {
    // Brand Colors
    static let primaryGreen = Color(red: 0.0, green: 0.8, blue: 0.4)
    static let darkGreen = Color(red: 0.0, green: 0.6, blue: 0.3)
    static let lightGreen = Color(red: 0.92, green: 0.98, blue: 0.94)
    static let accentOrange = Color(red: 1.0, green: 0.6, blue: 0.2)
    
    // Neutral Colors
    static let backgroundPrimary = Color(red: 0.98, green: 0.98, blue: 0.99)
    static let backgroundSecondary = Color.white
    static let textPrimary = Color(red: 0.08, green: 0.08, blue: 0.12)
    static let textSecondary = Color(red: 0.4, green: 0.4, blue: 0.45)
    static let textTertiary = Color(red: 0.6, green: 0.6, blue: 0.65)
    
    // Semantic Colors
    static let success = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let warning = Color(red: 1.0, green: 0.7, blue: 0.0)
    static let error = Color(red: 0.95, green: 0.25, blue: 0.25)
    static let info = Color(red: 0.2, green: 0.6, blue: 1.0)
    
    // Gradients
    static let primaryGradient = LinearGradient(
        colors: [primaryGreen, darkGreen],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let subtleGradient = LinearGradient(
        colors: [backgroundPrimary, backgroundSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
    
    // Shadows
    static let cardShadow = Color.black.opacity(0.06)
    static let buttonShadow = Color.black.opacity(0.12)
    
    // Animation
    static let springAnimation = Animation.spring(response: 0.4, dampingFraction: 0.75)
    static let easeAnimation = Animation.easeInOut(duration: 0.3)
}

// MARK: - Reusable Components
struct PrimaryActionButton: View {
    let title: String
    var icon: String? = nil
    var isLoading: Bool = false
    var isEnabled: Bool = true
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            if isEnabled && !isLoading {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    isPressed = true
                }
                
                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                impactFeedback.impactOccurred()
                
                action()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }) {
            HStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                } else if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                Group {
                    if isEnabled && !isLoading {
                        CCDesign.primaryGradient
                    } else {
                        Color.gray.opacity(0.3)
                    }
                }
            )
            .cornerRadius(16)
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .shadow(
                color: isEnabled && !isLoading ? CCDesign.buttonShadow : Color.clear,
                radius: 8,
                x: 0,
                y: 4
            )
        }
        .disabled(!isEnabled || isLoading)
    }
}

struct SecondaryActionButton: View {
    let title: String
    var icon: String? = nil
    let action: () -> Void
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(CCDesign.primaryGreen)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(CCDesign.primaryGreen, lineWidth: 1.5)
                    .background(Color.white.cornerRadius(12))
            )
        }
    }
}

struct GlassCard<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(CCDesign.backgroundSecondary)
                    .shadow(color: CCDesign.cardShadow, radius: 12, x: 0, y: 4)
            )
    }
}

struct ErrorBanner: View {
    let message: String
    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(CCDesign.error)
            
            Text(message)
                .font(.system(size: 14))
                .foregroundColor(CCDesign.error)
            
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(CCDesign.error.opacity(0.1))
        )
    }
}
