import SwiftUI

// MARK: - Calendar sheet
//
// Two modes: select a diary day, or bank past dry days. Tide dots are logged
// days; moss dots are dry days (per-day state, glanceable, never a heatmap).

struct CalendarSheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    let dryMode: Bool

    /// Month offset from the current month (0 = current).
    @State private var monthOffset = 0

    private var monthStart: Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: DrinkingDay.date(for: model.todayKey))
        let base = cal.date(from: comps)!
        return cal.date(byAdding: .month, value: monthOffset, to: base)!
    }

    var body: some View {
        VStack(spacing: 0) {
            SheetGrabber()

            HStack {
                CircleIconButton(systemName: "chevron.left", size: 34, onCard2: true) {
                    withAnimation(Motion.fade) { monthOffset -= 1 }
                }
                .accessibilityLabel(L.s("a11y_prev_month"))
                Spacer()
                Text(monthLabel)
                    .font(theme.fonts.body(16.5, .semibold))
                Spacer()
                CircleIconButton(systemName: "chevron.right", size: 34, onCard2: true, dimmed: monthOffset >= 0) {
                    guard monthOffset < 0 else { return }
                    withAnimation(Motion.fade) { monthOffset += 1 }
                }
                .accessibilityLabel(L.s("a11y_next_month"))
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)

            // Weekday header — symbols and their order both come from the
            // platform calendar, so the week starts on the locale's own day.
            HStack(spacing: 4) {
                ForEach(Array(CalendarL10n.weekdayHeaders.enumerated()), id: \.offset) { _, d in
                    Text(d)
                        .font(theme.fonts.body(11, .semibold))
                        .foregroundStyle(theme.faint)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)

            // Grid
            let cells = makeCells()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(cells) { cell in
                    dayCell(cell)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 6)

            Text(dryMode
                ? L.s("sheet_cal_hint_dry")
                : L.s("sheet_cal_hint_select"))
                .font(theme.fonts.body(13))
                .foregroundStyle(theme.muted)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .padding(.horizontal, 20)
                .padding(.top, 14)

            SoftButton(title: L.s("action_done"), background: theme.surface2, foreground: theme.text, height: 48) {
                model.closeSheet()
            }
            .padding(.horizontal, 20)
            .padding(.top, 14)
            .padding(.bottom, 26)
        }
        .background(theme.bg)
        .presentationDetents([.medium, .large])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
    }

    private var monthLabel: String {
        let f = DateFormatter()
        f.locale = Locale.current
        // A fixed "MMMM yyyy" pattern puts the parts in the wrong order for
        // ja / ko / zh, which write 2026年3月. Let the locale decide.
        f.setLocalizedDateFormatFromTemplate("MMMMy")
        return f.string(from: monthStart)
    }

    private struct Cell: Identifiable {
        let id: Int
        let day: Int?
        let key: Int?
        let future: Bool
    }

    private func makeCells() -> [Cell] {
        let cal = Calendar.current
        // Never assume the grid starts on Sunday — the offset is measured from
        // whichever day the locale's calendar begins its week on.
        let lead = CalendarL10n.leadingBlanks(firstDayWeekday: cal.component(.weekday, from: monthStart))
        let daysInMonth = cal.range(of: .day, in: .month, for: monthStart)!.count
        var cells: [Cell] = (0 ..< lead).map { Cell(id: $0, day: nil, key: nil, future: false) }
        for d in 1 ... daysInMonth {
            let date = cal.date(byAdding: .day, value: d - 1, to: monthStart)!
            let key = DrinkingDay.key(forLabelDate: date)
            cells.append(Cell(id: lead + d, day: d, key: key, future: key > model.todayKey))
        }
        return cells
    }

    @ViewBuilder
    private func dayCell(_ cell: Cell) -> some View {
        if let day = cell.day, let key = cell.key {
            let logged = !model.logs(forKey: key).isEmpty
            let dry = model.dryKeys.contains(key)
            let isToday = key == model.todayKey
            let isSelected = key == model.selectedKey && !dryMode

            Button {
                guard !cell.future else { return }
                if dryMode {
                    model.toggleDry(key: key)
                } else {
                    model.dayOffset = key - model.todayKey
                    model.closeSheet()
                }
            } label: {
                VStack(spacing: 3) {
                    // Locale-aware digits: Thai and Arabic-Indic numerals
                    // come from the formatter, not from string interpolation.
                    Text(day.formatted())
                        .font(theme.fonts.body(14.5, .medium))
                        .foregroundStyle(theme.text)
                    Circle()
                        .fill(logged ? theme.accent : (dry ? theme.b1 : .clear))
                        .frame(width: 5, height: 5)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(isSelected ? theme.surface2 : .clear)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(isToday ? theme.accent : .clear, lineWidth: 1.5)
                        )
                )
                .opacity(cell.future ? 0.3 : 1)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(cellAccessibility(day: day, logged: logged, dry: dry))
        } else {
            Color.clear.frame(height: 44)
        }
    }

    private func cellAccessibility(day: Int, logged: Bool, dry: Bool) -> String {
        // One whole sentence per state, never concatenated fragments: the
        // clause order differs by language.
        let key: String
        if logged && dry {
            key = "a11y_cal_day_logged_dry"
        } else if logged {
            key = "a11y_cal_day_logged"
        } else if dry {
            key = "a11y_cal_day_dry"
        } else {
            key = "a11y_cal_day"
        }
        return L.f(key, day)
    }
}

struct SheetGrabber: View {
    @Environment(\.theme) private var theme
    var body: some View {
        Capsule()
            .fill(theme.line)
            .frame(width: 38, height: 5)
            .padding(.top, 9)
            .padding(.bottom, 8)
    }
}

// MARK: - Entry detail sheet

struct EntrySheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings
    let entryID: UUID

    private var entry: DrinkLog? {
        model.logs.first { $0.id == entryID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetGrabber().frame(maxWidth: .infinity)

            if let entry {
                HStack(spacing: 16) {
                    GlassIcon(abv: entry.abv, width: 46, height: 58)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(entry.name).font(theme.fonts.display(21))
                        Text(L.f("sheet_entry_meta",
                                 Int(entry.ml),
                                 Formatters.trim(entry.abv),
                                 Formatters.time(entry.loggedAt)))
                            .font(theme.fonts.body(14))
                            .foregroundStyle(theme.muted)
                    }
                }
                .padding(.top, 10)

                HStack(spacing: 10) {
                    statTile(Formatters.units1(entry.units),
                             L.unit("stat_label_units", Int(entry.units), UnitsConfig.current.noun(.short)),
                             tint: theme.accent)
                    statTile("\(entry.kcal)", L.s("stat_label_kcal"))
                    statTile(Formatters.money(entry.cost), L.s("stat_label_spent"))
                }
                .padding(.top, 18)

                SoftButton(title: L.s("sheet_entry_relog"), background: theme.surface2, foreground: theme.accent) {
                    model.relog(entry)
                }
                .padding(.top, 18)

                Button {
                    // The dialog host lives under the sheet layer — close the
                    // sheet first or the confirm dialog is unreachable.
                    model.closeSheet()
                    model.dialog = .deleteEntry(id: entry.id)
                } label: {
                    Text(L.s("sheet_entry_remove"))
                        .font(theme.fonts.body(16, .semibold))
                        .foregroundStyle(theme.b3)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                }
                .buttonStyle(PressScale(scale: 0.97))
                .padding(.top, 10)
            }
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(theme.bg)
        .presentationDetents([.height(360)])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
    }

    private func statTile(_ value: String, _ label: String, tint: Color? = nil) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(theme.fonts.display(17))
                .monospacedDigit()
                .foregroundStyle(tint ?? theme.text)
            Text(label)
                .font(theme.fonts.body(11.5))
                .foregroundStyle(theme.muted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .card(radius: 16)
    }
}

// MARK: - Units info sheet ("What's a unit, really?")

struct UnitsInfoSheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetGrabber().frame(maxWidth: .infinity)

            HStack(spacing: 16) {
                AnimatedGlass(width: 54, height: 70)
                VStack(alignment: .leading, spacing: 5) {
                    Text(L.unit("sheet_units_title", UnitsConfig.current.noun(.singular)))
                        .font(theme.fonts.display(20))
                    Text(L.s("sheet_units_body"))
                        .font(theme.fonts.body(13.5))
                        .foregroundStyle(theme.muted)
                        .lineSpacing(2)
                }
            }
            .padding(.top, 10)

            // The derivation, as chips: 150 ml × 13% × 0.789 ÷ 1000 = 1.5 units
            FlowChips {
                formulaChip(L.s("sheet_units_chip_pour"), bg: theme.surface2, fg: theme.accent, delay: 0.05)
                operatorText("×")
                formulaChip(L.s("sheet_units_chip_abv"), bg: theme.surface2, fg: theme.b2, delay: 0.15)
                operatorText("×")
                formulaChip(L.s("sheet_units_chip_density"), bg: theme.surface2, fg: theme.muted, delay: 0.25)
                operatorText("=")
                formulaChip(L.unit("sheet_units_chip_result", UnitsConfig.current.noun(.plural)),
                            bg: theme.surface2, fg: theme.b1, delay: 0.4, bold: true)
            }
            .padding(.top, 18)

            Text(L.s("sheet_units_density_note"))
                .font(theme.fonts.body(12))
                .foregroundStyle(theme.faint)
                .padding(.top, 8)

            Text(L.unit("sheet_units_targets", UnitsConfig.current.noun(.plural)))
                .font(theme.fonts.body(14))
                .foregroundStyle(theme.muted)
                .lineSpacing(3)
                .padding(.top, 14)

            SoftButton(title: L.s("diary_adjust_guideline"), background: theme.surface2, foreground: theme.text, height: 48) {
                model.closeSheet()
                Task {
                    try? await Task.sleep(for: .milliseconds(320))
                    withAnimation(Motion.slide) { model.push = .guideline }
                }
            }
            .padding(.top, 16)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
        .background(theme.bg)
        .presentationDetents([.height(430)])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
    }

    private func formulaChip(_ text: String, bg: Color, fg: Color, delay: Double, bold: Bool = false) -> some View {
        Text(text)
            .font(theme.fonts.body(13.5, bold ? .bold : .semibold))
            .monospacedDigit()
            .foregroundStyle(fg)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(bg))
            .riseIn(delay: delay)
    }

    private func operatorText(_ symbol: String) -> some View {
        Text(symbol)
            .font(theme.fonts.body(15))
            .foregroundStyle(theme.faint)
    }
}

/// Simple wrapping HStack for the formula chips.
struct FlowChips<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        FlowLayout(spacing: 6) { content }
    }
}

struct FlowLayout: Layout {
    var spacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), anchor: .topLeading, proposal: .unspecified)
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

// MARK: - BAC info sheet

struct BacInfoSheet: View {
    @Environment(\.theme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetGrabber().frame(maxWidth: .infinity)

            Text(L.s("bac_how_estimated"))
                .font(theme.fonts.display(20))
                .padding(.top, 10)
            Text(L.s("sheet_bac_widmark"))
                .font(theme.fonts.body(14.5))
                .foregroundStyle(theme.muted)
                .lineSpacing(3)
                .padding(.top, 10)
            Text(L.s("sheet_bac_not_measurement"))
                .font(theme.fonts.body(14.5))
                .foregroundStyle(theme.muted)
                .lineSpacing(3)
                .padding(.top, 10)

            Text(L.s("sheet_bac_never_drive"))
                .font(theme.fonts.body(13.5, .medium))
                .foregroundStyle(theme.b2)
                .lineSpacing(2)
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(theme.surface2))
                .padding(.top, 14)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
        .background(theme.bg)
        .presentationDetents([.height(320)])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Custom drink sheet

struct CustomDrinkSheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    @State private var name = ""
    @State private var base = "Beer"
    @State private var abvText = "5"
    @State private var mlText = "355"
    @State private var notes = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SheetGrabber().frame(maxWidth: .infinity)

                Text(L.s("sheet_custom_title"))
                    .font(theme.fonts.display(20))
                    .padding(.top, 8)

                TextField(L.s("sheet_custom_name_placeholder"), text: $name)
                    .font(theme.fonts.body(15.5))
                    .padding(.horizontal, 16)
                    .frame(height: 48)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface2))
                    .padding(.top, 14)

                SectionCaption(L.s("sheet_custom_base_caption")).padding(.top, 12)
                FlowChips {
                    // The five base categories stay literal — the drink
                    // nomenclature decision is deliberately deferred.
                    ForEach(Presets.customDrinkBases, id: \.self) { b in
                        Button {
                            Haptics.selection()
                            withAnimation(Motion.fade) { base = b }
                        } label: {
                            Text(b)
                                .font(theme.fonts.body(13.5, .semibold))
                                .foregroundStyle(base == b ? .white : theme.muted)
                                .padding(.horizontal, 15)
                                .frame(height: 34)
                                .background(Capsule().fill(base == b ? theme.accent : theme.surface2))
                        }
                        .buttonStyle(PressScale(scale: 0.93))
                    }
                }
                .padding(.top, 8)

                HStack(spacing: 10) {
                    fieldCard(label: L.s("sheet_custom_abv_label"), text: $abvText)
                    fieldCard(label: L.s("sheet_custom_ml_label"), text: $mlText)
                }
                .padding(.top, 14)

                TextField(L.s("sheet_custom_notes_placeholder"), text: $notes, axis: .vertical)
                    .font(theme.fonts.body(14.5))
                    .lineLimit(3 ... 3)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface2))
                    .padding(.top, 10)

                PrimaryButton(title: L.s("action_save"), enabled: !name.trimmingCharacters(in: .whitespaces).isEmpty, height: 50) {
                    model.saveCustomDrink(
                        name: name.trimmingCharacters(in: .whitespaces),
                        base: base,
                        abv: Double(abvText.replacingOccurrences(of: ",", with: ".")) ?? 5,
                        ml: Double(mlText) ?? 355,
                        notes: notes
                    )
                }
                .padding(.top, 14)

                Button(L.s("action_cancel")) { model.closeSheet() }
                    .font(theme.fonts.body(15, .semibold))
                    .foregroundStyle(theme.muted)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 26)
        }
        .scrollIndicators(.hidden)
        .background(theme.bg)
        .presentationDetents([.height(560), .large])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
    }

    private func fieldCard(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(theme.fonts.body(12, .semibold))
                .foregroundStyle(theme.muted)
            TextField("", text: text)
                .keyboardType(.decimalPad)
                .font(theme.fonts.display(19))
                .monospacedDigit()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .card(radius: 16)
    }
}

// MARK: - Health sync sheet

struct HealthSheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    /// Apple's product name, not copy — it is the same in every language.
    private static let healthServiceName = HealthService.name

    /// The path the user walks in Settings. Apple translates these panes, so
    /// this English spelling is a known gap; there is no inventory row for it.
    private static let healthSettingsPath = "Settings › Health › Data Access & Devices"

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetGrabber().frame(maxWidth: .infinity)

            Text(L.s("sheet_health_title"))
                .font(theme.fonts.display(20))
                .padding(.top, 8)
            Text(L.f("sheet_health_body", Self.healthServiceName))
                .font(theme.fonts.body(14))
                .foregroundStyle(theme.muted)
                .lineSpacing(3)
                .padding(.top, 8)

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(theme.surface2)
                    .frame(width: 30, height: 30)
                    .overlay(Circle().fill(theme.b1).frame(width: 11, height: 11))
                VStack(alignment: .leading, spacing: 1) {
                    Text(L.s("sheet_health_data_title")).font(theme.fonts.body(14.5, .semibold))
                    Text(L.s("sheet_health_data_sub"))
                        .font(theme.fonts.body(12.5))
                        .foregroundStyle(theme.muted)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card(radius: 18)
            .padding(.top, 14)

            PrimaryButton(title: L.f("sheet_health_cta", Self.healthServiceName), height: 50) {
                // Close the sheet first: the dialog host renders below the
                // presented-sheet layer.
                model.closeSheet()
                model.dialog = .healthPermission
            }
            .padding(.top, 16)

            Button(L.s("action_cancel")) { model.closeSheet() }
                .font(theme.fonts.body(15.5, .semibold))
                .foregroundStyle(theme.muted)
                .frame(maxWidth: .infinity)
                .frame(height: 46)
                .padding(.top, 8)

            Text(L.f("sheet_health_change_access", Self.healthSettingsPath))
                .font(theme.fonts.body(12))
                .foregroundStyle(theme.faint)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 26)
        .background(theme.bg)
        .presentationDetents([.height(420)])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
    }
}

// MARK: - Live Activity preview sheet

struct LivePreviewSheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SheetGrabber().frame(maxWidth: .infinity)

            Text(L.s("sheet_live_title"))
                .font(theme.fonts.display(20))
                .padding(.top, 8)
            Text(L.s("sheet_live_body"))
                .font(theme.fonts.body(14))
                .foregroundStyle(theme.muted)
                .lineSpacing(3)
                .padding(.top, 6)

            // Dark Lock-Screen mock — example numbers only.
            //
            // The mock keeps its own four slots rather than being driven by
            // `ReminderScheduler.bacContent`: that builder deliberately folds
            // the never-drive sentence into `body` and the figure into
            // `subtitle`, which does not map onto this card's caption / large
            // monospaced figure / short green countdown without changing the
            // layout. The shipped ordering is asserted in the builder itself.
            VStack(spacing: 14) {
                HStack(spacing: 12) {
                    DropletMark(size: 34, color: Color(hex: 0x7EB0CC), breathing: false)
                        .scaleEffect(0.8)
                        .frame(width: 34, height: 34)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(L.s("app_name"))
                            .font(theme.fonts.body(13, .semibold))
                            .foregroundStyle(.white)
                        Text(L.s("sheet_live_mock_status"))
                            .font(theme.fonts.body(11.5))
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 1) {
                        Text(L.s("sheet_live_mock_value"))
                            .font(theme.fonts.display(19))
                            .monospacedDigit()
                            .foregroundStyle(.white)
                        Text(L.s("sheet_live_mock_tozero"))
                            .font(theme.fonts.body(11))
                            .foregroundStyle(Color(hex: 0xA9CBB0))
                    }
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(.white.opacity(0.14))
                        Capsule().fill(Color(hex: 0x7EB0CC)).frame(width: geo.size.width * 0.46)
                    }
                }
                .frame(height: 5)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(Color(hex: 0x101014))
                    .shadow(color: .black.opacity(0.3), radius: 17, y: 10)
            )
            .padding(.top, 16)

            Text(L.s("sheet_live_note"))
                .font(theme.fonts.body(12.5))
                .foregroundStyle(theme.faint)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)

            SoftButton(title: L.s("action_done"), background: theme.surface2, foreground: theme.text, height: 48) {
                model.closeSheet()
            }
            .padding(.top, 14)
        }
        .padding(.horizontal, 22)
        .padding(.bottom, 28)
        .background(theme.bg)
        .presentationDetents([.height(400)])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
    }
}
