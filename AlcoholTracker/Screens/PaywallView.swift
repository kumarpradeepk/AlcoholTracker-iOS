import SwiftUI
import UIKit

// MARK: - Paywall
//
// One screen, honest, dismissible. Shown on intent, never on launch and
// never mid-logging. Price stated plainly; trial converts to the chosen plan.

struct PaywallView: View {
    @Environment(\.theme) private var theme
    @ObservedObject var model: AppModel
    @ObservedObject var entitlements: EntitlementStore

    @State private var selectedPlan: String?
    @State private var expandedFAQ = -1

    /// The plan the card list has highlighted, or nothing until one arrives.
    ///
    /// Before the buyer touches anything the highlight falls on the plan with
    /// a free trial, then the yearly. Deliberately not "the dearest" — the
    /// trial is what the buyer would have chosen anyway, and pre-selecting a
    /// plan they did not pick is the kind of trick this app promised not to play.
    private var plan: ProPlan? {
        if let id = selectedPlan, let picked = entitlements.plans.first(where: { $0.id == id }) {
            return picked
        }
        return entitlements.plans.first { $0.hasTrial }
            ?? entitlements.plans.first { $0.cadence == .year }
            ?? entitlements.plans.first
    }

    /// Longest free trial anywhere in the offering; drives the FAQ wording.
    private var trialDays: Int {
        entitlements.plans.map(\.freeTrialDays).max() ?? 0
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        DropletMark(size: 40, breathing: false)
                            .padding(.leading, 4)
                            .padding(.top, 6)
                            .padding(.bottom, 20)

                        Text(L.s("pay_title"))
                            .font(.system(size: 29, weight: .bold))
                            .kerning(-0.5)
                        Text(L.s("pay_sub"))
                            .font(.system(size: 15.5))
                            .foregroundStyle(theme.sec)
                            .padding(.top, 6)

                        HStack(spacing: 8) {
                            Circle().fill(theme.moss).frame(width: 7, height: 7)
                            Text(L.s("pay_no_ads"))
                                .font(.system(size: 12.5, weight: .semibold))
                                .foregroundStyle(theme.moss)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(theme.mossSoft))
                        .padding(.top, 12)

                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(Array(PaywallContent.benefits.enumerated()), id: \.offset) { i, benefit in
                                HStack(spacing: 12) {
                                    Circle().fill(theme.tide).frame(width: 7, height: 7)
                                    Text(benefit).font(.system(size: 15))
                                }
                                .riseIn(delay: Double(i) * 0.045)
                            }
                        }
                        .padding(.top, 20)

                        comparisonTable
                            .padding(.top, 22)

                        planList
                            .padding(.top, 20)

                        Text(L.s("pay_faq_caption"))
                            .font(.system(size: 13, weight: .semibold))
                            .kerning(0.6)
                            .foregroundStyle(theme.ter)
                            .padding(.top, 22)

                        faqCard
                            .padding(.top, 8)
                            .padding(.bottom, 8)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 74)
                    .padding(.bottom, 10)
                }
                .scrollIndicators(.hidden)

                // Sticky CTA
                VStack(spacing: 0) {
                    PrimaryButton(title: PaywallContent.cta(for: plan)) { buy() }
                        .disabled(plan == nil || entitlements.purchaseInFlight)
                        .opacity(plan == nil || entitlements.purchaseInFlight ? 0.45 : 1)
                    if let sub = PaywallContent.subCopy(for: plan) {
                        Text(sub)
                            .font(.system(size: 12.5))
                            .foregroundStyle(theme.sec)
                            .multilineTextAlignment(.center)
                            .padding(.top, 9)
                    }
                    HStack(spacing: 24) {
                        footerLink(L.s("pay_restore")) {
                            Task {
                                let restored = await entitlements.restore()
                                model.showToast(restored
                                    ? L.s("toast_restore_success")
                                    : L.s("toast_restore_none"))
                            }
                        }
                        footerLink(L.s("pay_terms")) { openURL("https://alcoholtracker.app/terms") }
                        footerLink(L.s("pay_privacy")) { openURL("https://alcoholtracker.app/privacy") }
                    }
                    .padding(.top, 11)
                }
                .padding(.horizontal, 22)
                .padding(.bottom, 12)
                .background(
                    LinearGradient(
                        colors: [theme.bg.opacity(0), theme.bg],
                        startPoint: .top, endPoint: UnitPoint(x: 0.5, y: 0.26)
                    )
                    .ignoresSafeArea(edges: .bottom)
                )
            }

            CircleIconButton(systemName: "xmark", size: 34, onCard2: true) {
                withAnimation(Motion.rise) { model.paywallShown = false }
            }
            .padding(.trailing, 18)
            .padding(.top, 14)
            .accessibilityLabel(L.s("a11y_close"))
        }
        .background(theme.bg.ignoresSafeArea())
        .riseIn()
    }

    // MARK: pieces

    private var comparisonTable: some View {
        VStack(spacing: 0) {
            HStack {
                Text(L.s("pay_compare_caption")).frame(maxWidth: .infinity, alignment: .leading)
                Text(L.s("pay_compare_free")).frame(width: 44)
                Text(L.s("pay_compare_pro")).frame(width: 44)
            }
            .font(.system(size: 11, weight: .semibold))
            .kerning(0.6)
            .foregroundStyle(theme.ter)
            .padding(.vertical, 10)

            ForEach(Array(PaywallContent.comparison.enumerated()), id: \.offset) { _, row in
                HStack {
                    Text(row.0)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(row.1 ? "✓" : "·")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(row.1 ? theme.moss : theme.ter)
                        .frame(width: 44)
                    Text(row.2 ? "✓" : "·")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(theme.tide)
                        .frame(width: 44)
                }
                .padding(.vertical, 10)
                .overlay(alignment: .top) { Rectangle().fill(theme.hair).frame(height: 0.5) }
            }
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
        .card(radius: 20)
    }

    /// Plans, exactly as the store priced them today. Three states, because
    /// "we could not reach the App Store" is a different sentence from
    /// "one moment" and the buyer deserves the right one.
    @ViewBuilder private var planList: some View {
        if !entitlements.plans.isEmpty {
            VStack(spacing: 10) {
                ForEach(entitlements.plans) { planRow($0) }
            }
        } else if entitlements.loaded {
            VStack(alignment: .leading, spacing: 10) {
                Text(L.s("pay_unavailable"))
                    .font(.system(size: 14))
                    .foregroundStyle(theme.sec)
                Button(L.s("pay_retry")) { Task { await entitlements.refresh() } }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(theme.tide)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(L.s("pay_loading"))
                .font(.system(size: 14))
                .foregroundStyle(theme.ter)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func planRow(_ plan: ProPlan) -> some View {
        let selected = self.plan?.id == plan.id
        return Button {
            Haptics.selection()
            withAnimation(Motion.fade) { selectedPlan = plan.id }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .strokeBorder(selected ? theme.tide : theme.hair, lineWidth: 1.5)
                        .background(Circle().fill(selected ? theme.tide : .clear))
                        .frame(width: 22, height: 22)
                    if selected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                VStack(alignment: .leading, spacing: 1) {
                    Text(PaywallContent.planName(plan.cadence))
                        .font(.system(size: 16, weight: .semibold))
                    Text(PaywallContent.priceLine(plan))
                        .font(.system(size: 13))
                        .foregroundStyle(theme.sec)
                }
                Spacer()
                if let badge = PaywallContent.badge(plan) {
                    Text(badge.text)
                        .font(.system(size: 10, weight: .bold))
                        .kerning(0.5)
                        .foregroundStyle(badge.good ? theme.moss : theme.amber)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(badge.good ? theme.mossSoft : theme.amberSoft)
                        )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(selected ? theme.tideSoft : theme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .strokeBorder(selected ? theme.tide : .clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PressScale(scale: 0.98))
        .accessibilityAddTraits(selected ? [.isSelected] : [])
    }

    private var faqCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(PaywallContent.faq(trialDays: trialDays).enumerated()), id: \.offset) { i, qa in
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(Motion.slide) { expandedFAQ = expandedFAQ == i ? -1 : i }
                    } label: {
                        HStack {
                            Text(qa.0)
                                .font(.system(size: 14.5, weight: .medium))
                                .foregroundStyle(theme.ink)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(theme.ter)
                                .rotationEffect(.degrees(expandedFAQ == i ? 45 : 0))
                                .animation(Motion.pop, value: expandedFAQ)
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)

                    if expandedFAQ == i {
                        Text(qa.1)
                            .font(.system(size: 13.5))
                            .foregroundStyle(theme.sec)
                            .lineSpacing(3)
                            .padding(.top, 8)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
                .padding(.vertical, 12)
                .overlay(alignment: .top) {
                    if i > 0 { Rectangle().fill(theme.hair).frame(height: 0.5) }
                }
            }
        }
        .padding(.horizontal, 16)
        .card(radius: 20)
    }

    private func footerLink(_ title: String, action: @escaping () -> Void) -> some View {
        Button(title, action: action)
            .font(.system(size: 13))
            .foregroundStyle(theme.ter)
    }

    private func buy() {
        guard let plan else {
            model.showToast(L.s("toast_purchase_unavailable"))
            return
        }
        Task {
            // A cancelled sheet is not a failure and gets no toast; the buyer
            // knows perfectly well what they just tapped.
            if await entitlements.purchase(plan) {
                withAnimation(Motion.rise) { model.paywallShown = false }
                model.showToast(L.s("toast_pro_welcome"))
            }
        }
    }

    private func openURL(_ string: String) {
        if let url = URL(string: string) {
            UIApplication.shared.open(url)
        }
    }
}
