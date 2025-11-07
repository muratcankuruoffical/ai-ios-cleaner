//
//  SwipeDeckView.swift
//  AI Cleaner
//
//  Tinder-like swipe interface for reviewing and deleting photos - Dark Theme
//

import SwiftUI
import Photos
internal import Combine

struct SwipeDeckView: View {
    @StateObject private var viewModel: SwipeDeckViewModel
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var scanCoordinator: ScanCoordinator

    init(assets: [PHAsset], category: String) {
        _viewModel = StateObject(wrappedValue: SwipeDeckViewModel(assets: assets, category: category))
    }

    var body: some View {
        ZStack {
            // Dark Background
            CleanerTheme.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                headerView

                // Main Card Stack
                if viewModel.hasMoreCards {
                    ZStack {
                        // Stack of cards (show top 3)
                        ForEach(Array(viewModel.remainingCards.prefix(3).enumerated()), id: \.element) { index, asset in
                            SwipeCardView(
                                asset: asset,
                                index: index,
                                isTop: index == 0,
                                onSwipe: { direction in
                                    viewModel.handleSwipe(direction: direction)
                                }
                            )
                            .offset(y: CGFloat(index * 8))
                            .scaleEffect(1.0 - CGFloat(index) * 0.05)
                            .zIndex(Double(viewModel.remainingCards.count - index))
                        }
                    }
                    .padding()
                } else {
                    completionView
                }

                // Action Buttons
                actionButtonsView
            }
        }
        .navigationTitle("Review Photos")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
        .alert("Delete Photos?", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete \(viewModel.toDelete.count)", role: .destructive) {
                Task {
                    await viewModel.performDeletion(scanCoordinator: scanCoordinator)
                }
            }
        } message: {
            Text("This will delete \(viewModel.toDelete.count) photos. They will be moved to Recently Deleted.")
        }
        .alert("Error", isPresented: $viewModel.showingError) {
            Button("OK") { }
        } message: {
            if let error = viewModel.lastError {
                Text(error.localizedDescription)
            }
        }
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(viewModel.currentIndex + 1) / \(viewModel.totalCards)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)
                Text("Swipe to review")
                    .cleanerFont(.caption)
            }

            Spacer()

            HStack(spacing: 12) {
                StatBadge(
                    icon: "checkmark.circle.fill",
                    count: viewModel.toKeep.count,
                    color: CleanerTheme.accentGreen
                )

                StatBadge(
                    icon: "trash.circle.fill",
                    count: viewModel.toDelete.count,
                    color: CleanerTheme.accentRed
                )
            }
        }
        .padding()
        .background(CleanerTheme.surface)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(CleanerTheme.accentGreen.opacity(0.2))
                    .frame(width: 120, height: 120)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(CleanerTheme.accentGreen)
            }

            VStack(spacing: 12) {
                Text("Review Complete!")
                    .cleanerFont(.title)

                Text("Kept: \(viewModel.toKeep.count) • To Delete: \(viewModel.toDelete.count)")
                    .cleanerFont(.body)
            }

            VStack(spacing: 12) {
                if !viewModel.toDelete.isEmpty {
                    Button(action: {
                        viewModel.showingDeleteConfirmation = true
                    }) {
                        Text("Delete Selected Photos")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: 300)
                            .padding(.vertical, 16)
                            .background(CleanerTheme.accentRed)
                            .cornerRadius(16)
                    }
                }

                Button(action: {
                    dismiss()
                }) {
                    Text("Done")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: 300)
                        .padding(.vertical, 16)
                        .background(
                            LinearGradient(
                                colors: [CleanerTheme.primary, Color(hex: "#0066DD")],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(16)
                }
            }
        }
        .padding()
    }

    // MARK: - Action Buttons

    private var actionButtonsView: some View {
        HStack(spacing: 24) {
            // Keep Button
            Button(action: {
                viewModel.handleSwipe(direction: .left)
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 32))
                    Text("Keep")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(CleanerTheme.accentGreen)
                .frame(width: 80, height: 80)
                .background(CleanerTheme.accentGreen.opacity(0.15))
                .cornerRadius(40)
            }

            Spacer()

            // Undo Button
            Button(action: {
                viewModel.undo()
            }) {
                ZStack {
                    Circle()
                        .fill(CleanerTheme.surface)
                        .frame(width: 56, height: 56)

                    Image(systemName: "arrow.uturn.backward.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(viewModel.swipeHistory.isEmpty ? CleanerTheme.iconPrimary.opacity(0.5) : CleanerTheme.iconActive)
                }
            }
            .disabled(viewModel.swipeHistory.isEmpty)

            Spacer()

            // Delete Button
            Button(action: {
                viewModel.handleSwipe(direction: .right)
            }) {
                VStack(spacing: 8) {
                    Image(systemName: "trash.circle.fill")
                        .font(.system(size: 32))
                    Text("Delete")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundColor(CleanerTheme.accentRed)
                .frame(width: 80, height: 80)
                .background(CleanerTheme.accentRed.opacity(0.15))
                .cornerRadius(40)
            }
        }
        .padding()
        .padding(.bottom, 8)
        .background(CleanerTheme.surface)
        .disabled(!viewModel.hasMoreCards)
    }
}

// MARK: - Swipe Card (Dark Theme)

struct SwipeCardView: View {
    let asset: PHAsset
    let index: Int
    let isTop: Bool
    let onSwipe: (SwipeDirection) -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var image: UIImage?

    private let swipeThreshold: CGFloat = 80
    private let velocityThreshold: CGFloat = 1000

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Card Background
            RoundedRectangle(cornerRadius: 20)
                .fill(CleanerTheme.surface)
                .shadow(color: Color.black.opacity(0.4), radius: 12, x: 0, y: 6)

            // Image
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .cornerRadius(20)
            } else {
                ZStack {
                    CleanerTheme.cardBackground
                        .cornerRadius(20)

                    ProgressView()
                        .tint(CleanerTheme.primary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Gradient Overlay
            LinearGradient(
                colors: [Color.clear, CleanerTheme.background.opacity(0.8)],
                startPoint: .center,
                endPoint: .bottom
            )
            .cornerRadius(20)

            // Swipe Indicators
            if isTop {
                swipeIndicators
            }

            // Info Overlay
            infoOverlay
        }
        .frame(maxWidth: .infinity)
        .frame(height: 500)
        .offset(x: offset.width, y: 0)
        .rotationEffect(.degrees(rotation))
        .gesture(
            isTop ? DragGesture()
                .onChanged { gesture in
                    offset = gesture.translation
                    rotation = Double(gesture.translation.width / 20)
                }
                .onEnded { gesture in
                    handleDragEnd(gesture)
                } : nil
        )
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: offset)
        .task {
            await loadImage()
        }
    }

    // MARK: - Swipe Indicators

    private var swipeIndicators: some View {
        ZStack {
            // Keep Indicator (Left)
            if offset.width < -50 {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(CleanerTheme.accentGreen.opacity(0.9))
                                .frame(width: 80, height: 80)

                            Image(systemName: "checkmark")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(32)
                    }
                    Spacer()
                }
                .opacity(min(Double(-offset.width / 100), 1.0))
            }

            // Delete Indicator (Right)
            if offset.width > 50 {
                VStack {
                    HStack {
                        ZStack {
                            Circle()
                                .fill(CleanerTheme.accentRed.opacity(0.9))
                                .frame(width: 80, height: 80)

                            Image(systemName: "trash")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(32)
                        Spacer()
                    }
                    Spacer()
                }
                .opacity(min(Double(offset.width / 100), 1.0))
            }
        }
    }

    // MARK: - Info Overlay

    private var infoOverlay: some View {
        VStack {
            Spacer()

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formatDate(asset.creationDate))
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white)

                    Text("\(asset.pixelWidth) × \(asset.pixelHeight)")
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding(12)
                .background(CleanerTheme.surface.opacity(0.8))
                .cornerRadius(12)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - Drag Handling

    private func handleDragEnd(_ gesture: DragGesture.Value) {
        let horizontalDistance = gesture.translation.width
        let predictedEnd = gesture.predictedEndTranslation.width

        // Calculate velocity from predicted end position
        let velocity = abs(predictedEnd - horizontalDistance)

        // Determine if swipe should trigger based on distance OR velocity
        let shouldTriggerLeft = horizontalDistance < -swipeThreshold ||
                                (horizontalDistance < -40 && velocity > velocityThreshold)
        let shouldTriggerRight = horizontalDistance > swipeThreshold ||
                                 (horizontalDistance > 40 && velocity > velocityThreshold)

        if shouldTriggerLeft {
            // Swipe left = Keep
            animateSwipe(direction: .left, velocity: velocity)
            onSwipe(.left)
        } else if shouldTriggerRight {
            // Swipe right = Delete
            animateSwipe(direction: .right, velocity: velocity)
            onSwipe(.right)
        } else {
            // Return to center with bounce
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                offset = .zero
                rotation = 0
            }
        }
    }

    private func animateSwipe(direction: SwipeDirection, velocity: CGFloat) {
        let distance: CGFloat = 500

        // Spring animation with overshoot for natural physics
        withAnimation(.spring(response: 0.35, dampingFraction: 0.7, blendDuration: 0.1)) {
            offset = direction == .left
                ? CGSize(width: -distance, height: 0)
                : CGSize(width: distance, height: 0)
            rotation = direction == .left ? -30 : 30
        }

        // Haptic feedback - vary intensity based on swipe velocity
        let isFastSwipe = velocity > velocityThreshold
        let impactFeedback = UIImpactFeedbackGenerator(style: isFastSwipe ? .heavy : .medium)
        impactFeedback.impactOccurred()
    }

    // MARK: - Image Loading

    private func loadImage() async {
        do {
            let loadedImage = try await PhotoLibraryService.shared.loadThumbnail(for: asset)
            await MainActor.run {
                image = loadedImage
            }
        } catch {
            // Silently fail - UI shows placeholder
        }
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date = date else { return "Unknown" }
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - View Model

@MainActor
class SwipeDeckViewModel: ObservableObject {
    @Published var remainingCards: [PHAsset]
    @Published var toKeep: [PHAsset] = []
    @Published var toDelete: [PHAsset] = []
    @Published var swipeHistory: [(asset: PHAsset, direction: SwipeDirection)] = []

    @Published var showingDeleteConfirmation = false
    @Published var showingError = false
    @Published var lastError: Error?

    let category: String
    let totalCards: Int

    var currentIndex: Int {
        totalCards - remainingCards.count
    }

    var hasMoreCards: Bool {
        !remainingCards.isEmpty
    }

    init(assets: [PHAsset], category: String) {
        self.remainingCards = assets
        self.category = category
        self.totalCards = assets.count
    }

    func handleSwipe(direction: SwipeDirection) {
        guard let asset = remainingCards.first else { return }

        swipeHistory.append((asset, direction))

        switch direction {
        case .left:
            toKeep.append(asset)
        case .right:
            toDelete.append(asset)
        }

        remainingCards.removeFirst()

        AnalyticsManager.shared.logItemSwiped(
            direction: direction == .left ? "keep" : "delete",
            category: category
        )
    }

    func undo() {
        guard let last = swipeHistory.popLast() else { return }

        remainingCards.insert(last.asset, at: 0)

        if last.direction == .left {
            toKeep.removeAll { $0 == last.asset }
        } else {
            toDelete.removeAll { $0 == last.asset }
        }
    }

    func performDeletion(scanCoordinator: ScanCoordinator?) async {
        print("🗑️ [SwipeDeck] Starting deletion - count: \(toDelete.count), category: \(category)")
        AnalyticsManager.shared.logCleanupStarted(itemCount: toDelete.count, category: category)

        do {
            try await PhotoLibraryService.shared.delete(assets: toDelete)
            print("🗑️ [SwipeDeck] Photos deleted successfully")

            // Calculate freed space (approximate)
            var freedBytes: Int64 = 0
            for asset in toDelete {
                freedBytes += await PhotoLibraryService.shared.getAssetSize(for: asset)
            }
            print("🗑️ [SwipeDeck] Freed bytes calculated: \(freedBytes)")

            AnalyticsManager.shared.logCleanupCompleted(
                itemCount: toDelete.count,
                category: category,
                bytesFreed: freedBytes
            )

            // Log activity to CoreData and update scan coordinator
            await MainActor.run {
                print("🗑️ [SwipeDeck] Creating ActivityLog on MainActor")
                let context = CoreDataStack.shared.viewContext
                ActivityLog.createDeleteActivity(
                    context: context,
                    count: toDelete.count,
                    freedBytes: freedBytes,
                    category: category,
                    timestamp: Date()
                )
                print("🗑️ [SwipeDeck] Saving context...")
                CoreDataStack.shared.save(context: context)
                print("🗑️ [SwipeDeck] Context saved successfully")

                // Update scan coordinator to track deleted assets
                if let coordinator = scanCoordinator {
                    coordinator.markAssetsAsDeleted(toDelete)
                }
            }

            toDelete.removeAll()
        } catch {
            print("❌ [SwipeDeck] Deletion error: \(error.localizedDescription)")
            lastError = error
            showingError = true
            AnalyticsManager.shared.logError(error, context: "deletion")
        }
    }
}

// MARK: - Enums

enum SwipeDirection {
    case left  // Keep
    case right // Delete
}

// MARK: - Stat Badge (Dark Theme)

struct StatBadge: View {
    let icon: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text("\(count)")
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.15))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SwipeDeckView(assets: [], category: "Duplicates")
    }
}
