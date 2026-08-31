import SwiftUI
import UIKit

// MARK: - Statistics

struct StatisticsView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    private var range: StatsRange { model.statsRange }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                header
                periodControl.padding(.top, 16)
                pager.padding(.top, 14)

                if model.statsPeriod == .custom {
                    Button(L.s("stats_edit_range")) { model.openSheet(.customRange) }
                        .font(Fonts.text(13))
                        .foregroundStyle(theme.acc)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 8)
                }

                if let verdict = StatsEngine.verdict(range: range, tone: settings.tone) {
                    Text(verdict.text)
                        .font(Fonts.text(13.5, .semibold))
                        .foregroundStyle(verdict.positive ? theme.moss : theme.sub)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                }

                statTiles.padding(.top, 14)

                unitsChartCard
                    .padding(.top, 12)
                    .riseIn(delay: 0.1)
                spendChartCard
                    .padding(.top, 12)
                    .riseIn(delay: 0.14)
                moneySavedCard.padding(.top, 12)
                breakdownCard.padding(.top, 12)
                dryRingCard
                    .padding(.top, 12)
                    .riseIn(delay: 0.18)
            }
            .padding(.horizontal, 18)
            .padding(.bottom, 150)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Header

    private var header: some View {
        HStack(alignment: .bottom) {
            Text(MainTab.stats.title)
                .font(Fonts.figure(32))
                .kerning(-0.5)
            Spacer()
            Button { model.openSheet(.export) } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 12, weight: .semibold))
                    Text(L.s("action_export"))
                        .font(.system(size: 13.5, weight: .semibold))
                }
                .foregroundStyle(theme.acc)
                .padding(.horizontal, 14)
                .frame(height: 36)
                .background(
                    Capsule()
                        .fill(theme.card)
                        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
                )
            }
            .buttonStyle(PressScale(scale: 0.92))
        }
        .padding(.top, 12)
    }

    // MARK: Period control (sliding thumb, Pro locks past 7D)

    private var periodControl: some View {
        GeometryReader { geo in
            let segmentWidth = (geo.size.width - 6) / 5
            let index = CGFloat(StatsPeriod.allCases.firstIndex(of: model.statsPeriod) ?? 0)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(theme.card)
                    .shadow(color: .black.opacity(0.1), radius: 2.5, y: 1)
                    .frame(width: segmentWidth, height: geo.size.height - 6)
                    .offset(x: 3 + index * segmentWidth)
                    .animation(.spring(response: 0.38, dampingFraction: 0.78), value: model.statsPeriod)

                HStack(spacing: 0) {
                    ForEach(StatsPeriod.allCases) { period in
                        Button { select(period) } label: {
                            HStack(spacing: 3) {
                                Text(period.label)
                                    .font(Fonts.text(13, .semibold))
                                if period.requiresPro, !model.pro {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8))
                                        .foregroundStyle(theme.sub)
                                }
                            }
                            .foregroundStyle(model.statsPeriod == period ? theme.ink : theme.sub)
                            .frame(maxWidth: .infinity)
                            .frame(height: geo.size.height)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .frame(height: 34)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.elev).padding(-3))
        .padding(3)
    }

    private func select(_ period: StatsPeriod) {
        if period.requiresPro, !model.pro {
            model.openPaywall()
            return
        }
        Haptics.selection()
        if period == .custom {
            model.openSheet(.customRange)
            return
        }
        withAnimation(Motion.fade) {
            model.statsPeriod = period
            model.statsPage = 0
        }
    }

    // MARK: Range pager

    private var pager: some View {
        HStack {
            CircleIconButton(systemName: "chevron.left", size: 34) {
                withAnimation(Motion.fade) { model.statsPage += 1 }
            }
            .accessibilityLabel(L.s("a11y_prev_period"))
            Spacer()
            Text(range.label)
                .font(Fonts.text(14.5, .semibold))
            Spacer()
            CircleIconButton(systemName: "chevron.right", size: 34, dimmed: model.statsPage == 0) {
                guard model.statsPage > 0 else { return }
                withAnimation(Motion.fade) { model.statsPage -= 1 }
            }
            .accessibilityLabel(L.s("a11y_next_period"))
        }
    }

    // MARK: Stat tiles

    private var statTiles: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
            tile(
                L.s("stats_tile_drunk"),
                value: range.totalMl,
                format: { "\(Int($0).formatted())" },
                unit: L.s("stats_unit_ml"),
                delay: 0
            )
            tile(
                L.s("stats_tile_alcohol"),
                value: range.totalUnits,
                format: { Formatters.units1($0) },
                unit: L.unit(
                    "stats_unit_units",
                    Int(range.totalUnits.rounded()),
                    UnitsConfig.current.noun(.short)
                ),
                delay: 0.05
            )
            tile(
                L.s("stats_tile_spending"),
                value: range.totalSpend,
                format: { Formatters.money($0) },
                unit: nil,
                delay: 0.1
            )
            tile(
                L.s("stats_tile_calories"),
                value: Double(range.totalKcal),
                format: { "\(Int($0).formatted())" },
                unit: settings.energyUnit == .kJ ? L.s("units_kj") : L.s("stats_unit_kcal"),
                delay: 0.15,
                footnote: StatsEngine.kcalComparison(kcal: range.totalKcal, tone: settings.tone)
            )
        }
    }

    private func tile(
        _ label: String,
        value: Double,
        format: @escaping (Double) -> String,
        unit: String?,
        delay: Double,
        footnote: String = ""
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(Fonts.text(12, .semibold))
                .foregroundStyle(theme.sub)
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                CountingText(value: value, format: format, font: .system(size: 20, weight: .bold))
                if let unit {
                    Text(unit)
                        .font(Fonts.text(12, .medium))
                        .foregroundStyle(theme.sub)
                }
            }
            if !footnote.isEmpty {
                Text(footnote)
                    .font(Fonts.text(11))
                    .foregroundStyle(theme.sub)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .card(radius: 18)
        .riseIn(delay: delay)
        .accessibilityElement(children: .combine)
    }

    // MARK: Charts

    private var unitsChartCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L.unit("stats_units_chart_title", UnitsConfig.current.noun(.plural)))
                    .font(Fonts.text(15, .semibold))
                Spacer()
                averageToggle(label: L.s("stats_daily_average"), isOn: $model.showDailyAverage)
            }

            if range.totalUnits > 0 {
                BarChart(
                    buckets: range.buckets,
                    valueOf: { $0.units },
                    averageFraction: model.showDailyAverage
                        ? (range.totalUnits / Double(range.days)) / max(0.1, range.buckets.map(\.units).max() ?? 0.1)
                        : nil
                )
                .padding(.top, 14)

                HStack {
                    Text(L.f("stats_units_total", range.totalUnits, UnitsConfig.current.noun(.plural)))
                    Spacer()
                    Text(L.f("stats_units_per_day", range.totalUnits / Double(range.days)))
                }
                .font(Fonts.text(12.5))
                .monospacedDigit()
                .foregroundStyle(theme.sub)
                .padding(.top, 10)
            } else {
                VStack(spacing: 12) {
                    RisingBubbles()
                    Text(L.s("stats_units_empty"))
                        .font(Fonts.text(13.5))
                        .foregroundStyle(theme.sub)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 110)
            }
        }
        .padding(16)
        .card()
    }

    private var spendChartCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(L.s("stats_spend_chart_title")).font(Fonts.text(15, .semibold))
                Spacer()
                averageToggle(label: L.s("stats_daily_average"), isOn: $model.showSpendAverage)
            }

            if range.totalSpend > 0 {
                SpendBarChart(
                    buckets: range.buckets,
                    averageFraction: model.showSpendAverage
                        ? (range.totalSpend / Double(range.days)) / max(0.1, range.buckets.map(\.spend).max() ?? 0.1)
                        : nil
                )
                .padding(.top, 14)

                HStack {
                    Text(L.f(
                        "stats_spend_total",
                        Formatters.moneyAmount(range.totalSpend),
                        CurrencyConfig.current.symbol
                    ))
                    Spacer()
                    Text(L.f(
                        "stats_spend_per_day",
                        Formatters.moneyAmount(range.totalSpend / Double(range.days)),
                        CurrencyConfig.current.symbol
                    ))
                }
                .font(Fonts.text(12.5))
                .monospacedDigit()
                .foregroundStyle(theme.sub)
                .padding(.top, 10)
            } else {
                Text(L.s("stats_spend_empty"))
                    .font(Fonts.text(13.5))
                    .foregroundStyle(theme.sub)
                    .frame(maxWidth: .infinity)
                    .frame(height: 90)
            }
        }
        .padding(16)
        .card()
    }

    private func averageToggle(label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 7) {
            Text(label)
                .font(Fonts.text(12))
                .foregroundStyle(theme.sub)
            MiniToggle(isOn: isOn)
        }
    }

    // MARK: Money saved

    private var moneySavedCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 10) {
                Text(L.s("stats_money_saved_title")).font(Fonts.text(15, .semibold))
                Spacer()
                HStack(spacing: 5) {
                    Text(L.f("stats_baseline_label", CurrencyConfig.current.symbol))
                        .font(Fonts.text(12.5))
                        .foregroundStyle(theme.sub)
                    TextField(L.s("log_cost_placeholder"), text: $settings.spendBaseline)
                        .keyboardType(.decimalPad)
                        .font(Fonts.text(14, .semibold))
                        .monospacedDigit()
                        .multilineTextAlignment(.center)
                        .frame(width: 52, height: 32)
                        .background(RoundedRectangle(cornerRadius: 9, style: .continuous).fill(theme.elev))
                }
            }
            Text(StatsEngine.savedLine(
                baseline: Double(settings.spendBaseline.replacingOccurrences(of: ",", with: ".")) ?? 0,
                range: range
            ))
            .font(Fonts.text(13.5))
            .foregroundStyle(theme.sub)
            .lineSpacing(3)
            .padding(.top, 10)
        }
        .padding(16)
        .card()
    }

    // MARK: Drink breakdown

    @ViewBuilder
    private var breakdownCard: some View {
        if !model.pro {
            Button { model.openPaywall() } label: {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L.s("stats_breakdown_title"))
                            .font(Fonts.text(15, .semibold))
                            .foregroundStyle(theme.ink)
                        Spacer()
                        ProBadge()
                    }
                    Text(L.s("stats_breakdown_locked"))
                        .font(Fonts.text(13.5))
                        .foregroundStyle(theme.sub)
                        .lineSpacing(2)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
            }
            .buttonStyle(PressScale(scale: 0.98))
            .card()
        } else if range.breakdown.isEmpty {
            VStack(alignment: .leading, spacing: 6) {
                Text(L.s("stats_breakdown_title")).font(Fonts.text(15, .semibold))
                Text(L.s("stats_breakdown_empty"))
                    .font(Fonts.text(13.5))
                    .foregroundStyle(theme.sub)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .card()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text(L.s("stats_breakdown_title")).font(Fonts.text(15, .semibold))
                ForEach(Array(range.breakdown.enumerated()), id: \.element.id) { i, row in
                    VStack(spacing: 5) {
                        HStack {
                            Text(L.f("stats_breakdown_row", row.name, row.pours))
                                .font(Fonts.text(13.5))
                            Spacer()
                            Text(L.f("stats_breakdown_pct", row.percent))
                                .font(Fonts.text(13.5, .semibold))
                                .monospacedDigit()
                                .foregroundStyle(theme.acc)
                        }
                        ThinBar(fraction: Double(row.percent) / 100, color: theme.acc)
                    }
                    .padding(.top, 12)
                    .riseIn(delay: Double(i) * 0.04)
                }
                if let top = range.breakdown.first {
                    Text(L.f(
                        "stats_breakdown_leader",
                        top.name,
                        top.percent,
                        UnitsConfig.current.noun(.plural)
                    ))
                        .font(Fonts.text(13))
                        .foregroundStyle(theme.sub)
                        .padding(.top, 12)
                }
            }
            .padding(16)
            .card()
        }
    }

    // MARK: Dry days ring

    private var dryRingCard: some View {
        HStack(spacing: 16) {
            ZStack {
                ProgressRing(
                    progress: Double(range.dryPercent) / 100,
                    color: theme.moss,
                    lineWidth: 8,
                    size: 84
                )
                CountingText(
                    value: Double(range.dryPercent),
                    format: { L.f("stats_dry_ring_pct", Int($0)) },
                    font: .system(size: 16, weight: .bold)
                )
            }
            VStack(alignment: .leading, spacing: 5) {
                Text(dryCopy.title).font(Fonts.text(15, .semibold))
                Text(dryCopy.body)
                    .font(Fonts.text(13))
                    .foregroundStyle(theme.sub)
                    .lineSpacing(3)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .card()
        .accessibilityElement(children: .combine)
        .accessibilityLabel(L.f("a11y_dry_ring", range.dryCount, range.dryPercent))
    }

    private var dryCopy: (title: String, body: String) {
        if settings.tone == .numbers {
            return (
                L.s("stats_dry_title_numbers"),
                L.f("stats_dry_body_numbers", range.dryCount, range.days, range.dryPercent)
            )
        }
        if range.dryCount > 0 {
            return (
                L.s("stats_dry_title_positive"),
                L.f("stats_dry_body_positive", range.dryPercent)
            )
        }
        return (
            L.s("stats_dry_title_none"),
            L.s("stats_dry_body_none")
        )
    }
}

// MARK: - Spend bar chart (amber bars)

struct SpendBarChart: View {
    @Environment(\.theme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let buckets: [StatsBucket]
    var averageFraction: Double?
    @State private var grown = false

    private var maxValue: Double { max(0.1, buckets.map(\.spend).max() ?? 0.1) }

    var body: some View {
        ZStack(alignment: .bottom) {
            HStack(alignment: .bottom, spacing: 3) {
                ForEach(buckets) { b in
                    let fraction = max(0.02, b.spend / maxValue)
                    UnevenRoundedRectangle(
                        topLeadingRadius: 3, bottomLeadingRadius: 2,
                        bottomTrailingRadius: 2, topTrailingRadius: 3
                    )
                    .fill(theme.amber.opacity(0.7))
                    .frame(height: grown ? 110 * fraction : 2)
                    .frame(maxWidth: .infinity)
                    .animation(Motion.reduced(reduceMotion, Motion.bars.delay(Double(b.id) * 0.024)), value: grown)
                }
            }
            .frame(height: 110, alignment: .bottom)

            if let averageFraction {
                Rectangle()
                    .fill(.clear)
                    .frame(height: 1.5)
                    .overlay(DashedLine().stroke(theme.sub, style: StrokeStyle(lineWidth: 1.5, dash: [5, 4])))
                    .offset(y: -110 * min(0.96, averageFraction))
            }
        }
        .onAppear { grown = true }
    }
}

private struct DashedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 0, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.width, y: rect.midY))
        return p
    }
}

// MARK: - Mini toggle (40×24, chart headers)

struct MiniToggle: View {
    @Environment(\.theme) private var theme
    @Binding var isOn: Bool

    var body: some View {
        Button {
            Haptics.selection()
            withAnimation(Motion.pop) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? theme.acc : theme.elev)
                    .frame(width: 40, height: 24)
                Circle()
                    .fill(.white)
                    .shadow(color: .black.opacity(0.2), radius: 2, y: 1)
                    .frame(width: 20, height: 20)
                    .padding(2)
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(.isToggle)
        .accessibilityValue(isOn ? L.s("a11y_toggle_on") : L.s("a11y_toggle_off"))
    }
}

// MARK: - Rising bubbles (empty chart state)

struct RisingBubbles: View {
    @Environment(\.theme) private var theme

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 20)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                func bubble(x: CGFloat, phase: Double, duration: Double, radius: CGFloat, alpha: Double) {
                    let p = ((t + phase) / duration).truncatingRemainder(dividingBy: 1)
                    let y = size.height - p * size.height
                    let a = p < 0.2 ? p / 0.2 : (1 - p)
                    context.fill(
                        Path(ellipseIn: CGRect(x: x - radius, y: y - radius, width: radius * 2, height: radius * 2)),
                        with: .color(theme.acc.opacity(alpha * a))
                    )
                }
                bubble(x: 13, phase: 0, duration: 5, radius: 3, alpha: 0.55)
                bubble(x: 33, phase: 1.4, duration: 6.4, radius: 2.5, alpha: 0.4)
                bubble(x: 50, phase: 2.8, duration: 7.2, radius: 2, alpha: 0.3)
            }
        }
        .frame(width: 64, height: 36)
        .accessibilityHidden(true)
    }
}

// MARK: - Custom range sheet

struct CustomRangeSheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    @State private var from = Calendar.current.date(byAdding: .day, value: -13, to: .now)!
    @State private var to = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetGrabber().frame(maxWidth: .infinity)

            Text(L.s("sheet_range_title"))
                .font(Fonts.figure(20))
                .padding(.top, 8)

            HStack(spacing: 10) {
                dateCard(label: L.s("sheet_range_from"), selection: $from)
                dateCard(label: L.s("sheet_range_to"), selection: $to)
            }
            .padding(.top, 14)

            HStack(spacing: 8) {
                quickChip(L.s("sheet_range_last7")) {
                    from = Calendar.current.date(byAdding: .day, value: -6, to: .now)!
                    to = .now
                }
                quickChip(L.s("sheet_range_last30")) {
                    from = Calendar.current.date(byAdding: .day, value: -29, to: .now)!
                    to = .now
                }
            }
            .padding(.top, 12)

            PrimaryButton(title: L.s("action_apply"), height: 50) {
                model.customFrom = from
                model.customTo = to
                model.statsPeriod = .custom
                model.statsPage = 0
                model.closeSheet()
            }
            .padding(.top, 16)

            Button(L.s("action_cancel")) { model.closeSheet() }
                .font(Fonts.text(15.5, .semibold))
                .foregroundStyle(theme.sub)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .padding(.top, 8)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 26)
        .background(theme.page)
        .presentationDetents([.height(380)])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
        .onAppear {
            if let f = model.customFrom { from = f }
            if let t = model.customTo { to = t }
        }
    }

    private func dateCard(label: String, selection: Binding<Date>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(Fonts.text(12, .semibold))
                .foregroundStyle(theme.sub)
            DatePicker("", selection: selection, in: ...Date(), displayedComponents: .date)
                .labelsHidden()
                .datePickerStyle(.compact)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(radius: 16)
    }

    private func quickChip(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(Fonts.text(13.5, .semibold))
                .foregroundStyle(theme.sub)
                .frame(maxWidth: .infinity)
                .frame(height: 36)
                .background(Capsule().fill(theme.elev))
        }
        .buttonStyle(PressScale(scale: 0.94))
    }
}

// MARK: - Export sheet

struct ExportSheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    @State private var shareURL: URL?

    private var fileName: String {
        // The range label is built by `DateIntervalFormatter`, and several
        // locales write dates with slashes (ja: 2026/03/01～2026/03/07), which
        // cannot appear in a file name. Strip every path separator, not just
        // the en dash.
        // Backslash and quote are written as escapes so the set is unambiguous.
        let illegal = CharacterSet(charactersIn: "/:*?<>|\\\u{22}")
        return L.f("sheet_export_filename", model.statsRange.label)
            .replacingOccurrences(of: "–", with: "-")
            .components(separatedBy: illegal)
            .joined(separator: "-")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetGrabber().frame(maxWidth: .infinity)

            Text(L.s("sheet_export_title"))
                .font(Fonts.figure(20))
                .padding(.top, 8)

            HStack(spacing: 14) {
                Text(L.s("sheet_export_format"))
                    .font(Fonts.text(10, .bold))
                    .foregroundStyle(theme.acc)
                    .frame(width: 42, height: 52)
                    .background(RoundedRectangle(cornerRadius: 8, style: .continuous).fill(theme.elev))
                VStack(alignment: .leading, spacing: 2) {
                    Text(fileName)
                        .font(Fonts.text(14.5, .semibold))
                        .lineLimit(1)
                    Text(L.s("sheet_export_desc"))
                        .font(Fonts.text(12.5))
                        .foregroundStyle(theme.sub)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(radius: 18)
            .padding(.top, 14)

            PrimaryButton(title: L.s("sheet_export_cta"), height: 50) { export() }
                .padding(.top, 16)

            Button(L.s("action_cancel")) { model.closeSheet() }
                .font(Fonts.text(15.5, .semibold))
                .foregroundStyle(theme.sub)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .padding(.top, 8)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 26)
        .background(theme.page)
        .presentationDetents([.height(330)])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
        .sheet(item: $shareURL) { url in
            ShareSheet(items: [url]) {
                model.closeSheet()
                model.showToast(L.s("toast_csv_saved_ios"))
            }
        }
    }

    private func export() {
        let csv = CsvExport.statisticsCSV(
            range: model.statsRange,
            logsByDay: model.logsByDay,
            dryKeys: model.dryKeys
        )
        guard let url = CsvExport.writeTemp(csv: csv, fileName: fileName) else {
            model.showToast(L.s("toast_export_failed_ios"))
            return
        }
        shareURL = url
    }
}

extension URL: Identifiable {
    public var id: String { absoluteString }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onComplete: (() -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            if completed { onComplete?() }
        }
        return controller
    }

    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
