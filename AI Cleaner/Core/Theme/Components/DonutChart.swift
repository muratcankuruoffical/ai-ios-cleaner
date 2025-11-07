//
//  DonutChart.swift
//  AI Cleaner
//
//  Animated donut chart for displaying storage metrics
//

import SwiftUI

struct DonutChart: View {
    let value: Double // 0.0 to 1.0
    let total: String
    let used: String
    let title: String
    let lineWidth: CGFloat
    let size: CGFloat

    @State private var animatedValue: Double = 0

    init(
        value: Double,
        total: String,
        used: String,
        title: String,
        lineWidth: CGFloat = 20,
        size: CGFloat = 200
    ) {
        self.value = value
        self.total = total
        self.used = used
        self.title = title
        self.lineWidth = lineWidth
        self.size = size
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(
                    CleanerTheme.surface,
                    lineWidth: lineWidth
                )

            // Progress circle with gradient
            Circle()
                .trim(from: 0, to: animatedValue)
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: [
                            CleanerTheme.primary,
                            CleanerTheme.accent,
                            CleanerTheme.primary
                        ]),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 1.0, dampingFraction: 0.7), value: animatedValue)

            // Center content
            VStack(spacing: 8) {
                Text(used)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(CleanerTheme.textPrimary)

                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(CleanerTheme.textSecondary)

                Text("of \(total)")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(CleanerTheme.textTertiary)
            }
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 1.5, dampingFraction: 0.6).delay(0.2)) {
                animatedValue = value
            }
        }
    }
}

// MARK: - Mini Donut Chart

struct MiniDonutChart: View {
    let value: Double
    let color: Color
    let size: CGFloat

    @State private var animatedValue: Double = 0

    init(value: Double, color: Color, size: CGFloat = 60) {
        self.value = value
        self.color = color
        self.size = size
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    CleanerTheme.surface,
                    lineWidth: 6
                )

            Circle()
                .trim(from: 0, to: animatedValue)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: 6,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))

            Text("\(Int(value * 100))%")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(CleanerTheme.textPrimary)
        }
        .frame(width: size, height: size)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.1)) {
                animatedValue = value
            }
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        CleanerTheme.background.ignoresSafeArea()

        VStack(spacing: 40) {
            DonutChart(
                value: 0.65,
                total: "64 GB",
                used: "42 GB",
                title: "Used"
            )

            HStack(spacing: 20) {
                MiniDonutChart(value: 0.75, color: CleanerTheme.primary)
                MiniDonutChart(value: 0.45, color: CleanerTheme.accentGreen)
                MiniDonutChart(value: 0.90, color: CleanerTheme.accentRed)
            }
        }
    }
}
