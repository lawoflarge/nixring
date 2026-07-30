import SwiftUI
import StoreKit
import NixringCore

struct PaywallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var selected = SubscriptionManager.weeklyID

    private var subs: SubscriptionManager { model.subs }
    private var state: PaywallState { subs.paywallState(preferred: selected) }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                featureList

                switch state {
                case .loading:
                    loadingBlock
                case .unavailable:
                    unavailableBlock
                case .ready(let plans, let active):
                    planCards(plans: plans, active: active)
                    ctaButton(active: active)
                    disclosure(plans: plans)
                }

                if let message = subs.errorMessage {
                    Text(message)
                        .font(.footnote).foregroundStyle(Palette.danger)
                        .multilineTextAlignment(.center)
                }

                footerLinks
            }
            .padding(22)
            .padding(.top, 28)
        }
        .background(Palette.bg.ignoresSafeArea())
        .overlay(alignment: .topTrailing) {
            Button { dismiss() } label: {
                Image(systemName: "xmark.circle.fill").font(.title2).foregroundStyle(Palette.textMuted)
            }
            .padding()
        }
        .task { if subs.products.isEmpty { await subs.loadProducts() } }
        .onChange(of: model.isPro) { _, isPro in if isPro { dismiss() } }
    }

    private var header: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle().fill(Palette.shieldGlow).frame(width: 150, height: 150)
                Image(systemName: "checkmark.shield.fill")
                    .font(.system(size: 54, weight: .bold)).foregroundStyle(Palette.accentGradient)
            }
            Text("Nixring Pro")
                .font(.system(size: 28, weight: .bold, design: .rounded)).foregroundStyle(Palette.textPrimary)
            Text("Full protection. One fair price. Nothing leaves your phone.")
                .font(.subheadline).foregroundStyle(Palette.textSecondary).multilineTextAlignment(.center)
        }
    }

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            feature("infinity", "Unlimited blocked numbers")
            feature("message.badge.filled.fill", "Junk & scam text filtering")
            feature("arrow.triangle.2.circlepath", "Auto-updating spam blocklist")
            feature("slider.horizontal.3", "Prefix & range rules")
            feature("checkmark.seal.fill", "Whitelist real callers")
            feature("chart.bar.fill", "Full protection stats")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func feature(_ icon: String, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon).foregroundStyle(Palette.accent).frame(width: 26)
            Text(text).foregroundStyle(Palette.textPrimary)
            Spacer()
        }
    }

    // MARK: states

    private var loadingBlock: some View {
        VStack(spacing: 10) {
            ProgressView().tint(Palette.accent)
            Text("Loading plans…").font(.footnote).foregroundStyle(Palette.textSecondary)
        }
        .padding(.vertical, 32)
    }

    /// Reached whenever the App Store hands back no sellable product — offline, no App Store
    /// account, or the subscriptions simply aren't live. Never fake a price here.
    private var unavailableBlock: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Plans unavailable", systemImage: "exclamationmark.triangle.fill")
                .font(.headline).foregroundStyle(Palette.textPrimary)
            Text("Nixring couldn't load any plans from the App Store. Check your connection and try again — nothing is charged until you pick a plan.")
                .font(.footnote).foregroundStyle(Palette.textSecondary)
            Button {
                Task { await subs.loadProducts() }
            } label: {
                Label("Try again", systemImage: "arrow.clockwise")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity).padding(.vertical, 12)
            }
            .buttonStyle(.plain)
            .background(Palette.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(Palette.stroke))
            .foregroundStyle(Palette.accent)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(Palette.stroke))
    }

    private func planCards(plans: [String], active: String) -> some View {
        VStack(spacing: 12) {
            ForEach(plans, id: \.self) { id in
                planCard(id: id, isSelected: id == active)
            }
        }
    }

    @ViewBuilder
    private func planCard(id: String, isSelected: Bool) -> some View {
        if let product = subs.products.first(where: { $0.id == id }) {
            let weekly = id == SubscriptionManager.weeklyID
            Button { selected = id } label: {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text(weekly ? "Weekly" : "Yearly")
                                .font(.headline).foregroundStyle(Palette.textPrimary)
                            if !weekly {
                                Text("SAVE 88%").font(.caption2.weight(.heavy))
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Palette.accent.opacity(0.2), in: Capsule())
                                    .foregroundStyle(Palette.accent)
                            }
                        }
                        Text(weekly ? "3-day free trial, then billed weekly" : "Billed annually")
                            .font(.footnote).foregroundStyle(Palette.textSecondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(product.displayPrice).font(.headline).foregroundStyle(Palette.textPrimary)
                        Text(weekly ? "/week" : "/year").font(.caption).foregroundStyle(Palette.textSecondary)
                    }
                    Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                        .foregroundStyle(isSelected ? Palette.accent : Palette.textMuted)
                }
                .padding(16)
                .background(Palette.surface, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Palette.accent : Palette.stroke, lineWidth: isSelected ? 2 : 1))
            }
        }
    }

    private func ctaButton(active: String) -> some View {
        PrimaryButton(title: subs.isPurchasing ? "Please wait…" : ctaTitle(for: active),
                      enabled: !subs.isPurchasing) {
            Task { await purchase(active) }
        }
    }

    private func ctaTitle(for active: String) -> String {
        active == SubscriptionManager.weeklyID ? "Start 3-day free trial" : "Unlock Nixring Pro"
    }

    private func purchase(_ id: String) async {
        guard let product = subs.products.first(where: { $0.id == id }) else { return }
        await model.purchase(product)
    }

    private func disclosure(plans: [String]) -> some View {
        var text = "Payment is charged to your Apple Account at confirmation. The subscription renews automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel any time in App Store settings."
        if plans.contains(SubscriptionManager.weeklyID) {
            text += " Any unused portion of a free trial is forfeited when you buy a subscription."
        }
        return Text(text)
            .font(.caption2).foregroundStyle(Palette.textMuted).multilineTextAlignment(.center)
    }

    private var footerLinks: some View {
        HStack(spacing: 18) {
            Button("Restore") { Task { await model.restore() } }
            Link("Terms", destination: AppLinks.terms)
            Link("Privacy", destination: AppLinks.privacy)
        }
        .font(.footnote).foregroundStyle(Palette.textSecondary)
    }
}
