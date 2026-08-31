import SwiftUI

// MARK: - Custom tab bar
//
// Three destinations with hand-drawn stroke icons whose strokes redraw when
// the tab becomes active (the canvas' kDraw + kTabPop pairing), over a glass
// blur with a hairline top border.

struct AppTabBar: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Binding var tab: MainTab
    var onChange: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            tabItem(.diary, label: MainTab.diary.shortLabel) { color, progress in
                DiaryGlyph(progress: progress).stroke(color, lineWidth: 2)
            }
            tabItem(.stats, label: MainTab.stats.shortLabel) { color, progress in
                StatsGlyph(progress: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 3, lineCap: .round))
            }
            tabItem(.settings, label: MainTab.settings.shortLabel) { color, progress in
                SettingsGlyph(progress: progress)
                    .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(
            theme.card
                .background(.ultraThinMaterial)
                .overlay(alignment: .top) { Rectangle().fill(theme.line).frame(height: 0.5) }
                .ignoresSafeArea(edges: .bottom)
        )
    }

    @ViewBuilder
    private func tabItem<S: View>(
        _ value: MainTab,
        label: String,
        @ViewBuilder glyph: @escaping (Color, CGFloat) -> S
    ) -> some View {
        let active = tab == value
        Button {
            guard tab != value else { return }
            Haptics.selection()
            withAnimation(Motion.fade) { tab = value }
            onChange()
        } label: {
            VStack(spacing: 4) {
                TabGlyphAnimator(active: active, reduceMotion: reduceMotion) { progress in
                    glyph(active ? theme.acc : theme.sub, progress)
                }
                .frame(width: 22, height: 19)
                Text(label)
                    .font(Fonts.text(10.5, .semibold))
                    .foregroundStyle(active ? theme.acc : theme.sub)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(PressScale(scale: 0.92))
        .accessibilityLabel(label)
        .accessibilityAddTraits(active ? [.isSelected] : [])
    }
}

/// Drives stroke-draw progress (0→1) plus a small pop when a tab activates.
private struct TabGlyphAnimator<Content: View>: View {
    let active: Bool
    let reduceMotion: Bool
    @ViewBuilder var content: (CGFloat) -> Content

    @State private var progress: CGFloat = 1
    @State private var pop = false

    var body: some View {
        content(progress)
            .scaleEffect(pop ? 1.18 : 1)
            .onChange(of: active) { _, isActive in
                guard isActive, !reduceMotion else { return }
                progress = 0
                withAnimation(.timingCurve(0.4, 0, 0.2, 1, duration: 0.55)) { progress = 1 }
                withAnimation(Motion.pop) { pop = true }
                Task {
                    try? await Task.sleep(for: .milliseconds(220))
                    withAnimation(Motion.pop) { pop = false }
                }
            }
    }
}

// MARK: Glyph shapes (22×19 design space), trimmed for the draw-in effect

private struct DiaryGlyph: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 22
        let sy = rect.height / 19
        var p = Path()
        p.addRoundedRect(
            in: CGRect(x: 2 * sx, y: 1.5 * sy, width: 18 * sx, height: 16 * sy),
            cornerSize: CGSize(width: 4 * sx, height: 4 * sx)
        )
        p.move(to: CGPoint(x: 11 * sx, y: 1.5 * sy))
        p.addLine(to: CGPoint(x: 11 * sx, y: 17.5 * sy))
        return p.trimmedPath(from: 0, to: progress)
    }
}

private struct StatsGlyph: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 22
        let sy = rect.height / 19
        var p = Path()
        p.move(to: CGPoint(x: 5 * sx, y: 17 * sy))
        p.addLine(to: CGPoint(x: 5 * sx, y: 11 * sy))
        p.move(to: CGPoint(x: 11 * sx, y: 17 * sy))
        p.addLine(to: CGPoint(x: 11 * sx, y: 2 * sy))
        p.move(to: CGPoint(x: 17 * sx, y: 17 * sy))
        p.addLine(to: CGPoint(x: 17 * sx, y: 8 * sy))
        return p.trimmedPath(from: 0, to: progress)
    }
}

private struct SettingsGlyph: Shape {
    var progress: CGFloat
    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let sx = rect.width / 22
        let sy = rect.height / 19
        var p = Path()
        p.move(to: CGPoint(x: 2 * sx, y: 6 * sy))
        p.addLine(to: CGPoint(x: 20 * sx, y: 6 * sy))
        p.addEllipse(in: CGRect(x: 5 * sx, y: 3 * sy, width: 6 * sx, height: 6 * sy))
        p.move(to: CGPoint(x: 2 * sx, y: 13 * sy))
        p.addLine(to: CGPoint(x: 20 * sx, y: 13 * sy))
        p.addEllipse(in: CGRect(x: 11 * sx, y: 10 * sy, width: 6 * sx, height: 6 * sy))
        return p.trimmedPath(from: 0, to: progress)
    }
}

// MARK: - FAB with expanding actions

struct DiaryFab: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .trailing, spacing: 10) {
            fabAction(L.s("action_dry_day"), color: theme.moss, delay: 0.05) {
                model.fabOpen = false
                model.markDry(key: model.selectedKey)
            }
            fabAction(L.s("action_log_drink"), color: theme.acc, delay: 0) {
                model.fabOpen = false
                model.openSheet(.log)
            }

            Button {
                Haptics.medium()
                withAnimation(Motion.pop) { model.fabOpen.toggle() }
            } label: {
                Circle()
                    .fill(theme.acc)
                    .frame(width: 58, height: 58)
                    .overlay(
                        CocktailGlyph()
                            .frame(width: 26, height: 34)
                            .rotationEffect(.degrees(model.fabOpen ? -22 : 0))
                            .scaleEffect(model.fabOpen ? 1.08 : 1)
                    )
                    .shadow(color: .black.opacity(0.18), radius: 9, y: 6)
            }
            .buttonStyle(PressScale(scale: 0.9))
            .accessibilityLabel(L.s(model.fabOpen ? "a11y_fab_close" : "a11y_fab_add"))
            .accessibilityHint(L.s("a11y_fab_hint"))
        }
    }

    private func fabAction(_ title: String, color: Color, delay: Double, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Fonts.text(14.5, .semibold))
                .foregroundStyle(color)
                .padding(.horizontal, 18)
                .frame(height: 42)
                .background(
                    Capsule()
                        .fill(theme.card)
                        .shadow(color: .black.opacity(0.14), radius: 12, y: 8)
                )
        }
        .buttonStyle(PressScale())
        .opacity(model.fabOpen ? 1 : 0)
        .offset(y: model.fabOpen ? 0 : 16)
        .allowsHitTesting(model.fabOpen)
        .animation(Motion.pop.delay(model.fabOpen ? delay : 0), value: model.fabOpen)
    }
}
