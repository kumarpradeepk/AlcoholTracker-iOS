import SwiftUI

// MARK: - Onboarding
//
// Three screens, all skippable, no account, no quiz-then-paywall. The user
// can log a drink before we ask for anything (brief P7/§9).

struct WelcomeView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 0) {
                DropletMark(size: 54)
                    .padding(.bottom, 32)

                Text(L.s("ob_welcome_title"))
                    .font(theme.fonts.display(30))
                    .kerning(-0.4)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text(L.s("ob_welcome_sub"))
                    .font(theme.fonts.body(17))
                    .foregroundStyle(theme.muted)
                    .padding(.top, 10)

                Text(L.s("ob_welcome_body"))
                    .font(theme.fonts.body(15))
                    .foregroundStyle(theme.muted)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .frame(maxWidth: 290)
                    .padding(.top, 18)

                watchPreviewCard
                    .padding(.top, 34)
                    .riseIn(delay: 0.25)
            }

            Spacer()

            HStack(spacing: 6) {
                Capsule().fill(theme.accent).frame(width: 20, height: 6)
                Circle().fill(theme.line).frame(width: 6, height: 6)
                Circle().fill(theme.line).frame(width: 6, height: 6)
            }
            .padding(.bottom, 18)

            PrimaryButton(title: L.s("ob_get_started")) {
                withAnimation(Motion.rise) { model.phase = .goals }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 24)
        .riseIn()
    }

    private var watchPreviewCard: some View {
        HStack(spacing: 14) {
            // Miniature watch face with two quick-log pills.
            VStack(spacing: 5) {
                watchPill("Beer", tint: DrinkTints.beer, bg: DrinkTints.beer.opacity(0.25))
                watchPill("Wine", tint: DrinkTints.wine, bg: DrinkTints.wine.opacity(0.28))
            }
            .frame(width: 64, height: 78)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color(hex: 0x101012))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color(hex: 0x2E2E33), lineWidth: 3)
                    )
            )

            VStack(alignment: .leading, spacing: 3) {
                Text(L.s("ob_welcome_quick_caption"))
                    .font(theme.fonts.body(13, .semibold))
                Text(L.s("ob_welcome_bac_example"))
                    .font(theme.fonts.body(12))
                    .foregroundStyle(theme.muted)
                Text(L.s("ob_welcome_sober_example"))
                    .font(theme.fonts.body(12))
                    .foregroundStyle(theme.b1)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(theme.surface)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 6)
        )
    }

    private func watchPill(_ label: String, tint: Color, bg: Color) -> some View {
        Text(label)
            .font(theme.fonts.body(8, .semibold))
            .foregroundStyle(tint)
            .frame(width: 44, height: 20)
            .background(Capsule().fill(bg))
    }
}

// MARK: - Step 2: intentions

struct GoalsView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    private var count: Int { settings.selectedGoals.count }

    /// The seven intentions, in the order their indices are persisted in
    /// `selectedGoals`. The order must never change — the selection is stored
    /// by index, not by text.
    private var goals: [String] {
        [
            L.s("ob_goal_less"),
            L.s("ob_goal_awareness"),
            L.s("ob_goal_break"),
            L.s("ob_goal_free_days"),
            L.s("ob_goal_conscious"),
            L.s("ob_goal_reset"),
            L.s("ob_goal_social"),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingHeader(step: 2, onBack: {
                withAnimation(Motion.rise) { model.phase = .welcome }
            }, onSkip: skip)

            Text(L.s("ob_goals_title"))
                .font(theme.fonts.display(27))
                .kerning(-0.4)
                .padding(.top, 6)
            Text(L.s("ob_goals_sub"))
                .font(theme.fonts.body(15))
                .foregroundStyle(theme.muted)
                .lineSpacing(2)
                .padding(.top, 6)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(goals.enumerated()), id: \.offset) { i, title in
                        SelectableRow(
                            title: title,
                            selected: settings.selectedGoals.contains(i),
                            checkStyle: .check
                        ) {
                            Haptics.selection()
                            withAnimation(Motion.fade) {
                                if let idx = settings.selectedGoals.firstIndex(of: i) {
                                    settings.selectedGoals.remove(at: idx)
                                } else {
                                    settings.selectedGoals.append(i)
                                }
                            }
                        }
                        .riseIn(delay: Double(i) * 0.038)
                    }
                }
                .padding(.top, 18)
                .padding(.bottom, 8)
            }
            .scrollIndicators(.hidden)

            PrimaryButton(
                title: count > 0 ? L.f("ob_goals_cta", count) : L.s("ob_goals_cta_empty"),
                enabled: count > 0
            ) {
                withAnimation(Motion.rise) { model.phase = .baseline }
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .riseIn()
    }

    private func skip() {
        settings.onboardingDone = true
        withAnimation(Motion.rise) { model.phase = .app }
    }
}

// MARK: - Step 3: baseline

struct BaselineView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    /// The five bands, in the order `baselineAnswer` indexes them. The order
    /// must never change — the answer is stored by index, not by text.
    private var baselines: [String] {
        [
            L.s("ob_base_0_4"),
            L.s("ob_base_5_9"),
            L.s("ob_base_10_14"),
            L.s("ob_base_15_19"),
            L.s("ob_base_20_plus"),
        ]
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            OnboardingHeader(step: 3, onBack: {
                withAnimation(Motion.rise) { model.phase = .goals }
            }, onSkip: finish)

            Text(L.s("ob_base_title"))
                .font(theme.fonts.display(27))
                .kerning(-0.4)
                .padding(.top, 6)
            Text(L.s("ob_base_sub"))
                .font(theme.fonts.body(15))
                .foregroundStyle(theme.muted)
                .lineSpacing(2)
                .padding(.top, 6)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(Array(baselines.enumerated()), id: \.offset) { i, title in
                        SelectableRow(
                            title: title,
                            selected: settings.baselineAnswer == i,
                            checkStyle: .radio
                        ) {
                            Haptics.selection()
                            withAnimation(Motion.fade) { settings.baselineAnswer = i }
                        }
                        .riseIn(delay: Double(i) * 0.038)
                    }
                }
                .padding(.top, 18)
            }
            .scrollIndicators(.hidden)

            PrimaryButton(title: L.s("ob_continue"), enabled: settings.baselineAnswer >= 0) {
                finish()
            }
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
        .riseIn()
    }

    private func finish() {
        settings.onboardingDone = true
        withAnimation(Motion.rise) { model.phase = .app }
    }
}

// MARK: - Shared onboarding pieces

private struct OnboardingHeader: View {
    @Environment(\.theme) private var theme
    let step: Int
    let onBack: () -> Void
    let onSkip: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            CircleIconButton(systemName: "chevron.left", onCard2: true, action: onBack)
                .accessibilityLabel(L.s("a11y_back"))
            HStack {
                Text(L.f("ob_step_indicator", step))
                    .font(theme.fonts.body(12, .semibold))
                    .kerning(1)
                    .foregroundStyle(theme.faint)
                Spacer()
                Button(L.s("ob_skip"), action: onSkip)
                    .font(theme.fonts.body(14, .medium))
                    .foregroundStyle(theme.faint)
            }
        }
    }
}

private struct SelectableRow: View {
    enum CheckStyle { case check, radio }

    @Environment(\.theme) private var theme
    let title: String
    let selected: Bool
    let checkStyle: CheckStyle
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? theme.accent : theme.line, lineWidth: 1.5)
                        .background(Circle().fill(selected ? theme.accent : .clear))
                        .frame(width: 24, height: 24)
                    if selected {
                        switch checkStyle {
                        case .check:
                            Image(systemName: "checkmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(theme.onAccent)
                                .transition(.scale.combined(with: .opacity))
                        case .radio:
                            Circle()
                                .fill(theme.onAccent)
                                .frame(width: 10, height: 10)
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                }
                Text(title)
                    .font(theme.fonts.body(16, .medium))
                    .foregroundStyle(theme.text)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(selected ? theme.surface2 : theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(selected ? theme.accent : .clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PressScale(scale: 0.97))
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }
}
