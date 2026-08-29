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
                .font(.system(size: height >= 54 ? 17 : 16.5, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(
                    Capsule().fill(theme.tide)
                        .shadow(color: theme.tide.opacity(0.35), radius: 10, y: 8)
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(foreground)
                .frame(maxWidth: .infinity)
                .frame(height: height)
                .background(Capsule().fill(background))
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
                .foregroundStyle(theme.sec)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(onCard2 ? theme.card2 : theme.card)
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
                        .font(.system(size: fontSize, weight: .semibold))
                        .foregroundStyle(selection == value ? theme.ink : theme.sec)
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
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.card2))
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
                .font(.system(size: 30, weight: .bold))
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
                .foregroundStyle(theme.sec)
                .frame(width: 44, height: 44)
                .background(Circle().fill(theme.card2))
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
                .font(.system(size: 13.5, weight: .semibold))
                .foregroundStyle(selected ? .white : theme.sec)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Capsule().fill(selected ? theme.tide : theme.card2))
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
                    .fill(isOn ? theme.tide : theme.card2)
                    .frame(width: 50, height: 30)
                Circle()
                    .fill(.white)
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
                .stroke(theme.card2, lineWidth: lineWidth)
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
                Capsule().fill(theme.card2)
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
            .font(.system(size: 10.5, weight: .bold))
            .kerning(0.5)
            .foregroundStyle(theme.tide)
            .padding(.horizontal, 9)
            .padding(.vertical, 4)
            .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(theme.tideSoft))
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
                        .font(.system(size: 15.5))
                        .foregroundStyle(theme.ink)
                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 12.5))
                            .foregroundStyle(theme.sec)
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
                Rectangle().fill(theme.hair).frame(height: 0.5).padding(.leading, 56)
            }
        }
    }
}

/// Grouped card wrapping a stack of SettingsRows.
struct SettingsGroup<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(spacing: 0) { content }
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .card(radius: 20)
    }
}
