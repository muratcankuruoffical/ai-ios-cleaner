//
//  OnboardingView.swift
//  AI Cleaner
//
//  Onboarding flow with privacy and permission screens
//

import SwiftUI
internal import Combine

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool

    var body: some View {
        ZStack {
            CleanerTheme.background.ignoresSafeArea()

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
        .onAppear {
            AnalyticsManager.shared.logOnboardingStarted()
        }
    }
}

// MARK: - Welcome Page

struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // App Icon with gradient
            ZStack {
                Circle()
                    .fill(CleanerTheme.primaryGradient)
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)

                Circle()
                    .fill(CleanerTheme.primary.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "sparkles")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(CleanerTheme.iconGray)
            }
            .scaleIn()

            VStack(spacing: 16) {
                Text("Welcome to")
                    .cleanerFont(.title2)
                    .foregroundColor(CleanerTheme.textSecondary)

                Text("AI Cleaner")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text("Smart, on-device photo cleaning\npowered by AI")
                    .cleanerFont(.body)
                    .foregroundColor(CleanerTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .fadeIn(delay: 0.2)

            Spacer()

            VStack(spacing: 20) {
                OnboardingFeatureRow(
                    icon: "square.on.square",
                    title: "Find Duplicates",
                    description: "Automatically detect similar photos",
                    color: CleanerTheme.primary
                )
                .fadeIn(delay: 0.3)

                OnboardingFeatureRow(
                    icon: "eye.slash",
                    title: "Detect Blurry Photos",
                    description: "Identify low-quality images",
                    color: CleanerTheme.accent
                )
                .fadeIn(delay: 0.4)

                OnboardingFeatureRow(
                    icon: "camera.viewfinder",
                    title: "Find Screenshots",
                    description: "Organize and clean up screenshots",
                    color: CleanerTheme.accentGreen
                )
                .fadeIn(delay: 0.5)
            }
            .padding(.horizontal)

            Spacer()

            Text("Swipe to continue")
                .cleanerFont(.caption)
                .foregroundColor(CleanerTheme.textTertiary)
                .padding(.bottom)
        }
    }
}

// MARK: - Privacy Page

struct PrivacyPageView: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Privacy Icon
            ZStack {
                Circle()
                    .fill(CleanerTheme.accentGreen.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)

                Circle()
                    .fill(CleanerTheme.accentGreen.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(CleanerTheme.iconGray)
            }
            .scaleIn()

            VStack(spacing: 16) {
                Text("Your Privacy")
                    .font(.system(size: 42, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text("All analysis happens on your device")
                    .cleanerFont(.title2)
                    .foregroundColor(CleanerTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .fadeIn(delay: 0.2)

            Spacer()

            VStack(spacing: 20) {
                PrivacyFeatureCard(
                    icon: "iphone",
                    title: "100% On-Device",
                    description: "Your photos never leave your device"
                )
                .fadeIn(delay: 0.3)

                PrivacyFeatureCard(
                    icon: "xmark.shield",
                    title: "No Cloud Upload",
                    description: "Zero data transmitted to servers"
                )
                .fadeIn(delay: 0.4)

                PrivacyFeatureCard(
                    icon: "person.badge.shield.checkmark",
                    title: "Complete Privacy",
                    description: "No one can access your photos but you"
                )
                .fadeIn(delay: 0.5)
            }
            .padding(.horizontal)

            Spacer()

            Text("Swipe to continue")
                .cleanerFont(.caption)
                .foregroundColor(CleanerTheme.textTertiary)
                .padding(.bottom)
        }
    }
}

// MARK: - Permission Page

struct PermissionPageView: View {
    @State private var isRequesting = false
    let onPermissionGranted: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Photo Icon
            ZStack {
                Circle()
                    .fill(CleanerTheme.accent.opacity(0.2))
                    .frame(width: 140, height: 140)
                    .blur(radius: 40)

                Circle()
                    .fill(CleanerTheme.accent.opacity(0.15))
                    .frame(width: 120, height: 120)

                Image(systemName: "photo.stack")
                    .font(.system(size: 60, weight: .semibold))
                    .foregroundColor(CleanerTheme.iconGray)
            }
            .scaleIn()

            VStack(spacing: 16) {
                Text("Access Your Photos")
                    .font(.system(size: 38, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text("We need access to analyze and clean\nyour photo library")
                    .cleanerFont(.body)
                    .foregroundColor(CleanerTheme.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .fadeIn(delay: 0.2)

            Spacer()

            VStack(spacing: 16) {
                PermissionCheckRow(text: "Scan for duplicates and similar photos")
                    .fadeIn(delay: 0.3)
                PermissionCheckRow(text: "Detect blurry and low-quality images")
                    .fadeIn(delay: 0.4)
                PermissionCheckRow(text: "Find screenshots and large videos")
                    .fadeIn(delay: 0.5)
                PermissionCheckRow(text: "Safely delete unwanted photos")
                    .fadeIn(delay: 0.6)
            }
            .padding(.horizontal, 32)

            Spacer()

            Button(action: requestPermission) {
                HStack(spacing: 12) {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Image(systemName: "photo.badge.checkmark")
                            .font(.system(size: 18, weight: .semibold))
                        Text("Grant Photo Access")
                            .font(.system(size: 18, weight: .semibold))
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(CleanerTheme.primaryGradient)
                .cornerRadius(16)
            }
            .disabled(isRequesting)
            .padding(.horizontal, 32)
            .scaleIn(delay: 0.7)
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

// MARK: - Helper Views

struct OnboardingFeatureRow: View {
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
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CleanerTheme.iconGray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .cleanerFont(.headline)
                    .foregroundColor(CleanerTheme.textPrimary)
                Text(description)
                    .cleanerFont(.caption)
                    .foregroundColor(CleanerTheme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(CleanerTheme.cardBackground)
        .cornerRadius(16)
    }
}

struct PrivacyFeatureCard: View {
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
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(CleanerTheme.iconGray)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .cleanerFont(.headline)
                    .foregroundColor(CleanerTheme.textPrimary)
                Text(description)
                    .cleanerFont(.caption)
                    .foregroundColor(CleanerTheme.textSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(CleanerTheme.cardBackground)
        .cornerRadius(16)
    }
}

struct PermissionCheckRow: View {
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(CleanerTheme.accentGreen)
                .font(.system(size: 20, weight: .semibold))
            Text(text)
                .cleanerFont(.body)
                .foregroundColor(CleanerTheme.textPrimary)
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
