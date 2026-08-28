import Foundation
import StoreKit
import Observation
import NixringCore

/// Native StoreKit 2 subscription manager. No RevenueCat, no server — entitlement is read
/// straight from `Transaction.currentEntitlements`. Owning either product grants Pro.
@Observable
@MainActor
final class SubscriptionManager {
    nonisolated static let weeklyID = NixringProduct.weekly
    nonisolated static let yearlyID = NixringProduct.yearly
    var productIDs: [String] { NixringProduct.all }

    private(set) var products: [Product] = []
    private(set) var phase: StoreLoadPhase = .idle
    private(set) var isPro = false

    /// Whether the first entitlement check has answered. Before it has, `isPro`
    /// is false for subscribers too, so anything that would treat a paying user
    /// differently has to wait for this instead of reading `isPro` straight away.
    private(set) var hasLoaded = false

    var isPurchasing = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?

    init() {
        updatesTask = Task { [weak self] in
            for await update in Transaction.updates {
                if case .verified(let t) = update { await t.finish() }
                await self?.refreshEntitlements()
            }
        }
    }
    deinit { updatesTask?.cancel() }

    var weekly: Product? { products.first { $0.id == Self.weeklyID } }
    var yearly: Product? { products.first { $0.id == Self.yearlyID } }

    func loadProducts() async {
        if products.isEmpty { phase = .loading }
        do {
            let loaded = try await Product.products(for: productIDs)
            products = loaded.sorted { $0.price < $1.price }
            phase = .loaded
        } catch {
            products = []
            phase = .failed
        }
    }

    /// Paywall state derived from what the App Store actually returned.
    func paywallState(preferred: String) -> PaywallState {
        PaywallStateResolver.resolve(phase: phase,
                                     loadedIDs: products.map(\.id),
                                     preferred: preferred,
                                     order: NixringProduct.displayOrder)
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        errorMessage = nil
        defer { isPurchasing = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                } else {
                    errorMessage = "That purchase couldn't be verified. Please try again."
                }
            case .pending:
                errorMessage = "Your purchase is waiting for approval."
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        errorMessage = nil
        do {
            try await AppStore.sync()
            await refreshEntitlements()
            if !isPro { errorMessage = "No active Nixring Pro subscription on this Apple Account." }
        } catch StoreKitError.userCancelled {
            // Nothing to say — the user backed out of the App Store prompt.
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Reads the entitlement, and reads it the way a subscription has to be read.
    ///
    /// A receipt that exists is not a licence. Three cases have to come apart:
    ///
    /// - Cancelled but still inside the period that was paid for. Auto renew is
    ///   off, `expirationDate` is in the future, and this is still Pro. Turning
    ///   ads back on the moment somebody cancels would be taking away what they
    ///   already paid for.
    /// - Expired. `expirationDate` has passed and the App Store is not retrying.
    ///   Not Pro, so the free version with its advertising comes back.
    /// - In a grace period. The renewal failed, the App Store is retrying, and
    ///   Apple's own guidance is to keep the subscription working meanwhile.
    ///   `expirationDate` is already in the past here, which is exactly why the
    ///   date alone cannot decide it and the renewal state has to be asked.
    func refreshEntitlements() async {
        defer { hasLoaded = true }
        var pro = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let t) = result,
                  productIDs.contains(t.productID),
                  t.revocationDate == nil
            else { continue }

            if let expiry = t.expirationDate, expiry <= Date() {
                guard await isInGracePeriod(groupID: t.subscriptionGroupID) else { continue }
            }
            pro = true
        }
        isPro = pro
    }

    /// True while the App Store is still retrying a failed renewal inside the
    /// grace period that was granted for this subscription group.
    private func isInGracePeriod(groupID: String?) async -> Bool {
        guard let groupID,
              let statuses = try? await Product.SubscriptionInfo.status(for: groupID)
        else { return false }
        return statuses.contains { $0.state == .inGracePeriod }
    }
}
