//
//  OnboardingView.swift
//  AI Cleaner
//
//  Onboarding flow with privacy and permission screens
//

import SwiftUI
import Combine

struct OnboardingView: View {
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool

    var body: some View {
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
        .onAppear {
            AnalyticsManager.shared.logOnboardingStarted()
        }
    }
}

// MARK: - Welcome Page

struct WelcomePageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Icon
            Image(systemName: "sparkles.square.filled.on.square")
                .font(.system(size: 100))
                .foregroundColor(.blue)

            VStack(spacing: 16) {
                Text("Welcome to AI Cleaner")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("Smart, on-device photo cleaning powered by AI")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 16) {
                FeatureRow(
                    icon: "square.on.square",
                    title: "Find Duplicates",
                    description: "Automatically detect similar photos"
                )

                FeatureRow(
                    icon: "eye.slash",
                    title: "Detect Blurry Photos",
                    description: "Identify low-quality images"
                )

                FeatureRow(
                    icon: "camera",
                    title: "Find Screenshots",
                    description: "Organize and clean up screenshots"
                )
            }
            .padding(.horizontal)

            Spacer()

            Text("Swipe to continue")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom)
        }
    }
}

// MARK: - Privacy Page

struct PrivacyPageView: View {
    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "lock.shield.fill")
                .font(.system(size: 100))
                .foregroundColor(.green)

            VStack(spacing: 16) {
                Text("Your Privacy Matters")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("All analysis happens on your device")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 20) {
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
            .padding(.horizontal)

            Spacer()

            Text("Swipe to continue")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.bottom)
        }
    }
}

// MARK: - Permission Page

struct PermissionPageView: View {
    @State private var isRequesting = false
    let onPermissionGranted: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "photo.stack")
                .font(.system(size: 100))
                .foregroundColor(.purple)

            VStack(spacing: 16) {
                Text("Access Your Photos")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("We need access to analyze and clean your photo library")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Spacer()

            VStack(spacing: 16) {
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
            .padding(.horizontal)

            Spacer()

            Button(action: requestPermission) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(.circular)
                            .tint(.white)
                    } else {
                        Text("Grant Photo Access")
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(isRequesting)
            .padding(.horizontal)
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct PrivacyFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
    }
}

struct InfoRow: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.green)
            Text(text)
                .font(.body)
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
