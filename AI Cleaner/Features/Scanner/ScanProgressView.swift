//
//  ScanProgressView.swift
//  AI Cleaner
//
//  View for displaying scan progress
//

import SwiftUI
internal import Combine

struct ScanProgressView: View {
    @ObservedObject var coordinator: ScanCoordinator

    var body: some View {
        ZStack {
            CleanerTheme.background.ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Animated Icon
                ProgressRingView(progress: coordinator.progress.percentage)
                    .scaleIn()

                VStack(spacing: 12) {
                    Text(coordinator.progress.currentStep)
                        .cleanerFont(.title2)
                        .foregroundColor(CleanerTheme.textPrimary)

                    Text("\(coordinator.progress.currentItemIndex) / \(coordinator.progress.totalItems)")
                        .cleanerFont(.body)
                        .foregroundColor(CleanerTheme.textSecondary)

                    if coordinator.progress.percentage > 0 {
                        Text(String(format: "%.0f%% Complete", coordinator.progress.percentage * 100))
                            .cleanerFont(.caption)
                            .foregroundColor(CleanerTheme.textTertiary)
                    }
                }
                .fadeIn(delay: 0.2)

                ProgressView(value: coordinator.progress.percentage)
                    .progressViewStyle(.linear)
                    .tint(CleanerTheme.primary)
                    .frame(maxWidth: 300)

                Spacer()

                Button(action: {
                    coordinator.cancelScan()
                }) {
                    Text("Cancel")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(CleanerTheme.accentRed)
                        .padding(.horizontal, 32)
                        .padding(.vertical, 12)
                        .background(CleanerTheme.accentRed.opacity(0.15))
                        .cornerRadius(12)
                }
                .padding(.bottom, 32)
            }
            .padding()
        }
    }
}

// MARK: - Progress Ring

struct ProgressRingView: View {
    let progress: Double

    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(CleanerTheme.surface, lineWidth: 12)
                .frame(width: 120, height: 120)

            // Progress ring
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    CleanerTheme.primaryGradient,
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .frame(width: 120, height: 120)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: progress)

            // Icon
            Image(systemName: "sparkles")
                .font(.system(size: 40, weight: .semibold))
                .foregroundColor(CleanerTheme.iconGray)
        }
    }
}

// MARK: - Results View

struct ScanResultsView: View {
    let results: ScanCoordinator.ScanResults
    @Binding var showingResults: Bool

    var body: some View {
        NavigationView {
            ZStack {
                CleanerTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(CleanerTheme.accentGreen.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 30)

                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 64))
                                    .foregroundColor(CleanerTheme.accentGreen)
                            }
                            .scaleIn()

                            VStack(spacing: 8) {
                                Text("Scan Complete!")
                                    .cleanerFont(.title)
                                    .foregroundColor(CleanerTheme.textPrimary)

                                Text("Found \(results.statistics.totalDuplicates) items to clean")
                                    .cleanerFont(.body)
                                    .foregroundColor(CleanerTheme.textSecondary)
                            }
                            .fadeIn(delay: 0.2)
                        }
                        .padding(.top, 32)

                        // Potential Savings Card
                        VStack(spacing: 16) {
                            Text("Potential Space Savings")
                                .cleanerFont(.headline)
                                .foregroundColor(CleanerTheme.textPrimary)

                            Text(results.formattedSavings)
                                .font(.system(size: 48, weight: .bold))
                                .foregroundColor(CleanerTheme.primary)

                            Text("by cleaning suggested items")
                                .cleanerFont(.caption)
                                .foregroundColor(CleanerTheme.textSecondary)
                        }
                        .padding(24)
                        .frame(maxWidth: .infinity)
                        .background(CleanerTheme.cardBackground)
                        .cornerRadius(20)
                        .padding(.horizontal)
                        .scaleIn(delay: 0.3)

                        // Categories
                        VStack(spacing: 16) {
                            if !results.similarGroups.isEmpty {
                                ResultCategoryCard(
                                    icon: "square.on.square",
                                    title: "Similar Photos",
                                    count: results.statistics.totalDuplicates,
                                    color: CleanerTheme.primary
                                )
                                .scaleIn(delay: 0.4)
                            }

                            if !results.blurryPhotos.isEmpty {
                                ResultCategoryCard(
                                    icon: "eye.slash",
                                    title: "Blurry Photos",
                                    count: results.blurryPhotos.count,
                                    color: CleanerTheme.accent
                                )
                                .scaleIn(delay: 0.5)
                            }

                            if !results.darkPhotos.isEmpty {
                                ResultCategoryCard(
                                    icon: "moon",
                                    title: "Dark Photos",
                                    count: results.darkPhotos.count,
                                    color: CleanerTheme.accentGreen
                                )
                                .scaleIn(delay: 0.6)
                            }

                            if !results.screenshots.isEmpty {
                                ResultCategoryCard(
                                    icon: "camera.viewfinder",
                                    title: "Screenshots",
                                    count: results.screenshots.count,
                                    color: CleanerTheme.accentRed
                                )
                                .scaleIn(delay: 0.7)
                            }

                            if !results.largeVideos.isEmpty {
                                ResultCategoryCard(
                                    icon: "video.fill",
                                    title: "Large Videos",
                                    count: results.largeVideos.count,
                                    color: CleanerTheme.primary
                                )
                                .scaleIn(delay: 0.8)
                            }
                        }
                        .padding(.horizontal)

                        // Action Button
                        Button(action: {
                            showingResults = false
                        }) {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.right.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Start Cleaning")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(CleanerTheme.primaryGradient)
                            .cornerRadius(16)
                        }
                        .padding(.horizontal)
                        .scaleIn(delay: 0.9)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        showingResults = false
                    }
                    .foregroundColor(CleanerTheme.primary)
                }
            }
        }
    }
}

// MARK: - Result Category Card

struct ResultCategoryCard: View {
    let icon: String
    let title: String
    let count: Int
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
                Text("\(count) items found")
                    .cleanerFont(.caption)
                    .foregroundColor(CleanerTheme.textSecondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(CleanerTheme.iconGray)
        }
        .padding(16)
        .background(CleanerTheme.cardBackground)
        .cornerRadius(16)
    }
}

// MARK: - Preview

#Preview("Progress") {
    ScanProgressView(coordinator: ScanCoordinator())
}

#Preview("Results") {
    ScanResultsView(
        results: ScanCoordinator.ScanResults(
            sessionId: UUID(),
            scanDuration: 45.0,
            totalPhotos: 1000,
            totalVideos: 50,
            similarGroups: [],
            blurryPhotos: [],
            darkPhotos: [],
            screenshots: [],
            largeVideos: [],
            similarVideoGroups: [],
            optimizablePhotos: [],
            documents: [],
            contactsResults: nil,
            calendarResults: nil,
            potentialSavingsBytes: 2_500_000_000,
            statistics: CleanupStatistics(
                totalGroups: 25,
                totalDuplicates: 150,
                potentialSavingsBytes: 2_500_000_000,
                largestGroupSize: 8
            )
        ),
        showingResults: .constant(true)
    )
}
