import Foundation
import StoreKit
import Observation

/// Native StoreKit 2 subscription manager. No RevenueCat, no server — entitlement is read
/// straight from `Transaction.currentEntitlements`. Owning either product grants Pro.
@Observable
@MainActor
final class SubscriptionManager {
    static let weeklyID = "com.levinschwab.nixring.weekly"
    static let yearlyID = "com.levinschwab.nixring.yearly"
    var productIDs: [String] { [Self.weeklyID, Self.yearlyID] }

    private(set) var products: [Product] = []
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
        do {
            let loaded = try await Product.products(for: productIDs)
            products = loaded.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Couldn't load subscription options."
        }
    }

    func purchase(_ product: Product) async {
        isPurchasing = true
        defer { isPurchasing = false }
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    await refreshEntitlements()
                }
            case .userCancelled, .pending:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        try? await AppStore.sync()
        await refreshEntitlements()
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
