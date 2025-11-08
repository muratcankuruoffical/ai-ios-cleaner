//
//  MainTabView.swift
//  AI Cleaner
//
//  Main tab bar navigation
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            // Dashboard Tab
            DashboardView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            // AI Photo Search Tab
            AIPhotoSearchView()
                .tabItem {
                    Label("AI Search", systemImage: "sparkles.magnifyingglass")
                }
                .tag(1)

            // Settings Tab
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
                .tag(2)
        }
        .accentColor(CleanerTheme.primary)
        .preferredColorScheme(.dark)
        .onAppear {
            // Customize tab bar appearance
            let appearance = UITabBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor(CleanerTheme.surface)

            // Selected item color
            appearance.stackedLayoutAppearance.selected.iconColor = UIColor(CleanerTheme.primary)
            appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
                .foregroundColor: UIColor(CleanerTheme.primary)
            ]

            // Normal item color
            appearance.stackedLayoutAppearance.normal.iconColor = UIColor(CleanerTheme.textSecondary)
            appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
                .foregroundColor: UIColor(CleanerTheme.textSecondary)
            ]

            UITabBar.appearance().standardAppearance = appearance
            UITabBar.appearance().scrollEdgeAppearance = appearance
        }
    }
}

#Preview {
    MainTabView()
        .environment(\.managedObjectContext, CoreDataStack.shared.viewContext)
}
