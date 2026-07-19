import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var selected = SubscriptionManager.weeklyID

    private var subs: SubscriptionManager { model.subs }

    var body: some View {
        ScrollView {
            VStack(spacing: 22) {
                header
                featureList
                planCards
                ctaButton
                disclosure
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

    private var planCards: some View {
        VStack(spacing: 12) {
            planCard(id: SubscriptionManager.weeklyID, title: "Weekly",
                     price: subs.weekly?.displayPrice ?? "$4.99", period: "/week",
                     subtitle: "3-day free trial, then billed weekly", badge: nil)
            planCard(id: SubscriptionManager.yearlyID, title: "Yearly",
                     price: subs.yearly?.displayPrice ?? "$29.99", period: "/year",
                     subtitle: "Billed annually", badge: "SAVE 88%")
        }
    }

    private func planCard(id: String, title: String, price: String, period: String, subtitle: String, badge: String?) -> some View {
        let isSelected = selected == id
        return Button { selected = id } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(title).font(.headline).foregroundStyle(Palette.textPrimary)
                        if let badge {
                            Text(badge).font(.caption2.weight(.heavy))
                                .padding(.horizontal, 6).padding(.vertical, 2)
                                .background(Palette.accent.opacity(0.2), in: Capsule())
                                .foregroundStyle(Palette.accent)
                        }
                    }
                    Text(subtitle).font(.footnote).foregroundStyle(Palette.textSecondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(price).font(.headline).foregroundStyle(Palette.textPrimary)
                    Text(period).font(.caption).foregroundStyle(Palette.textSecondary)
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

    private var ctaButton: some View {
        PrimaryButton(title: subs.isPurchasing ? "Please wait…" : ctaTitle) {
            Task { await purchaseSelected() }
        }
    }

    private var ctaTitle: String {
        selected == SubscriptionManager.weeklyID ? "Start 3-day free trial" : "Unlock Nixring Pro"
    }

    private func purchaseSelected() async {
        guard let product = subs.products.first(where: { $0.id == selected }) else { return }
        await model.purchase(product)
    }

    private var disclosure: some View {
        Text("Payment is charged to your Apple Account at confirmation. The subscription renews automatically unless canceled at least 24 hours before the end of the current period. Manage or cancel any time in App Store settings. Any unused portion of a free trial is forfeited when you buy a subscription.")
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
