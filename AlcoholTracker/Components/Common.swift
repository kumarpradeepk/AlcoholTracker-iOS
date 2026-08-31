import SwiftUI

// MARK: - Buttons

/// Full-width tide pill CTA (54pt) with soft colored shadow.
struct PrimaryButton: View {
    @Environment(\.theme) private var theme
    let title: String
    var enabled = true
    var height: CGFloat = 54
    let action: () -> Void

    var body: some View {
        Button {
            guard enabled else { return }
            action()
        } label: {
            Text(title)
                .font(Fonts.text(height >= 54 ? 17 : 16.5, .semibold))
                .foregroundStyle(theme.onAcc)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(
                    RoundedRectangle(cornerRadius: Radii.banner, style: .continuous)
                        .fill(theme.acc)
                        .shadow(color: theme.acc.opacity(0.35), radius: 10, y: 8)
                )
                .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(PressScale(scale: 0.965))
        .animation(Motion.fade, value: enabled)
    }
}

/// Soft tinted secondary pill (e.g. "Mark a Dry Day", "Set Up BAC Profile").
struct SoftButton: View {
    let title: String
    var background: Color
    var foreground: Color
    var height: CGFloat = 50
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Fonts.text(16, .semibold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(RoundedRectangle(cornerRadius: Radii.tile, style: .continuous).fill(background))
        }
        .buttonStyle(PressScale(scale: 0.965))
    }
}

/// Small circular icon button (36pt) used for day navigation / close / back.
struct CircleIconButton: View {
    @Environment(\.theme) private var theme
    var systemName: String
    var size: CGFloat = 36
    var onCard2 = false
    var dimmed = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.34, weight: .semibold))
                .foregroundStyle(theme.sub)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(onCard2 ? theme.elev : theme.card)
                        .shadow(color: .black.opacity(onCard2 ? 0 : 0.05), radius: 4, y: 2)
                )
                .opacity(dimmed ? 0.3 : 1)
        }
        .buttonStyle(PressScale(scale: 0.88))
    }
}

// MARK: - Segmented pill (card2 track, card thumb + shadow)

struct SegmentedPill<T: Hashable>: View {
    @Environment(\.theme) private var theme
    let options: [(T, String)]
    @Binding var selection: T
    var fontSize: CGFloat = 14.5

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.0) { value, label in
                Button {
                    Haptics.selection()
                    withAnimation(Motion.fade) { selection = value }
                } label: {
                    Text(label)
                        .font(Fonts.text(fontSize, .semibold))
                        .foregroundStyle(selection == value ? theme.ink : theme.sub)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            Group {
                                if selection == value {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(theme.card)
                                        .shadow(color: .black.opacity(0.12), radius: 2, y: 1)
                                }
                            }
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(2)
        .background(RoundedRectangle(cornerRadius: Radii.tile, style: .continuous).fill(theme.elev))
    }
}

// MARK: - Circular stepper row (− value +)

struct StepperRow: View {
    @Environment(\.theme) private var theme
    let display: String
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        HStack {
            stepButton("minus", decrement)
            Spacer()
            Text(display)
                .font(Fonts.figure(30))
                .monospacedDigit()
                .contentTransition(.numericText())
            Spacer()
            stepButton("plus", increment)
        }
    }

    private func stepButton(_ icon: String, _ action: @escaping () -> Void) -> some View {
        Button {
            Haptics.light()
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(theme.sub)
                .frame(width: 44, height: 44)
                .background(Circle().fill(theme.elev))
        }
        .buttonStyle(PressScale(scale: 0.86))
    }
}

// MARK: - Chips

struct ValueChip: View {
    @Environment(\.theme) private var theme
    let text: String
    var selected = false
    let action: () -> Void

    var body: some View {
        Button {
            Haptics.selection()
            action()
        } label: {
            Text(text)
                .font(Fonts.text(13.5, .semibold))
                .foregroundStyle(selected ? theme.onAcc : theme.sub)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(
                    RoundedRectangle(cornerRadius: Radii.tile, style: .continuous)
                        .fill(selected ? theme.acc : theme.elev)
                )
        }
        .buttonStyle(PressScale(scale: 0.92))
    }
}

// MARK: - Custom toggle (50×30, matches the canvas)

struct AppToggle: View {
    @Environment(\.theme) private var theme
    @Binding var isOn: Bool
    var onTap: (() -> Void)?

    var body: some View {
        Button {
            if let onTap {
                onTap()
            } else {
                isOn.toggle()
            }
            Haptics.selection()
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? theme.acc : theme.elev)
                    .frame(width: 50, height: 30)
                Circle()
                    .fill(isOn ? theme.onAcc : theme.card)
                    .shadow(color: .black.opacity(0.2), radius: 3, y: 2)
                    .frame(width: 26, height: 26)
                    .padding(2)
            }
            .animation(Motion.pop, value: isOn)
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(L.s(isOn ? "a11y_toggle_on" : "a11y_toggle_off"))
    }
}

// MARK: - Progress ring

struct ProgressRing: View {
    @Environment(\.theme) private var theme
    /// 0…1 fraction of the ring to fill.
    var progress: Double
    var color: Color
    var lineWidth: CGFloat = 10
    var size: CGFloat = 116

    var body: some View {
        ZStack {
            Circle()
                .stroke(theme.elev, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(1, max(0, progress)))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(Motion.count, value: progress)
                .animation(.easeInOut(duration: 0.5), value: color)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Thin horizontal progress bar

struct ThinBar: View {
    @Environment(\.theme) private var theme
    var fraction: Double
    var color: Color

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(theme.elev)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, geo.size.width * min(1, fraction)))
                    .animation(Motion.count, value: fraction)
            }
        }
        .frame(height: 6)
    }
}

// MARK: - Animated numeric text

struct CountingText: View {
    let value: Double
    var format: (Double) -> String
    var font: Font

    var body: some View {
        Text(format(value))
            .font(font)
            .monospacedDigit()
            .contentTransition(.numericText(value: value))
            .animation(Motion.count, value: value)
    }
}

// MARK: - PRO badge

struct ProBadge: View {
    @Environment(\.theme) private var theme
    var action: (() -> Void)?

    var body: some View {
        Text(L.s("badge_pro"))
            .font(Fonts.text(10.5, .bold))
            .kerning(0.5)
            .foregroundStyle(theme.acc)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: Radii.tile, style: .continuous).fill(theme.elev))
            .onTapGesture { action?() }
    }
}

// MARK: - Settings list row

struct SettingsRow<Trailing: View>: View {
    @Environment(\.theme) private var theme
    let iconTint: Color
    let iconBackground: Color
    let iconSystemName: String
    let title: String
    var subtitle: String?
    var showChevron = false
    var showDivider = true
    var action: (() -> Void)?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(iconBackground)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: iconSystemName)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(iconTint)
                    )
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(Fonts.text(15.5))
                        .foregroundStyle(theme.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(Fonts.text(12.5))
                            .foregroundStyle(theme.sub)
                    }
                }
                Spacer(minLength: 8)
                trailing
                if showChevron { ChevronRight() }
            }
            .padding(.horizontal, 16)
            .frame(minHeight: subtitle == nil ? 52 : 56)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .overlay(alignment: .bottom) {
            if showDivider {
                Rectangle().fill(theme.line).frame(height: 0.5).padding(.leading, 56)
            }
        }
    }
}

/// Grouped card wrapping a stack of SettingsRows.
struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .clipShape(RoundedRectangle(cornerRadius: Radii.card, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radii.card, style: .continuous)
                    .strokeBorder(theme.line, lineWidth: 1)
            )
            .card(radius: 20)
    }
}
