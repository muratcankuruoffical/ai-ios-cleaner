//
//  OnboardingView.swift
//  AI Cleaner
//
//  Onboarding flow with privacy and permission screens - Dark Theme
//

import SwiftUI
internal import Combine

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        ZStack {
            CleanerTheme.background
                .ignoresSafeArea()

            TabView(selection: $viewModel.currentPage) {
                WelcomePageView()
                    .tag(0)

                PrivacyPageView()
                    .tag(1)

                PermissionPageView(
                    onPermissionGranted: {
                        isOnboardingComplete = true
                        AnalyticsManager.shared.logOnboardingCompleted()
                    }
                )
                .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
        }
        .preferredColorScheme(.dark)
        .onAppear {
            AnalyticsManager.shared.logOnboardingStarted()
        }
    }
}

// MARK: - Welcome Page (Dark Theme)

struct WelcomePageView: View {
    @State private var animateIcon = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // App Icon with Animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [CleanerTheme.primary.opacity(0.3), CleanerTheme.accent.opacity(0.2)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateIcon ? 1.0 : 0.8)
                    .opacity(animateIcon ? 1.0 : 0.6)

                Image(systemName: "sparkles.square.filled.on.square")
                    .font(.system(size: 80))
                    .foregroundColor(CleanerTheme.primary)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateIcon = true
                }
            }

            VStack(spacing: 16) {
                Text("Welcome to AI Cleaner")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Smart, on-device photo cleaning powered by AI")
                    .cleanerFont(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                FeatureRow(
                    icon: "rectangle.on.rectangle.angled",
                    title: "Find Duplicates",
                    description: "Automatically detect similar photos",
                    color: CleanerTheme.primary
                )

                FeatureRow(
                    icon: "eye.slash",
                    title: "Detect Blurry Photos",
                    description: "Identify low-quality images",
                    color: CleanerTheme.accentGreen
                )

                FeatureRow(
                    icon: "camera.viewfinder",
                    title: "Find Screenshots",
                    description: "Organize and clean up screenshots",
                    color: CleanerTheme.accent
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10))
                Text("Swipe to continue")
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
            }
            .cleanerFont(.caption)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Privacy Page (Dark Theme)

struct PrivacyPageView: View {
    @State private var animateShield = false

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [CleanerTheme.accentGreen.opacity(0.3), CleanerTheme.accentGreen.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .scaleEffect(animateShield ? 1.0 : 0.9)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 80))
                    .foregroundColor(CleanerTheme.accentGreen)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    animateShield = true
                }
            }

            VStack(spacing: 16) {
                Text("Your Privacy Matters")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("All analysis happens on your device")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(CleanerTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 16) {
                PrivacyFeatureRow(
                    icon: "iphone",
                    title: "100% On-Device",
                    description: "Your photos never leave your device"
                )

                PrivacyFeatureRow(
                    icon: "xmark.shield",
                    title: "No Cloud Upload",
                    description: "Zero data transmitted to servers"
                )

                PrivacyFeatureRow(
                    icon: "person.badge.shield.checkmark",
                    title: "Complete Privacy",
                    description: "No one can access your photos but you"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            HStack(spacing: 6) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 10))
                Text("Swipe to continue")
                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
            }
            .cleanerFont(.caption)
            .padding(.bottom, 32)
        }
    }
}

// MARK: - Permission Page (Dark Theme)

struct PermissionPageView: View {
    @State private var isRequesting = false
    let onPermissionGranted: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [CleanerTheme.accent.opacity(0.3), CleanerTheme.accent.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)

                Image(systemName: "photo.stack")
                    .font(.system(size: 80))
                    .foregroundColor(CleanerTheme.accent)
            }

            VStack(spacing: 16) {
                Text("Access Your Photos")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)
                    .multilineTextAlignment(.center)

                Text("We need access to analyze and clean your photo library")
                    .cleanerFont(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(spacing: 12) {
                InfoRow(
                    icon: "checkmark.circle.fill",
                    text: "Scan for duplicates and similar photos"
                )

                InfoRow(
                    icon: "checkmark.circle.fill",
                    text: "Detect blurry and low-quality images"
                )

                InfoRow(
                    icon: "checkmark.circle.fill",
                    text: "Find screenshots and large videos"
                )

                InfoRow(
                    icon: "checkmark.circle.fill",
                    text: "Safely delete unwanted photos"
                )
            }
            .padding(.horizontal, 24)

            Spacer()

            Button(action: requestPermission) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Grant Photo Access")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .foregroundColor(.white)
                .background(
                    LinearGradient(
                        colors: [CleanerTheme.primary, Color(hex: "#0066DD")],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
            }
            .disabled(isRequesting)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    private func requestPermission() {
        isRequesting = true
        AnalyticsManager.shared.logPermissionRequested(permissionType: "photo_library")

        Task {
            let granted = await PhotoLibraryService.shared.requestAuthorization()

            await MainActor.run {
                isRequesting = false

                if granted {
                    AnalyticsManager.shared.logPermissionGranted(permissionType: "photo_library")
                    onPermissionGranted()
                } else {
                    AnalyticsManager.shared.logPermissionDenied(permissionType: "photo_library")
                }
            }
        }
    }
}

// MARK: - Helper Views (Dark Theme)

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)
                Text(description)
                    .cleanerFont(.caption)
            }

            Spacer()
        }
        .padding(16)
        .card(backgroundColor: CleanerTheme.surface)
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(CleanerTheme.accentGreen.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(CleanerTheme.accentGreen)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(CleanerTheme.textPrimary)
                Text(description)
                    .cleanerFont(.caption)
            }

            Spacer()
        }
        .padding(16)
        .card(backgroundColor: CleanerTheme.surface)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(CleanerTheme.accentGreen)
            Text(text)
                .cleanerFont(.body)
            Spacer()
        }
    }
}

// MARK: - View Model

class OnboardingViewModel: ObservableObject {
    @Published var currentPage: Int = 0
}

// MARK: - Preview

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
