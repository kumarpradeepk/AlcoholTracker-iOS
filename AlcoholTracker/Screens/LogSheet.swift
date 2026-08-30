import SwiftUI

// MARK: - Log Drink sheet — three steps, one sheet, never a wizard of screens.
//
// Step 0: pick (search / saved / popular / create custom)
// Step 1: fine-tune (ABV, serving, quantity) with the live derivation line
// Step 2: review & save (when, cost, calories)

struct LogSheet: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var settings: AppSettings

    @State private var step = 0
    @State private var query = ""
    @State private var pickedName: String?
    @State private var abv: Double = 5
    @State private var ml: Double = 355
    @State private var quantity: Double = 1

    /// Hoisted out of the `ForEach` so the element type is stated rather than
    /// inferred from a mix of a literal and a lookup.
    private var quantityOptions: [(Double, String)] {
        [(0.5, L.s("log_qty_half")), (1.0, "1"), (2.0, "2")]
    }

    @State private var costText = ""
    @State private var whenIndex = 0
    @State private var servingInMl = true
    @State private var pickedCost: Double = 0

    private var filteredPresets: [DrinkPreset] {
        query.isEmpty
            ? Presets.popular
            : Presets.popular.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var filteredSaved: [SavedDrink] {
        query.isEmpty
            ? model.savedDrinks
            : model.savedDrinks.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    private var canAdvance: Bool { step > 0 || pickedName != nil }

    var body: some View {
        VStack(spacing: 0) {
            grabber

            // Title row
            HStack {
                if step > 0 {
                    CircleIconButton(systemName: "chevron.left", size: 32, onCard2: true) {
                        withAnimation(Motion.slide) { step -= 1 }
                    }
                    .accessibilityLabel(L.s("a11y_back"))
                    .transition(.opacity)
                } else {
                    Color.clear.frame(width: 32, height: 32)
                }
                Spacer()
                Text([L.s("action_log_drink"), L.s("log_title_tune"), L.s("log_title_review")][step])
                    .font(theme.fonts.body(16.5, .semibold))
                Spacer()
                CircleIconButton(systemName: "xmark", size: 32, onCard2: true) {
                    model.closeSheet()
                }
                .accessibilityLabel(L.s("a11y_close"))
            }
            .padding(.horizontal, 16)
            .padding(.top, 6)
            .padding(.bottom, 8)

            // Sliding steps
            GeometryReader { geo in
                HStack(spacing: 0) {
                    stepPick.frame(width: geo.size.width)
                    stepTune.frame(width: geo.size.width)
                    stepReview.frame(width: geo.size.width)
                }
                .offset(x: -CGFloat(step) * geo.size.width)
                .animation(Motion.slide, value: step)
            }

            // CTA
            PrimaryButton(
                title: [L.s("log_cta_next"), L.s("log_cta_next"), L.s("log_cta_save")][step],
                enabled: canAdvance,
                height: 52
            ) { advance() }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                .padding(.bottom, 12)
        }
        .background(theme.bg)
        .presentationDetents([.height(742), .large])
        .presentationCornerRadius(26)
        .presentationDragIndicator(.hidden)
    }

    private var grabber: some View {
        Capsule()
            .fill(theme.line)
            .frame(width: 38, height: 5)
            .padding(.top, 9)
            .padding(.bottom, 2)
    }

    private func advance() {
        switch step {
        case 0:
            guard pickedName != nil else { return }
            withAnimation(Motion.slide) { step = 1 }
        case 1:
            costText = pickedCost > 0
                ? Formatters.trim(pickedCost)
                : String(Int((ml * 0.07).rounded()))
            whenIndex = 0
            withAnimation(Motion.slide) { step = 2 }
        default:
            guard let name = pickedName else { return }
            model.saveLog(
                name: name,
                ml: ml,
                abv: abv,
                quantity: quantity,
                cost: settings.askCost ? (Double(costText.replacingOccurrences(of: ",", with: ".")) ?? 0) : 0,
                hoursAgo: whenIndex
            )
        }
    }

    private func pick(name: String, abv newAbv: Double, ml newMl: Double, cost: Double) {
        Haptics.selection()
        withAnimation(Motion.fade) {
            pickedName = name
            abv = newAbv
            ml = newMl
            pickedCost = cost
            quantity = 1
            servingInMl = true
        }
    }

    // MARK: Step 0 — pick

    private var stepPick: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(L.s("log_pick_intro"))
                    .font(theme.fonts.body(14.5))
                    .foregroundStyle(theme.muted)
                    .lineSpacing(2)

                TextField(L.s("log_search_placeholder"), text: $query)
                    .font(theme.fonts.body(15.5))
                    .padding(.horizontal, 16)
                    .frame(height: 44)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(theme.surface2))
                    .padding(.top, 14)

                Button { model.openSheet(.customDrink) } label: {
                    HStack(spacing: 12) {
                        Text(verbatim: "+")
                            .font(theme.fonts.body(20, .medium))
                            .foregroundStyle(theme.accent)
                            .frame(width: 34, height: 34)
                            .background(RoundedRectangle(cornerRadius: 11, style: .continuous).fill(theme.surface2))
                        VStack(alignment: .leading, spacing: 1) {
                            Text(L.s("log_custom_title"))
                                .font(theme.fonts.body(15, .semibold))
                                .foregroundStyle(theme.text)
                            Text(L.s("log_custom_sub"))
                                .font(theme.fonts.body(12.5))
                                .foregroundStyle(theme.muted)
                        }
                        Spacer()
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(theme.surface)
                            .shadow(color: .black.opacity(0.04), radius: 7, y: 4)
                    )
                }
                .buttonStyle(PressScale(scale: 0.97))
                .padding(.top, 12)

                if !filteredSaved.isEmpty {
                    SectionCaption(L.s("log_section_your_drinks")).padding(.top, 16)
                    drinkGrid(items: filteredSaved.map {
                        GridDrink(name: $0.name, abv: $0.abv, ml: $0.ml, cost: $0.defaultCost, saved: true)
                    })
                    .padding(.top, 8)
                }

                SectionCaption(L.s("log_section_popular")).padding(.top, 16)
                drinkGrid(items: filteredPresets.map {
                    GridDrink(name: $0.name, abv: $0.abv, ml: $0.ml, cost: $0.cost, saved: false)
                })
                .padding(.top, 8)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    private struct GridDrink: Identifiable {
        let name: String
        let abv: Double
        let ml: Double
        let cost: Double
        let saved: Bool
        var id: String { name }
    }

    private func drinkGrid(items: [GridDrink]) -> some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible())], spacing: 10) {
            ForEach(Array(items.enumerated()), id: \.element.id) { i, item in
                let selected = pickedName == item.name
                Button {
                    pick(name: item.name, abv: item.abv, ml: item.ml, cost: item.cost)
                } label: {
                    VStack(alignment: .leading, spacing: 0) {
                        GlassIcon(abv: item.abv, width: 26, height: 33, liquid: item.saved ? theme.b1 : theme.accent)
                        Text(item.name)
                            .font(theme.fonts.body(14, .semibold))
                            .foregroundStyle(theme.text)
                            .lineLimit(1)
                            .padding(.top, 8)
                        Text(L.f("log_grid_meta", Formatters.trim(item.abv), Int(item.ml)))
                            .font(theme.fonts.body(12))
                            .foregroundStyle(theme.muted)
                            .padding(.top, 2)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(selected ? theme.surface2 : theme.surface)
                            .overlay(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .strokeBorder(selected ? theme.accent : .clear, lineWidth: 1.5)
                            )
                    )
                }
                .buttonStyle(PressScale(scale: 0.96))
                .riseIn(delay: Double(i) * 0.028)
                .accessibilityAddTraits(selected ? [.isSelected] : [])
            }
        }
    }

    // MARK: Step 1 — fine-tune

    private var mlDisplay: String {
        servingInMl
            ? L.f("log_serving_ml_value", Int(ml))
            : L.f("log_serving_oz_value", ml / AlcoholMath.mlPerFlOz)
    }

    private var stepTune: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text(L.s("log_tune_intro"))
                    .font(theme.fonts.body(14.5))
                    .foregroundStyle(theme.muted)
                    .lineSpacing(2)

                // ABV card
                VStack(alignment: .leading, spacing: 0) {
                    Text(L.s("log_abv_label"))
                        .font(theme.fonts.body(13, .semibold))
                        .foregroundStyle(theme.muted)
                    StepperRow(
                        display: L.f("log_abv_value", abv),
                        decrement: { abv = max(0.5, ((abv - 0.5) * 10).rounded() / 10) },
                        increment: { abv = min(96, ((abv + 0.5) * 10).rounded() / 10) }
                    )
                    .padding(.top, 10)
                    HStack(spacing: 8) {
                        ForEach([10.0, 14.0, 20.0], id: \.self) { v in
                            ValueChip(text: L.f("log_abv_value", v), selected: false) { abv = v }
                        }
                    }
                    .padding(.top, 12)
                }
                .padding(16)
                .card(radius: 20)
                .padding(.top, 14)

                // Serving card
                VStack(alignment: .leading, spacing: 0) {
                    HStack {
                        Text(L.s("log_serving_label"))
                            .font(theme.fonts.body(13, .semibold))
                            .foregroundStyle(theme.muted)
                        Spacer()
                        SegmentedPill(
                            options: [(true, ServingUnit.ml.shortLabel), (false, ServingUnit.oz.shortLabel)],
                            selection: $servingInMl,
                            fontSize: 12.5
                        )
                        .frame(width: 120)
                    }
                    StepperRow(
                        display: mlDisplay,
                        decrement: { ml = max(10, ml - 10) },
                        increment: { ml = min(1000, ml + 10) }
                    )
                    .padding(.top, 10)
                    HStack(spacing: 8) {
                        ForEach([120.0, 150.0, 240.0, 355.0], id: \.self) { v in
                            ValueChip(
                                text: servingInMl
                                    ? L.f("log_serving_ml_value", Int(v))
                                    : L.f("log_serving_oz_value", v / AlcoholMath.mlPerFlOz),
                                selected: false
                            ) { ml = v }
                        }
                    }
                    .padding(.top, 12)
                }
                .padding(16)
                .card(radius: 20)
                .padding(.top, 12)

                // Quantity card — half measures are first-class.
                VStack(alignment: .leading, spacing: 0) {
                    Text(L.s("log_quantity_label"))
                        .font(theme.fonts.body(13, .semibold))
                        .foregroundStyle(theme.muted)
                    HStack(spacing: 8) {
                        ForEach(quantityOptions, id: \.0) { value, label in
                            ValueChip(text: label, selected: quantity == value) { quantity = value }
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(16)
                .card(radius: 20)
                .padding(.top, 12)

                // Live result + derivation — where the accuracy persona
                // decides to trust us (brief P9).
                VStack(spacing: 5) {
                    Text(L.f(
                        "log_result_line",
                        AlcoholMath.units(ml: ml * quantity, abv: abv),
                        AlcoholMath.kcal(ml: ml * quantity, abv: abv),
                        UnitsConfig.current.noun(.plural)
                    ))
                        .font(theme.fonts.body(14))
                        .foregroundStyle(theme.muted)
                    Text(AlcoholMath.workingLine(ml: ml, abv: abv, quantity: quantity))
                        .font(theme.fonts.body(11.5))
                        .monospacedDigit()
                        .foregroundStyle(theme.faint)
                }
                .frame(maxWidth: .infinity)
                .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    // MARK: Step 2 — review & save

    private var stepReview: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                // Review card
                HStack(spacing: 16) {
                    GlassIcon(abv: abv, width: 42, height: 54)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pickedName ?? "")
                            .font(theme.fonts.display(18))
                        Text(reviewMeta)
                            .font(theme.fonts.body(13.5))
                            .foregroundStyle(theme.muted)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 0) {
                        Text(Formatters.units1(AlcoholMath.units(ml: ml * quantity, abv: abv)))
                            .font(theme.fonts.display(22))
                            .monospacedDigit()
                            .foregroundStyle(theme.accent)
                        Text(UnitsConfig.current.noun(.short))
                            .font(theme.fonts.body(11.5))
                            .foregroundStyle(theme.muted)
                    }
                }
                .padding(18)
                .card(radius: 20)

                // When — back-dating lives on the sheet, not a separate flow.
                VStack(alignment: .leading, spacing: 0) {
                    Text(L.s("log_when_label"))
                        .font(theme.fonts.body(13, .semibold))
                        .foregroundStyle(theme.muted)
                    HStack(spacing: 8) {
                        ForEach(Array([L.s("log_when_now"), L.s("log_when_1h"), L.s("log_when_2h")].enumerated()), id: \.offset) { i, label in
                            ValueChip(text: label, selected: whenIndex == i) { whenIndex = i }
                        }
                    }
                    .padding(.top, 10)
                }
                .padding(16)
                .card(radius: 20)
                .padding(.top, 12)

                if settings.askCost {
                    HStack {
                        Text(L.s("log_cost_label"))
                            .font(theme.fonts.body(15, .semibold))
                        Spacer()
                        HStack(spacing: 2) {
                            Text(L.f("log_cost_currency", CurrencyConfig.current.symbol))
                                .font(theme.fonts.display(18))
                                .foregroundStyle(theme.muted)
                            TextField(L.s("log_cost_placeholder"), text: $costText)
                                .keyboardType(.decimalPad)
                                .font(theme.fonts.display(17))
                                .monospacedDigit()
                                .multilineTextAlignment(.center)
                                .frame(width: 64, height: 38)
                                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(theme.surface2))
                        }
                    }
                    .padding(16)
                    .card(radius: 20)
                    .padding(.top, 12)
                }

                if settings.showCalories {
                    HStack {
                        Text(L.s("log_calories_label")).font(theme.fonts.body(15, .semibold))
                        Spacer()
                        Text(calorieDisplay)
                            .font(theme.fonts.body(15))
                            .monospacedDigit()
                            .foregroundStyle(theme.muted)
                    }
                    .padding(16)
                    .card(radius: 20)
                    .padding(.top, 12)
                }

                Text(model.dayOffset == 0
                    ? L.s("log_saved_to_today")
                    : L.f("log_saved_to_day", model.selectedDayTitle))
                    .font(theme.fonts.body(12.5))
                    .foregroundStyle(theme.faint)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 14)
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 16)
        }
        .scrollIndicators(.hidden)
    }

    private var reviewMeta: String {
        if quantity == 0.5 {
            return L.f("log_review_meta_half", Int(ml), Formatters.trim(abv))
        }
        if quantity == 1 {
            return L.f("log_review_meta", Int(ml), Formatters.trim(abv))
        }
        return L.f("log_review_meta_qty", Int(quantity), Int(ml), Formatters.trim(abv))
    }

    private var calorieDisplay: String {
        let kcal = AlcoholMath.kcal(ml: ml * quantity, abv: abv)
        return settings.energyUnit == .kcal
            ? L.f("log_calories_kcal", kcal)
            : L.f("log_calories_kj", Int((Double(kcal) * 4.184).rounded()))
    }
}
