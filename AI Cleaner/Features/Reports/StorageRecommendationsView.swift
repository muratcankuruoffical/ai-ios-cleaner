//
//  StorageRecommendationsView.swift
//  AI Cleaner
//
//  UI for storage cleaning recommendations
//

import SwiftUI

struct StorageRecommendationsView: View {
    let storageInfo: SystemInsights.StorageInfo?
    @State private var selectedRecommendation: StorageRecommendations.Recommendation?
    @State private var showingInstructions = false

    private var recommendations: [StorageRecommendations.Recommendation] {
        StorageRecommendations.shared.getRecommendations(basedOn: storageInfo)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    headerView

                    // Recommendations List
                    VStack(spacing: 12) {
                        ForEach(recommendations, id: \.type.rawValue) { recommendation in
                            RecommendationCard(recommendation: recommendation) {
                                selectedRecommendation = recommendation
                                showingInstructions = true
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Storage Tips")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingInstructions) {
                if let recommendation = selectedRecommendation {
                    InstructionsView(recommendation: recommendation)
                }
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                    .font(.title2)

                Text("How to Free Up Space")
                    .font(.title2)
                    .fontWeight(.bold)
            }

            if let storage = storageInfo {
                Text("Your device is \(Int(storage.usagePercentage))% full. Here are ways to free up space:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Text("Here are ways to free up space on your device:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// MARK: - Recommendation Card

struct RecommendationCard: View {
    let recommendation: StorageRecommendations.Recommendation
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(priorityColor.opacity(0.15))
                        .frame(width: 50, height: 50)

                    Image(systemName: recommendation.icon)
                        .font(.title3)
                        .foregroundColor(priorityColor)
                }

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(recommendation.title)
                            .font(.headline)
                            .foregroundColor(.primary)

                        if recommendation.priority == .high {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                    }

                    Text(recommendation.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.leading)

                    Text("Potential: \(recommendation.estimatedSavings)")
                        .font(.caption2)
                        .foregroundColor(priorityColor)
                        .fontWeight(.medium)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(priorityColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var priorityColor: Color {
        switch recommendation.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Instructions View

struct InstructionsView: View {
    let recommendation: StorageRecommendations.Recommendation
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(priorityColor.opacity(0.15))
                                    .frame(width: 60, height: 60)

                                Image(systemName: recommendation.icon)
                                    .font(.largeTitle)
                                    .foregroundColor(priorityColor)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(recommendation.title)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Potential savings: \(recommendation.estimatedSavings)")
                                    .font(.subheadline)
                                    .foregroundColor(priorityColor)
                            }
                        }

                        Text(recommendation.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(priorityColor.opacity(0.1))
                    .cornerRadius(12)

                    // Instructions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Step-by-Step Guide")
                            .font(.headline)

                        ForEach(Array(recommendation.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(priorityColor)
                                        .frame(width: 28, height: 28)

                                    Text("\(index + 1)")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                }

                                Text(instruction)
                                    .font(.body)
                                    .fixedSize(horizontal: false, vertical: true)

                                Spacer()
                            }
                        }
                    }

                    // Action Button
                    if let deepLink = recommendation.deepLink {
                        Button(action: {
                            StorageRecommendations.shared.openDeepLink(deepLink)
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.up.forward.app")
                                Text("Open Settings")
                            }
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(priorityColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var priorityColor: Color {
        switch recommendation.priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Compact Recommendations Widget (for Dashboard)

struct CompactRecommendationsWidget: View {
    let storageInfo: SystemInsights.StorageInfo?
    @State private var showingFullView = false

    private var topRecommendations: [StorageRecommendations.Recommendation] {
        StorageRecommendations.shared.getTopRecommendations(count: 3, basedOn: storageInfo)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.orange)
                Text("Storage Tips")
                    .font(.headline)
                Spacer()
                Button(action: { showingFullView = true }) {
                    Text("View All")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
            }

            VStack(spacing: 8) {
                ForEach(topRecommendations.prefix(3), id: \.type.rawValue) { recommendation in
                    HStack(spacing: 8) {
                        Image(systemName: recommendation.icon)
                            .font(.caption)
                            .foregroundColor(priorityColor(recommendation.priority))
                            .frame(width: 20)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(recommendation.title)
                                .font(.caption)
                                .fontWeight(.medium)
                            Text(recommendation.estimatedSavings)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if recommendation.priority == .high {
                            Image(systemName: "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.1))
        .cornerRadius(12)
        .sheet(isPresented: $showingFullView) {
            StorageRecommendationsView(storageInfo: storageInfo)
        }
    }

    private func priorityColor(_ priority: StorageRecommendations.Recommendation.Priority) -> Color {
        switch priority {
        case .high: return .red
        case .medium: return .orange
        case .low: return .blue
        }
    }
}

// MARK: - Preview

#Preview {
    StorageRecommendationsView(storageInfo: nil)
}

#Preview("Compact Widget") {
    CompactRecommendationsWidget(storageInfo: nil)
        .padding()
}
