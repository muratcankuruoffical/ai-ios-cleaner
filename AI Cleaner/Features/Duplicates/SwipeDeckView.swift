//
//  SwipeDeckView.swift
//  AI Cleaner
//
//  Tinder-like swipe interface for reviewing and deleting photos
//

import SwiftUI
import Photos

struct SwipeDeckView: View {
    @StateObject private var viewModel: SwipeDeckViewModel
    @Environment(\.dismiss) private var dismiss

    init(assets: [PHAsset], category: String) {
        _viewModel = StateObject(wrappedValue: SwipeDeckViewModel(assets: assets, category: category))
    }

    var body: some View {
        ZStack {
            Color.gray.opacity(0.1).ignoresSafeArea()

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
        .alert("Delete Photos?", isPresented: $viewModel.showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete \(viewModel.toDelete.count)", role: .destructive) {
                Task {
                    await viewModel.performDeletion()
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
                    .font(.headline)
                Text("Swipe to review")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            HStack(spacing: 16) {
                StatBadge(
                    icon: "checkmark.circle.fill",
                    count: viewModel.toKeep.count,
                    color: .green
                )

                StatBadge(
                    icon: "trash.circle.fill",
                    count: viewModel.toDelete.count,
                    color: .red
                )
            }
        }
        .padding()
        .background(Color.white)
    }

    // MARK: - Completion View

    private var completionView: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.green)

            VStack(spacing: 12) {
                Text("Review Complete!")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Kept: \(viewModel.toKeep.count) • To Delete: \(viewModel.toDelete.count)")
                    .font(.body)
                    .foregroundColor(.secondary)
            }

            if !viewModel.toDelete.isEmpty {
                Button(action: {
                    viewModel.showingDeleteConfirmation = true
                }) {
                    Text("Delete Selected Photos")
                        .fontWeight(.semibold)
                        .frame(maxWidth: 300)
                        .padding()
                        .background(Color.red)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }

            Button(action: {
                dismiss()
            }) {
                Text("Done")
                    .fontWeight(.semibold)
                    .frame(maxWidth: 300)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
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
                        .font(.caption)
                }
                .foregroundColor(.green)
                .frame(width: 80, height: 80)
                .background(Color.green.opacity(0.1))
                .cornerRadius(40)
            }

            Spacer()

            // Undo Button
            Button(action: {
                viewModel.undo()
            }) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.gray)
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
                        .font(.caption)
                }
                .foregroundColor(.red)
                .frame(width: 80, height: 80)
                .background(Color.red.opacity(0.1))
                .cornerRadius(40)
            }
        }
        .padding()
        .background(Color.white)
        .disabled(!viewModel.hasMoreCards)
    }
}

// MARK: - Swipe Card

struct SwipeCardView: View {
    let asset: PHAsset
    let index: Int
    let isTop: Bool
    let onSwipe: (SwipeDirection) -> Void

    @State private var offset: CGSize = .zero
    @State private var rotation: Double = 0
    @State private var image: UIImage?

    private let swipeThreshold: CGFloat = 80 // Lowered from 120 for better responsiveness
    private let velocityThreshold: CGFloat = 1000 // Fast swipe detection

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Card Background
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(radius: 8)

            // Image
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
                    .cornerRadius(20)
            } else {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

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
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.green)
                            .padding()
                    }
                    Spacer()
                }
                .opacity(min(Double(-offset.width / 100), 1.0))
            }

            // Delete Indicator (Right)
            if offset.width > 50 {
                VStack {
                    HStack {
                        Image(systemName: "trash.circle.fill")
                            .font(.system(size: 64))
                            .foregroundColor(.red)
                            .padding()
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
                        .font(.caption)
                        .foregroundColor(.white)

                    Text("\(asset.pixelWidth) × \(asset.pixelHeight)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.8))
                }
                .padding()
                .background(Color.black.opacity(0.6))
                .cornerRadius(8)

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
            print("Failed to load image: \(error)")
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

    func performDeletion() async {
        AnalyticsManager.shared.logCleanupStarted(itemCount: toDelete.count, category: category)

        do {
            try await PhotoLibraryService.shared.delete(assets: toDelete)

            // Calculate freed space (approximate)
            var freedBytes: Int64 = 0
            for asset in toDelete {
                freedBytes += await PhotoLibraryService.shared.getAssetSize(for: asset)
            }

            AnalyticsManager.shared.logCleanupCompleted(
                itemCount: toDelete.count,
                category: category,
                bytesFreed: freedBytes
            )

            toDelete.removeAll()
        } catch {
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

// MARK: - Stat Badge

struct StatBadge: View {
    let icon: String
    let count: Int
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            Text("\(count)")
                .font(.caption)
                .fontWeight(.semibold)
        }
        .foregroundColor(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(12)
    }
}

// MARK: - Preview

#Preview {
    NavigationView {
        SwipeDeckView(assets: [], category: "Duplicates")
    }
}
