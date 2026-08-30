import SwiftUI

// MARK: - Glass iconography
//
// The canvas draws every drink as a small tumbler whose fill height encodes
// strength: fill% = min(85, abv × 2.6 + 18).

enum GlassMath {
    static func fillFraction(abv: Double) -> Double {
        min(85, abv * 2.6 + 18) / 100
    }
}

/// Static tumbler with a translucent liquid level.
struct GlassIcon: View {
    @Environment(\.theme) private var theme
    var abv: Double
    var width: CGFloat = 30
    var height: CGFloat = 38
    var liquid: Color?

    private var shape: UnevenRoundedRectangle {
        let corner = width * 0.2
        return UnevenRoundedRectangle(
            topLeadingRadius: corner * 0.55,
            bottomLeadingRadius: corner,
            bottomTrailingRadius: corner,
            topTrailingRadius: corner * 0.55,
            style: .continuous
        )
    }

    var body: some View {
        shape
            .strokeBorder(theme.line, lineWidth: 2)
            .background(
                GeometryReader { geo in
                    Rectangle()
                        .fill((liquid ?? theme.accent).opacity(0.55))
                        .frame(height: geo.size.height * GlassMath.fillFraction(abv: abv))
                        .frame(maxHeight: .infinity, alignment: .bottom)
                }
                .clipShape(shape)
            )
            .frame(width: width, height: height)
            .accessibilityHidden(true)
    }
}

/// The large animated vessel used on empty states, the dry-day card, the
/// profile header and the units-info sheet: a glass outline containing a
/// slowly swirling liquid mass and drifting bubbles.
struct AnimatedGlass: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var width: CGFloat = 96
    var height: CGFloat = 128
    var liquid: Color?
    var outline: Color?
    /// Moss variant shows a success check bubble at the top-right.
    var showCheck = false

    @State private var breathe = false

    var body: some View {
        let tint = liquid ?? theme.accent
        ZStack(alignment: .topTrailing) {
            TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1 / 30, paused: reduceMotion)) { timeline in
                let t = timeline.date.timeIntervalSinceReferenceDate
                Canvas { context, size in
                    let w = size.width
                    let h = size.height

                    // Swirling liquid: two rotating rounded blobs, opposite spins.
                    func blob(alpha: Double, duration: Double, reverse: Bool, dx: CGFloat) {
                        let angle = reduceMotion ? 0 : (t / duration).truncatingRemainder(dividingBy: 1) * 2 * .pi * (reverse ? -1 : 1)
                        let blobSize = w * 2.4
                        var ctx = context
                        ctx.translateBy(x: w / 2 + dx, y: h * 0.78 + blobSize * 0.28)
                        ctx.rotate(by: .radians(angle))
                        let rect = CGRect(x: -blobSize / 2, y: -blobSize / 2, width: blobSize, height: blobSize)
                        ctx.fill(
                            Path(roundedRect: rect, cornerRadius: blobSize * 0.44),
                            with: .color(tint.opacity(alpha))
                        )
                    }
                    blob(alpha: 0.55, duration: 11, reverse: false, dx: 0)
                    blob(alpha: 0.28, duration: 14, reverse: true, dx: w * 0.06)

                    // Bubbles drifting upward.
                    func bubble(x: CGFloat, phase: Double, duration: Double, radius: CGFloat) {
                        let p = reduceMotion ? 0.4 : ((t + phase) / duration).truncatingRemainder(dividingBy: 1)
                        let y = (h - 14) - p * 46
                        let alpha = p < 0.15 ? p / 0.15 * 0.75 : (p > 0.85 ? (1 - p) / 0.15 * 0.75 : 0.75)
                        context.fill(
                            Path(ellipseIn: CGRect(x: w * x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                            with: .color(.white.opacity(alpha))
                        )
                    }
                    bubble(x: 0.32, phase: 0, duration: 5.4, radius: 2.5)
                    bubble(x: 0.58, phase: 1.6, duration: 6.8, radius: 2)
                    bubble(x: 0.45, phase: 3.1, duration: 7.6, radius: 1.5)
                }
            }
            .frame(width: width, height: height)
            .clipShape(vesselShape)
            .overlay(
                vesselShape.strokeBorder(outline ?? theme.text.opacity(0.22), lineWidth: 2.5)
            )

            if showCheck {
                Circle()
                    .fill(theme.b1)
                    .frame(width: 24, height: 24)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(.white)
                    )
                    .shadow(color: .black.opacity(0.15), radius: 4, y: 3)
                    .offset(x: 10, y: -6)
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .scaleEffect(breathe ? 1.03 : 1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 3.5).repeatForever(autoreverses: true)) { breathe = true }
        }
        .accessibilityHidden(true)
    }

    private var vesselShape: UnevenRoundedRectangle {
        UnevenRoundedRectangle(
            topLeadingRadius: width * 0.1,
            bottomLeadingRadius: width * 0.27,
            bottomTrailingRadius: width * 0.27,
            topTrailingRadius: width * 0.1,
            style: .continuous
        )
    }
}

/// The FAB's cocktail glass: bowl with a gently sloshing liquid line, fizz
/// bubbles, stem and foot — drawn in code, matching the canvas SVG.
struct CocktailGlyph: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        TimelineView(.animation(minimumInterval: reduceMotion ? 1 : 1 / 30, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let sx = size.width / 26
                let sy = size.height / 34
                let white = Color.white.opacity(0.95)

                var bowl = Path()
                bowl.move(to: CGPoint(x: 3.2 * sx, y: 1 * sy))
                bowl.addCurve(
                    to: CGPoint(x: 13 * sx, y: 14.8 * sy),
                    control1: CGPoint(x: 3.2 * sx, y: 9.5 * sy),
                    control2: CGPoint(x: 6 * sx, y: 14.8 * sy)
                )
                bowl.addCurve(
                    to: CGPoint(x: 22.8 * sx, y: 1 * sy),
                    control1: CGPoint(x: 20 * sx, y: 14.8 * sy),
                    control2: CGPoint(x: 22.8 * sx, y: 9.5 * sy)
                )
                var closedBowl = bowl
                closedBowl.addLine(to: CGPoint(x: 3.2 * sx, y: 1 * sy))
                closedBowl.closeSubpath()

                // Liquid, clipped to the bowl, level bobbing gently.
                var liquidCtx = context
                liquidCtx.clip(to: closedBowl)
                let bob = reduceMotion ? 0 : sin(t * 2 * .pi / 3) * 1.2
                let level = (7.5 + bob) * sy
                var liquid = Path()
                liquid.move(to: CGPoint(x: 0, y: level))
                liquid.addCurve(
                    to: CGPoint(x: 13 * sx, y: level + 0.3 * sy),
                    control1: CGPoint(x: 4.5 * sx, y: level - 1.5 * sy),
                    control2: CGPoint(x: 8.5 * sx, y: level + 1.2 * sy)
                )
                liquid.addCurve(
                    to: CGPoint(x: 26 * sx, y: level),
                    control1: CGPoint(x: 17.5 * sx, y: level - 1.1 * sy),
                    control2: CGPoint(x: 21.5 * sx, y: level + 1.1 * sy)
                )
                liquid.addLine(to: CGPoint(x: 26 * sx, y: 16 * sy))
                liquid.addLine(to: CGPoint(x: 0, y: 16 * sy))
                liquid.closeSubpath()
                liquidCtx.fill(liquid, with: .color(.white.opacity(0.9)))

                // Fizz bubbles rising inside the bowl.
                func fizz(x: CGFloat, phase: Double, duration: Double, radius: CGFloat) {
                    let p = reduceMotion ? 0.5 : ((t + phase) / duration).truncatingRemainder(dividingBy: 1)
                    let y = (13 - p * 9) * sy
                    let alpha = p < 0.25 ? p / 0.25 * 0.95 : (1 - p) * 0.95
                    liquidCtx.fill(
                        Path(ellipseIn: CGRect(x: x * sx - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                        with: .color(.white.opacity(alpha))
                    )
                }
                fizz(x: 9, phase: 0, duration: 2.2, radius: 1.1)
                fizz(x: 13.5, phase: 0.9, duration: 2.8, radius: 0.9)
                fizz(x: 17, phase: 1.7, duration: 2.5, radius: 0.9)

                // Outline, stem, foot.
                context.stroke(bowl, with: .color(white), style: StrokeStyle(lineWidth: 2, lineCap: .round))
                context.fill(
                    Path(roundedRect: CGRect(x: 12 * sx, y: 14.5 * sy, width: 2 * sx, height: 12.5 * sy), cornerRadius: sx),
                    with: .color(white)
                )
                context.fill(
                    Path(ellipseIn: CGRect(x: 6 * sx, y: 29.6 * sy, width: 14 * sx, height: 3.4 * sy)),
                    with: .color(white)
                )
            }
        }
        .accessibilityHidden(true)
    }
}
