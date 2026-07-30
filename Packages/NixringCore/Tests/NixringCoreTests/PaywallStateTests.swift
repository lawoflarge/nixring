import XCTest
@testable import NixringCore

/// Regression tests for the defect that shipped in 1.0: the subscriptions were never approved,
/// `Product.products(for:)` therefore returned an empty array *without throwing*, and the paywall
/// rendered hardcoded prices over a buy button that silently did nothing.
final class PaywallStateTests: XCTestCase {

    private let weekly = NixringProduct.weekly
    private let yearly = NixringProduct.yearly

    private func resolve(_ phase: StoreLoadPhase,
                         _ loaded: [String],
                         preferred: String? = nil) -> PaywallState {
        PaywallStateResolver.resolve(phase: phase,
                                     loadedIDs: loaded,
                                     preferred: preferred ?? NixringProduct.weekly,
                                     order: NixringProduct.displayOrder)
    }

    func testIdleWithoutProductsIsLoading() {
        XCTAssertEqual(resolve(.idle, []), .loading)
    }

    func testLoadingWithoutProductsIsLoading() {
        XCTAssertEqual(resolve(.loading, []), .loading)
    }

    /// The actual 1.0 bug: the fetch succeeds, returns nothing, and we must not pretend to sell.
    func testLoadedWithoutProductsIsUnavailable() {
        XCTAssertEqual(resolve(.loaded, []), .unavailable)
    }

    func testFailedWithoutProductsIsUnavailable() {
        XCTAssertEqual(resolve(.failed, []), .unavailable)
    }

    func testLoadedWithBothProductsKeepsDisplayOrderAndPreferredSelection() {
        XCTAssertEqual(resolve(.loaded, [yearly, weekly]),
                       .ready(plans: NixringProduct.displayOrder, selected: weekly))
    }

    func testPreferredSelectionIsHonouredWhenAvailable() {
        XCTAssertEqual(resolve(.loaded, [yearly, weekly], preferred: yearly),
                       .ready(plans: NixringProduct.displayOrder, selected: yearly))
    }

    /// Only one of the two subscriptions got approved — sell that one, don't dead-end the paywall.
    func testPartialCatalogueFallsBackToAnAvailablePlan() {
        XCTAssertEqual(resolve(.loaded, [yearly], preferred: weekly),
                       .ready(plans: [yearly], selected: yearly))
    }

    /// A refresh must not blank out a paywall that already has something to show.
    func testReloadingWithProductsAlreadyLoadedStaysReady() {
        XCTAssertEqual(resolve(.loading, [weekly, yearly]),
                       .ready(plans: NixringProduct.displayOrder, selected: weekly))
    }

    func testUnknownIDsInTheStoreResponseAreIgnored() {
        XCTAssertEqual(resolve(.loaded, [weekly, "com.levinschwab.nixring.lifetime"]),
                       .ready(plans: [weekly], selected: weekly))
    }

    func testProductIDsMatchAppStoreConnect() {
        XCTAssertEqual(NixringProduct.weekly, "com.levinschwab.nixring.weekly")
        XCTAssertEqual(NixringProduct.yearly, "com.levinschwab.nixring.yearly")
        XCTAssertEqual(NixringProduct.all.count, 2)
        XCTAssertEqual(Set(NixringProduct.displayOrder), Set(NixringProduct.all))
    }
}
