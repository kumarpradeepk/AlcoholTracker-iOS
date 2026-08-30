import SwiftUI

// MARK: - Bar chart (units / spending)

struct BarChart: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let buckets: [StatsBucket]
    /// Colors a bar amber when its day exceeded the daily goal (P1: the
    /// over-limit case is drawn, not just described).
    var useOverColor = true
    var valueOf: (StatsBucket) -> Double
    var height: CGFloat = 132
    /// Dashed daily-average rule, as a fraction of the max (nil = hidden).
    var averageFraction: Double?

    @State private var grown = false

    private var maxValue: Double {
        max(0.1, buckets.map(valueOf).max() ?? 0.1)
    }

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .bottom) {
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(buckets) { b in
                        let fraction = max(0.02, valueOf(b) / maxValue)
                        UnevenRoundedRectangle(
                            topLeadingRadius: 3, bottomLeadingRadius: 2,
                            bottomTrailingRadius: 2, topTrailingRadius: 3
                        )
                        .fill(useOverColor && b.overDaily ? theme.b2 : theme.accent)
                        .frame(height: grown ? height * fraction : 2)
                        .frame(maxWidth: .infinity)
                        .animation(
                            Motion.reduced(reduceMotion, Motion.bars.delay(Double(b.id) * 0.024)),
                            value: grown
                        )
                    }
                }
                .frame(height: height, alignment: .bottom)

                if let averageFraction {
                    Line()
                        .stroke(theme.faint, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4]))
                        .frame(height: 1.5)
                        .offset(y: -height * min(0.96, averageFraction))
                        .transition(.opacity)
                }
            }

            if buckets.contains(where: { !$0.label.isEmpty }) {
                HStack(spacing: 3) {
                    ForEach(buckets) { b in
                        Text(b.label)
                            .font(theme.fonts.body(9))
                            .foregroundStyle(theme.faint)
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .onAppear { grown = true }
        .onChange(of: buckets.count) { grown = true }
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return p
    }
}

// MARK: - BAC trend line (7-day peaks)

struct TrendLineChart: View {
    @Environment(\.theme) private var theme
    let values: [Double]
    var height: CGFloat = 120

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let maxV = max(0.04, values.max() ?? 0.04)
            let points = values.enumerated().map { i, v in
                CGPoint(
                    x: values.count > 1 ? CGFloat(i) / CGFloat(values.count - 1) * (w - 12) + 6 : w / 2,
                    y: height - 14 - CGFloat(v / maxV) * (height - 28)
                )
            }

            ZStack {
                // Gradient fill under the curve.
                Path { p in
                    guard let first = points.first, let last = points.last else { return }
                    p.move(to: CGPoint(x: first.x, y: height))
                    for pt in points { p.addLine(to: pt) }
                    p.addLine(to: CGPoint(x: last.x, y: height))
                    p.closeSubpath()
                }
                .fill(theme.accent.opacity(0.18))

                Path { p in
                    guard let first = points.first else { return }
                    p.move(to: first)
                    for pt in points.dropFirst() { p.addLine(to: pt) }
                }
                .stroke(theme.accent, style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            }
        }
        .frame(height: height)
    }
}

// MARK: - Skeleton shimmer (loading states)

struct SkeletonCard: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var height: CGFloat
    var delay: Double = 0
    @State private var phase: CGFloat = -1.6

    var body: some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(theme.surface2)
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, theme.surface.opacity(0.9), .clear],
                        startPoint: .leading, endPoint: .trailing
                    )
                    .frame(width: geo.size.width * 0.6)
                    .offset(x: phase * geo.size.width)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            )
            .frame(height: height)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.4).repeatForever(autoreverses: false).delay(delay)) {
                    phase = 1.6
                }
            }
    }
}
