//
//  AI_CleanerApp.swift
//  AI Cleaner
//
//  Main application entry point
//

import SwiftUI
import CoreData
internal import Combine

@main
struct AI_CleanerApp: App {
    @StateObject private var appState = AppState()

    init() {
        // Configure services
        configureServices()
    }

    var body: some Scene {
        WindowGroup {
            AppRouter(appState: appState)
                .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
        }
    }

    private func configureServices() {
        // Configure RevenueCat
        RevenueCatManager.shared.configure()

        // Configure Analytics
        AnalyticsManager.shared.configure()

        // Log app launch
        AnalyticsManager.shared.logAppLaunch()

        // Check subscription status
        Task {
            await RevenueCatManager.shared.checkSubscriptionStatus()
        }
    }
}

// MARK: - App State

@MainActor
class AppState: ObservableObject {
    @Published var isOnboardingComplete: Bool
    @Published var hasPhotoLibraryAccess: Bool = false

    init() {
        // Check if onboarding is complete
        isOnboardingComplete = UserDefaults.standard.bool(forKey: "onboarding_complete")

        // Check photo library access
        checkPhotoLibraryAccess()
    }

    func completeOnboarding() {
        isOnboardingComplete = true
        UserDefaults.standard.set(true, forKey: "onboarding_complete")
    }

    func checkPhotoLibraryAccess() {
        hasPhotoLibraryAccess = PhotoLibraryService.shared.isAuthorized
    }
}
