//
//  LaunchScreenView.swift
//  Interviews
//
//  Created by keloran on 07/12/2025.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color.accentColor.opacity(0.1),
                    Color.accentColor.opacity(0.05)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                // Logo/Icon - Using App Icon
                ZStack {
                    // Background circle with subtle glow
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 140, height: 140)
                        .blur(radius: 20)
                        .scaleEffect(isAnimating ? 1.2 : 1.0)
                    
                    // App Icon
                    if let appIcon = Bundle.main.icon {
                        Image(uiImage: appIcon)
                            .resizable()
                            .frame(width: 120, height: 120)
                            .clipShape(RoundedRectangle(cornerRadius: 26.4, style: .continuous))
                            .shadow(color: Color.accentColor.opacity(0.3), radius: 20, y: 10)
                            .scaleEffect(isAnimating ? 1.0 : 0.8)
                    } else {
                        // Fallback to styled circle with icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.accentColor,
                                            Color.accentColor.opacity(0.8)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .shadow(color: Color.accentColor.opacity(0.3), radius: 20, y: 10)
                            
                            Image(systemName: "calendar.badge.checkmark")
                                .font(.system(size: 50, weight: .medium))
                                .foregroundStyle(.white)
                        }
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                    }
                }
                
                // App name
                Text("Interviews")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color.primary,
                                Color.primary.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .opacity(isAnimating ? 1.0 : 0.0)
                
                Spacer()
                
                // Loading indicator
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(Color.accentColor)
                    
                    Text("Loading...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .padding(.bottom, 60)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

// MARK: - Bundle Extension for App Icon
extension Bundle {
    var icon: UIImage? {
        // Try to get the app icon from the Info.plist
        guard let icons = infoDictionary?["CFBundleIcons"] as? [String: Any],
              let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
              let iconFiles = primaryIcon["CFBundleIconFiles"] as? [String],
              let lastIcon = iconFiles.last else {
            return nil
        }
        
        return UIImage(named: lastIcon)
    }
}

#Preview {
    LaunchScreenView()
}
