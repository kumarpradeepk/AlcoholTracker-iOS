import SwiftUI

// MARK: - Diary (home)

struct DiaryView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    @State private var scrolled = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                scrollProbe
                header

                if !model.pro {
                    proBanner.padding(.top, 16)
                }

                quickRow.padding(.top, 16)

                intakeCard
                    .padding(.top, 16)
                    .riseIn(delay: 0.04)

                bacCard
                    .padding(.top, 12)
                    .riseIn(delay: 0.08)

                if model.selectedDayIsDry {
                    dryCard
                        .padding(.top, 12)
                        .riseIn(delay: 0.1)
                }

                if !model.selectedDayLogs.isEmpty {
                    entriesSection.padding(.top, 22)
                } else if !model.selectedDayIsDry {
                    emptyState
                        .padding(.top, 12)
                        .riseIn(delay: 0.1)
                }
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 170)
        }
        .scrollIndicators(.hidden)
        .coordinateSpace(name: "diaryScroll")
        .onPreferenceChange(ScrollOffsetKey.self) { offset in
            let nowScrolled = offset < -34
            if nowScrolled != scrolled {
                withAnimation(Motion.slide) { scrolled = nowScrolled }
            }
        }
    }

    private var scrollProbe: some View {
        GeometryReader { geo in
            Color.clear.preference(
                key: ScrollOffsetKey.self,
                value: geo.frame(in: .named("diaryScroll")).minY
            )
        }
        .frame(height: 0)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 2) {
                Text(model.selectedDayTitle)
                    .font(.system(size: scrolled ? 22 : 32, weight: .bold))
                    .kerning(-0.5)
                    .contentTransition(.opacity)
                Text(model.selectedDaySubtitle)
                    .font(.system(size: 14))
                    .foregroundStyle(theme.sec)
            }
            Spacer()
            HStack(spacing: 8) {
                CircleIconButton(systemName: "chevron.left") {
                    withAnimation(Motion.fade) { model.dayOffset -= 1 }
                    Haptics.selection()
                }
                .accessibilityLabel(L.s("a11y_prev_day"))
                CircleIconButton(systemName: "calendar") {
                    model.openSheet(.calendar(dryMode: false))
                }
                .accessibilityLabel(L.s("a11y_open_calendar"))
                CircleIconButton(systemName: "chevron.right", dimmed: model.dayOffset >= 0) {
                    guard model.dayOffset < 0 else { return }
                    withAnimation(Motion.fade) { model.dayOffset += 1 }
                    Haptics.selection()
                }
                .accessibilityLabel(L.s("a11y_next_day"))
            }
        }
        .padding(.top, 12)
    }

    // MARK: Pro banner

    private var proBanner: some View {
        Button { model.openPaywall() } label: {
            HStack(spacing: 12) {
                DropletMark(size: 30, breathing: false)
                    .scaleEffect(0.62)
                    .frame(width: 30, height: 30)
                VStack(alignment: .leading, spacing: 1) {
                    Text(L.s("diary_pro_banner_title"))
                        .font(.system(size: 14.5, weight: .semibold))
                        .foregroundStyle(theme.ink)
                    Text(L.s("diary_pro_banner_sub"))
                        .font(.system(size: 12.5))
                        .foregroundStyle(theme.sec)
                }
                Spacer()
                ChevronRight()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(theme.tideSoft))
        }
        .buttonStyle(PressScale(scale: 0.98))
    }

    // MARK: Quick log

    private var quickRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L.s("diary_usual"))
                .font(.system(size: 13))
                .foregroundStyle(theme.sec)
            ScrollView(.horizontal) {
                HStack(spacing: 8) {
                    ForEach(model.quickItems) { item in
                        Button { model.quickLog(item) } label: {
                            HStack(spacing: 8) {
                                Circle().fill(theme.tide).frame(width: 6, height: 6)
                                Text(item.name)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(theme.ink)
                                Text(L.f(
                                    "units_abbrev_value",
                                    item.units,
                                    UnitsConfig.current.noun(.abbreviation)
                                ))
                                    .font(.system(size: 12.5))
                                    .monospacedDigit()
                                    .foregroundStyle(theme.sec)
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 44)
                            .background(
                                Capsule()
                                    .fill(theme.card)
                                    .shadow(color: .black.opacity(0.05), radius: 6, y: 4)
                            )
                        }
                        .buttonStyle(PressScale(scale: 0.94))
                        .accessibilityLabel(L.f(
                            "a11y_log_quick",
                            item.name,
                            item.units,
                            UnitsConfig.current.noun(.plural)
                        ))
                    }
                }
                .padding(.vertical, 2)
            }
            .scrollIndicators(.hidden)
        }
    }

    // MARK: Intake card

    private var ringColor: Color {
        let goal = Double(settings.dailyGoal)
        let u = model.selectedDayUnits
        if u / goal >= 1.5 { return theme.danger.opacity(0.85) }
        if u > goal { return theme.danger }
        if u / goal >= 0.75 { return theme.amber }
        return theme.tide
    }

    private var remainLine: (text: String, color: Color) {
        let goal = Double(settings.dailyGoal)
        let u = model.selectedDayUnits
        let rem = goal - u
        let units = UnitsConfig.current
        if settings.tone == .numbers {
            return (
                L.f("diary_remaining_numbers", u, settings.dailyGoal, units.noun(.plural)),
                theme.sec
            )
        }
        if u == 0 {
            return (L.s("diary_remaining_zero_neutral"), theme.sec)
        }
        if rem > 0 {
            return (
                L.f("diary_remaining_left_neutral", rem, units.noun(.plural)),
                theme.sec
            )
        }
        if rem == 0 {
            return (L.s("diary_remaining_at_target_neutral"), theme.sec)
        }
        return (
            L.f("diary_remaining_over_neutral", abs(rem), settings.dailyGoal, units.noun(.plural)),
            theme.amber
        )
    }

    private var intakeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L.s(model.dayOffset == 0 ? "diary_intake_today" : "diary_intake"))
                    .font(.system(size: 15, weight: .semibold))
                Spacer()
                Button { model.openSheet(.unitsInfo) } label: {
                    Text(verbatim: "i")
                        .font(.system(size: 12, weight: .semibold, design: .serif))
                        .italic()
                        .foregroundStyle(theme.sec)
                        .frame(width: 24, height: 24)
                        .background(Circle().fill(theme.card2))
                }
                .buttonStyle(PressScale(scale: 0.88))
                .accessibilityLabel(L.unit("a11y_units_info", UnitsConfig.current.noun(.singular)))
            }

            HStack(spacing: 20) {
                ZStack {
                    ProgressRing(
                        progress: model.selectedDayUnits / Double(max(1, settings.dailyGoal)),
                        color: ringColor
                    )
                    VStack(spacing: 0) {
                        CountingText(
                            value: model.selectedDayUnits,
                            format: { Formatters.units1($0) },
                            font: .system(size: 27, weight: .bold)
                        )
                        Text(L.unit(
                            "diary_ring_of_goal",
                            settings.dailyGoal,
                            UnitsConfig.current.noun(count: settings.dailyGoal)
                        ))
                            .font(.system(size: 11.5))
                            .foregroundStyle(theme.sec)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(L.f(
                    "a11y_intake_ring",
                    model.selectedDayUnits,
                    settings.dailyGoal,
                    UnitsConfig.current.noun(.plural)
                ))

                VStack(spacing: 12) {
                    miniProgress(
                        label: L.s("diary_this_week"),
                        value: model.weekUnits,
                        target: settings.weeklyGoal
                    )
                    miniProgress(
                        label: L.s("diary_this_month"),
                        value: model.monthUnits,
                        target: settings.monthlyGoal
                    )
                }
            }
            .padding(.top, 14)

            Text(remainLine.text)
                .font(.system(size: 13.5))
                .foregroundStyle(remainLine.color)
                .padding(.top, 14)

            Button(L.s("diary_adjust_guideline")) {
                withAnimation(Motion.slide) { model.push = .guideline }
            }
            .font(.system(size: 13))
            .foregroundStyle(theme.tide)
            .padding(.top, 5)
        }
        .padding(18)
        .card()
    }

    private func miniProgress(label: String, value: Double, target: Int) -> some View {
        VStack(spacing: 5) {
            HStack {
                Text(label)
                    .font(.system(size: 12.5))
                    .foregroundStyle(theme.sec)
                Spacer()
                Text(L.f("diary_mini_value", value, target))
                    .font(.system(size: 12.5, weight: .semibold))
                    .monospacedDigit()
            }
            ThinBar(fraction: value / Double(max(1, target)), color: theme.tide)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L.f(
            "a11y_mini_progress",
            label,
            value,
            target,
            UnitsConfig.current.noun(.plural)
        ))
    }

    // MARK: BAC card

    @ViewBuilder
    private var bacCard: some View {
        if !model.pro {
            bacFreeCard
        } else if model.bacEstimate == nil {
            bacSetupCard
        } else if settings.bacOn, let bac = model.bacEstimate {
            bacLiveCard(bac)
        }
    }

    private var bacFreeCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L.s("bac_monitor")).font(.system(size: 15, weight: .semibold))
                Spacer()
                ProBadge { model.openPaywall() }
            }
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(verbatim: "--")
                    .font(.system(size: 33, weight: .bold))
                    .foregroundStyle(theme.ter)
                HStack(spacing: 6) {
                    PulsingDot(color: theme.ter)
                    Text(L.s("bac_status_waiting"))
                        .font(.system(size: 11, weight: .bold))
                        .kerning(1)
                        .foregroundStyle(theme.ter)
                }
            }
            .padding(.top, 12)
            Text(L.s("bac_free_body"))
                .font(.system(size: 13.5))
                .foregroundStyle(theme.sec)
                .padding(.top, 6)
            HStack(spacing: 18) {
                Button(L.s("bac_how_estimated")) { model.openSheet(.bacInfo) }
                Button(L.s("bac_trends")) { model.openPaywall() }
            }
            .font(.system(size: 13))
            .foregroundStyle(theme.tide)
            .padding(.top, 12)
        }
        .padding(18)
        .card()
    }

    private var bacSetupCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L.s("bac_setup_title"))
                .font(.system(size: 15, weight: .semibold))
            Text(L.s("bac_setup_body"))
                .font(.system(size: 13.5))
                .foregroundStyle(theme.sec)
                .lineSpacing(2)
                .padding(.top, 6)
            Button {
                withAnimation(Motion.slide) { model.push = .profile }
            } label: {
                Text(L.s("bac_setup_cta"))
                    .font(.system(size: 14.5, weight: .semibold))
                    .foregroundStyle(theme.tide)
                    .padding(.horizontal, 20)
                    .frame(height: 40)
                    .background(Capsule().fill(theme.tideSoft))
            }
            .buttonStyle(PressScale(scale: 0.95))
            .padding(.top, 14)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .card()
    }

    private func bacLiveCard(_ bac: BacEstimate) -> some View {
        let statusColors: (bg: Color, fg: Color) = switch bac.status {
        case .rising: (theme.amberSoft, theme.amber)
        case .settling: (theme.tideSoft, theme.tide)
        case .clear: (theme.mossSoft, theme.moss)
        }
        let display = settings.bacUnit == .percent
            ? L.f("bac_value_percent", bac.value)
            : L.f("bac_value_permille", bac.value * 10)

        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L.s("bac_monitor")).font(.system(size: 15, weight: .semibold))
                Spacer()
                Text(bac.status.label)
                    .font(.system(size: 10.5, weight: .bold))
                    .kerning(0.8)
                    .foregroundStyle(statusColors.fg)
                    .padding(.horizontal, 9)
                    .padding(.vertical, 4)
                    .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(statusColors.bg))
            }
            CountingText(
                value: bac.value,
                format: { _ in display },
                font: .system(size: 33, weight: .bold)
            )
            .padding(.top, 10)
            Text(bac.value > 0.002
                ? L.f("bac_sober_in", Formatters.hoursMinutes(bac.hoursToZero))
                : L.s("bac_all_clear"))
                .font(.system(size: 14))
                .foregroundStyle(theme.moss)
                .padding(.top, 3)

            Button {
                withAnimation(Motion.slide) { model.push = .bacTrends }
            } label: {
                HStack {
                    Text(L.s("bac_trends"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.tide)
                    Spacer()
                    ChevronRight()
                }
                .padding(.top, 12)
                .overlay(alignment: .top) { Rectangle().fill(theme.hair).frame(height: 0.5) }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.top, 14)

            Text(L.s("bac_disclaimer_short"))
                .font(.system(size: 11.5))
                .foregroundStyle(theme.ter)
                .lineSpacing(2)
                .padding(.top, 10)
            Button(L.s("bac_how_estimated")) { model.openSheet(.bacInfo) }
                .font(.system(size: 13))
                .foregroundStyle(theme.tide)
                .padding(.top, 6)
        }
        .padding(18)
        .card()
    }

    // MARK: Dry day card

    private var dryCard: some View {
        VStack(spacing: 0) {
            AnimatedGlass(width: 72, height: 96, liquid: theme.moss, outline: theme.moss.opacity(0.55), showCheck: true)
            Text(L.s(model.dayOffset == 0 ? "diary_dry_marked" : "diary_dry_remembered"))
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(theme.moss)
                .padding(.top, 12)
            Text(L.s("diary_dry_body"))
                .font(.system(size: 13.5))
                .foregroundStyle(theme.sec)
                .padding(.top, 5)
            Button(L.s("diary_dry_unmark")) { model.unmarkDry(key: model.selectedKey) }
                .font(.system(size: 13))
                .foregroundStyle(theme.ter)
                .underline()
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity)
        .padding(22)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(theme.mossSoft))
    }

    // MARK: Entries

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionCaption(L.s(model.dayOffset == 0 ? "diary_logged_today" : "diary_logged_this_day"))
            ForEach(Array(model.selectedDayLogs.enumerated()), id: \.element.id) { i, entry in
                Button { model.openSheet(.entry(id: entry.id)) } label: {
                    HStack(spacing: 12) {
                        GlassIcon(abv: entry.abv)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.name)
                                .font(.system(size: 15.5, weight: .semibold))
                                .foregroundStyle(theme.ink)
                            Text(L.f("diary_entry_meta", Int(entry.ml), Formatters.trim(entry.abv)))
                                .font(.system(size: 13))
                                .foregroundStyle(theme.sec)
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(L.f(
                                "units_abbrev_value",
                                entry.units,
                                UnitsConfig.current.noun(.abbreviation)
                            ))
                                .font(.system(size: 14, weight: .semibold))
                                .monospacedDigit()
                                .foregroundStyle(theme.tide)
                            Text(Formatters.time(entry.loggedAt))
                                .font(.system(size: 12))
                                .foregroundStyle(theme.ter)
                        }
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(theme.card)
                            .shadow(color: .black.opacity(0.03), radius: 1, y: 1)
                            .shadow(color: .black.opacity(0.04), radius: 8, y: 5)
                    )
                }
                .buttonStyle(PressScale(scale: 0.97))
                .padding(.top, 10)
                .riseIn(delay: Double(i) * 0.045)
            }
        }
    }

    // MARK: Empty state

    private var emptyState: some View {
        VStack(spacing: 0) {
            AnimatedGlass()
            Text(L.s(model.dayOffset == 0 ? "diary_empty_title_today" : "diary_empty_title_other"))
                .font(.system(size: 19, weight: .semibold))
                .padding(.top, 24)
            Text(L.s(model.dayOffset == 0
                ? "diary_empty_body_today"
                : "diary_empty_body_other"))
                .font(.system(size: 14.5))
                .foregroundStyle(theme.sec)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .frame(maxWidth: 280)
                .padding(.top, 8)

            VStack(spacing: 10) {
                PrimaryButton(title: L.s("action_log_drink"), height: 52) { model.openSheet(.log) }
                SoftButton(
                    title: L.s("action_mark_dry_day"),
                    background: theme.mossSoft,
                    foreground: theme.moss
                ) { model.markDry(key: model.selectedKey) }
                Button(L.s("diary_add_previous_dry")) { model.openSheet(.calendar(dryMode: true)) }
                    .font(.system(size: 14))
                    .foregroundStyle(theme.tide)
                    .padding(.top, 4)
            }
            .padding(.horizontal, 26)
            .padding(.top, 22)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 22)
    }
}

// MARK: - Helpers

private struct ScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct PulsingDot: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    var color: Color
    @State private var bright = false

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .opacity(bright ? 1 : 0.25)
            .onAppear {
                guard !reduceMotion else { return }
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    bright = true
                }
            }
    }
}
