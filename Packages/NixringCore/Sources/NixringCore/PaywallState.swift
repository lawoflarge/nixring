import Foundation

/// The App Store Connect product IDs, in one place so the paywall, the store client and the
/// tests cannot drift apart.
public enum NixringProduct {
    public static let weekly = "com.levinschwab.nixring.weekly"
    public static let yearly = "com.levinschwab.nixring.yearly"
    public static let all = [weekly, yearly]
    /// Display order on the paywall — the trial plan leads.
    public static let displayOrder = [weekly, yearly]
}

/// How far `SubscriptionManager.loadProducts()` has got.
///
/// Deliberately separate from "do we have products": `Product.products(for:)` does **not** throw
/// for IDs the App Store doesn't know — it silently omits them and returns success. A finished
/// load is therefore not the same thing as a sellable catalogue.
public enum StoreLoadPhase: Equatable {
    case idle
    case loading
    case loaded
    case failed
}

/// What the paywall should put on screen.
public enum PaywallState: Equatable {
    case loading
    /// Nothing is sellable — show a retry, never a price or a buy button.
    case unavailable
    case ready(plans: [String], selected: String)
}

public enum PaywallStateResolver {
    /// - Parameters:
    ///   - loadedIDs: product IDs StoreKit actually returned.
    ///   - preferred: the user's current pick; falls back to the first sellable plan.
    ///   - order: product IDs in display order. Anything not in `loadedIDs` is dropped.
    public static func resolve(phase: StoreLoadPhase,
                               loadedIDs: [String],
                               preferred: String,
                               order: [String]) -> PaywallState {
        let plans = order.filter { loadedIDs.contains($0) }
        guard let first = plans.first else {
            return (phase == .idle || phase == .loading) ? .loading : .unavailable
        }
        return .ready(plans: plans, selected: plans.contains(preferred) ? preferred : first)
    }
}
