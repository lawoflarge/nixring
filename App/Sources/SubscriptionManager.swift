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

    func refreshEntitlements() async {
        var pro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result,
               productIDs.contains(t.productID),
               t.revocationDate == nil {
                pro = true
            }
        }
        isPro = pro
    }
}
