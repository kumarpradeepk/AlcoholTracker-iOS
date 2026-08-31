import SwiftUI

/// Builds a `Path` from the generated icon geometry.
///
/// The generator normalises every glyph to absolute `M / L / C / Z`, so this
/// reads four commands and needs no arc maths or general SVG parser. Anything
/// else in the data is a generator bug, not something to handle here.
struct IconShape: Shape {
    let spec: IconSpec

    func path(in rect: CGRect) -> Path {
        var path = Path()
        let k = min(rect.width, rect.height) / AppIcons.viewport
        for d in spec.paths {
            append(d, to: &path, scale: k)
        }
        return path
    }

    private func append(_ d: String, to path: inout Path, scale k: CGFloat) {
        var nums: [CGFloat] = []
        var cmd: Character = " "
        var i = d.startIndex

        func pt(_ a: Int) -> CGPoint { CGPoint(x: nums[a] * k, y: nums[a + 1] * k) }

        func flush() {
            switch cmd {
            case "M":
                if nums.count >= 2 { path.move(to: pt(0)) }
            case "L":
                if nums.count >= 2 { path.addLine(to: pt(0)) }
            case "C":
                if nums.count >= 6 {
                    path.addCurve(to: pt(4), control1: pt(0), control2: pt(2))
                }
            case "Z":
                path.closeSubpath()
            default:
                break
            }
            nums.removeAll(keepingCapacity: true)
        }

        while i < d.endIndex {
            let ch = d[i]
            if ch == "M" || ch == "L" || ch == "C" || ch == "Z" {
                flush()
                cmd = ch
                i = d.index(after: i)
                if ch == "Z" { flush() }
                continue
            }
            if ch == " " || ch == "," {
                i = d.index(after: i)
                continue
            }
            // A number: sign, digits, one dot.
            var j = i
            if d[j] == "-" { j = d.index(after: j) }
            while j < d.endIndex, d[j].isNumber || d[j] == "." { j = d.index(after: j) }
            nums.append(CGFloat(Double(d[i..<j]) ?? 0))
            i = j
        }
        flush()
    }
}

/// One of the canvas's line icons.
///
/// The set is drawn on a shared 24×24 grid with round caps and joins so the
/// icons read as one family; `IconSpec.strokeWidth` is the canvas's own weight
/// for that glyph and scales with the icon, which is what keeps a 16pt chevron
/// and a 42pt bottle looking like the same pen.
struct AppIcon: View {
    @Environment(\.theme) private var theme

    let spec: IconSpec
    var size: CGFloat = 18
    var tint: Color?
    var strokeWidth: CGFloat?
    /// How much of the stroke to reveal, for the `idraw` draw-on.
    var progress: CGFloat = 1

    var body: some View {
        let shape = IconShape(spec: spec)
        let colour = tint ?? theme.ink
        Group {
            if spec.filled {
                shape.fill(colour)
            } else {
                shape
                    .trim(from: 0, to: progress)
                    .stroke(
                        colour,
                        style: StrokeStyle(
                            lineWidth: (strokeWidth ?? spec.strokeWidth) * (size / AppIcons.viewport),
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}

/// The canvas's `animation:idraw .6s <delay> ease both` — the icon draws itself
/// in. Used where an icon arrives with its screen; a control the user is about
/// to press uses the static `AppIcon` so it is never half-drawn under a finger.
struct AnimatedAppIcon: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let spec: IconSpec
    var size: CGFloat = 18
    var tint: Color?
    var strokeWidth: CGFloat?
    var delay: Double = 0

    @State private var drawn = false

    var body: some View {
        AppIcon(
            spec: spec, size: size, tint: tint, strokeWidth: strokeWidth,
            progress: drawn || reduceMotion ? 1 : 0
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 0.6).delay(delay)) { drawn = true }
        }
    }
}
