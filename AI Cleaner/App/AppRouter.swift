//
//  AppRouter.swift
//  AI Cleaner
//
//  Main app router for navigation
//

import SwiftUI
internal import Combine

struct AppRouter: View {
    @ObservedObject var appState: AppState

    var body: some View {
        Group {
            if !appState.isOnboardingComplete {
                OnboardingView(isOnboardingComplete: .init(
                    get: { appState.isOnboardingComplete },
                    set: { newValue in
                        if newValue {
                            appState.completeOnboarding()
                            appState.checkPhotoLibraryAccess()
                        }
                    }
                ))
            } else if !appState.hasPhotoLibraryAccess {
                PermissionDeniedView()
            } else {
                MainTabView()
            }
        }
    }
}

// MARK: - Permission Denied View

struct PermissionDeniedView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "photo.badge.exclamationmark")
                .font(.system(size: 80))
                .foregroundColor(.red)

            VStack(spacing: 12) {
                Text("Photo Access Required")
                    .font(.title)
                    .fontWeight(.bold)

                Text("AI Cleaner needs access to your photo library to scan and organize your photos.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            VStack(spacing: 16) {
                Text("To grant access:")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Text("1.")
                            .fontWeight(.bold)
                        Text("Open Settings app")
                    }

                    HStack(spacing: 12) {
                        Text("2.")
                            .fontWeight(.bold)
                        Text("Go to AI Cleaner")
                    }

                    HStack(spacing: 12) {
                        Text("3.")
                            .fontWeight(.bold)
                        Text("Tap Photos and select 'Full Access'")
                    }
                }
                .font(.body)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)

            Button(action: {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }) {
                Text("Open Settings")
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Preview

#Preview("Router") {
    AppRouter(appState: AppState())
}

#Preview("Permission Denied") {
    PermissionDeniedView()
}
