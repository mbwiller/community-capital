// SplashView.swift
import SwiftUI

struct SplashView: View {
    @State private var animationAmount = 1.0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.3.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)
                .scaleEffect(animationAmount)
                .animation(
                    .easeInOut(duration: 1.0)
                    .repeatForever(autoreverses: true),
                    value: animationAmount
                )
            
            Text("Community Capital")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())
                .scaleEffect(1.5)
        }
        .onAppear {
            animationAmount = 1.2
        }
    }
}