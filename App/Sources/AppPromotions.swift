import CrossPromotionCore
import CrossPromotionUI
import SwiftUI

@MainActor
enum AppPromotions {
    static func makeStore() -> PromotionStore? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "CrossPromotionBaseURL") as? String,
              let url = URL(string: value), url.scheme == "https", url.host != nil,
              url.user == nil, url.password == nil else { return nil }
        return PromotionStore(
            source: PromotionIdentity(appStoreID: "6792562928", bundleID: "com.levinschwab.nixring"),
            baseURL: url,
            eventsEnabled: true
        )
    }
}

@MainActor
struct AppPromotionSection: View {
    let store: PromotionStore
    let viewport: CGRect
    @Environment(\.openURL) private var openURL
    @State private var openFailed = false

    var body: some View {
        Group {
            if !store.promotions.isEmpty {
                Section { rows } header: { Text(String(localized: "More apps", table: "CrossPromotion")) }
                .listRowBackground(Palette.surface)
            }
        }
        .tint(Palette.accent)
        .alert(String(localized: "Could not open the App Store. Please try again.", table: "CrossPromotion"), isPresented: $openFailed) {
            Button(String(localized: "OK", table: "CrossPromotion"), role: .cancel) { }
        }
    }

    private var rows: some View {
        ForEach(store.promotions) { promotion in
            CrossPromotionRow(
                promotion: promotion,
                appStoreActionTitle: String(localized: "View in App Store", table: "CrossPromotion"),
                style: .init(titleFont: .system(.headline, design: .rounded), benefitFont: .subheadline, actionFont: .caption.weight(.semibold), titleColor: Palette.textPrimary, benefitColor: Palette.textSecondary)
            ) {
                CrossPromotionIcon(promotion.iconURL)
            } onSelect: { selected in
                openURL(selected.appStoreURL) { accepted in
                    if accepted { store.recordClick(selected) } else { openFailed = true }
                }
            }
            .promotionImpression(promotion, store: store, viewport: openFailed ? .zero : viewport)
        }
    }
}
