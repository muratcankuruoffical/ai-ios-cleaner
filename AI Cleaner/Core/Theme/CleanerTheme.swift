//
//  CleanerTheme.swift
//  AI Cleaner
//
//  Dark theme design system for AI Cleaner
//

import SwiftUI

// MARK: - Color Theme

enum CleanerTheme {
    // MARK: - Primary Colors
    static let background = Color(hex: "#0F0D1C")
    static let surface = Color(hex: "#212126")
    static let cardBackground = Color(hex: "#1A1A24")

    // MARK: - Accent Colors
    static let primary = Color(hex: "#0077F9")
    static let accent = Color(hex: "#F9C200")
    static let accentGreen = Color(hex: "#5BAE1F")
    static let accentRed = Color(hex: "#DE4841")

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "#6677B1")
    static let textTertiary = Color(hex: "#595B72")

    // MARK: - Icon Color
    static let iconGray = Color(hex: "#9CA3AF")

    // MARK: - Gradient Colors
    static let primaryGradient = LinearGradient(
        colors: [primary, Color(hex: "#00A3FF")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [accent, Color(hex: "#FFD700")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let backgroundGradient = LinearGradient(
        colors: [background, surface],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Typography

enum CleanerFont {
    case largeTitle
    case title
    case title2
    case headline
    case subheadline
    case body
    case callout
    case caption
    case caption2

    var font: Font {
        switch self {
        case .largeTitle:
            return .system(size: 34, weight: .bold)
        case .title:
            return .system(size: 28, weight: .bold)
        case .title2:
            return .system(size: 22, weight: .bold)
        case .headline:
            return .system(size: 18, weight: .semibold)
        case .subheadline:
            return .system(size: 16, weight: .medium)
        case .body:
            return .system(size: 16, weight: .regular)
        case .callout:
            return .system(size: 14, weight: .medium)
        case .caption:
            return .system(size: 12, weight: .regular)
        case .caption2:
            return .system(size: 10, weight: .regular)
        }
    }
}

// MARK: - View Extensions

extension View {
    func cleanerFont(_ style: CleanerFont) -> some View {
        self.font(style.font)
    }

    func cleanerCard(cornerRadius: CGFloat = 20, shadowRadius: CGFloat = 8) -> some View {
        self
            .background(CleanerTheme.cardBackground)
            .cornerRadius(cornerRadius)
            .shadow(color: Color.black.opacity(0.3), radius: shadowRadius, x: 0, y: 4)
    }

    func cleanerButton(isSecondary: Bool = false) -> some View {
        self
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(isSecondary ? CleanerTheme.surface : CleanerTheme.primary)
            .cornerRadius(16)
    }

    func shimmerEffect() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Shimmer Animation

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                Rectangle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                .clear,
                                Color.white.opacity(0.1),
                                .clear
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(30))
                    .offset(x: phase)
            )
            .clipped()
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = 400
                }
            }
    }
}

// MARK: - Pulse Animation

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    let duration: Double

    init(duration: Double = 1.0) {
        self.duration = duration
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(
                    Animation.easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    func pulse(duration: Double = 1.0) -> some View {
        self.modifier(PulseModifier(duration: duration))
    }
}

// MARK: - Fade In Animation

struct FadeInModifier: ViewModifier {
    @State private var opacity: Double = 0
    let delay: Double

    init(delay: Double = 0) {
        self.delay = delay
    }

    func body(content: Content) -> some View {
        content
            .opacity(opacity)
            .onAppear {
                withAnimation(
                    Animation.easeOut(duration: 0.5)
                        .delay(delay)
                ) {
                    opacity = 1
                }
            }
    }
}

extension View {
    func fadeIn(delay: Double = 0) -> some View {
        self.modifier(FadeInModifier(delay: delay))
    }
}

// MARK: - Scale Animation

struct ScaleInModifier: ViewModifier {
    @State private var scale: CGFloat = 0.8
    let delay: Double

    init(delay: Double = 0) {
        self.delay = delay
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .onAppear {
                withAnimation(
                    Animation.spring(response: 0.6, dampingFraction: 0.7)
                        .delay(delay)
                ) {
                    scale = 1.0
                }
            }
    }
}

extension View {
    func scaleIn(delay: Double = 0) -> some View {
        self.modifier(ScaleInModifier(delay: delay))
    }
}
