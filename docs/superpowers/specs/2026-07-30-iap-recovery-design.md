# Nixring 1.0.1 — In-App-Purchase Recovery

**Date:** 2026-07-30
**Status:** implemented

## Problem

Nixring 1.0 is live (`READY_FOR_SALE`) but nobody can buy Nixring Pro.

Two independent faults stack:

1. **App Store Connect.** Both subscriptions (`com.levinschwab.nixring.weekly`, `…yearly`) sit at
   `READY_TO_SUBMIT`, and both `subscriptionVersion` resources are `DEVELOPER_REJECTED`. The
   2026-07-20 review submission carried the app version *and* the subscriptions; every
   subscription item ended up `REMOVED`, and the 2026-07-21 submission that actually got approved
   contained the app version alone. The products were therefore never approved and do not exist in
   the production App Store.

2. **The app.** `Product.products(for:)` does not throw for product IDs the App Store doesn't
   know — it silently omits them and returns success. `SubscriptionManager.loadProducts()` treated
   that as a normal load (its `catch` never ran, so `errorMessage` stayed `nil`), and `PaywallView`
   rendered hardcoded fallback prices (`?? "$4.99"`) above a CTA whose action was
   `guard let product = … else { return }`. With no product, the button did nothing at all: no
   error, no explanation, no retry.

The second fault is what turned a fixable store problem into a dead paywall. It is also why the
defect never showed up in development: the Simulator talks to the **sandbox** environment, and
sandbox serves subscriptions that have not been approved yet. Sandbox is not a proxy for
production here.

## Design

### Store availability is a first-class state

`NixringCore/PaywallState.swift` adds pure, testable pieces:

- `NixringProduct` — the product IDs, so the paywall, the store client and the tests cannot drift.
- `StoreLoadPhase` — `idle | loading | loaded | failed`. Kept separate from "do we have products",
  because a finished load is not the same thing as a sellable catalogue.
- `PaywallState` — `loading | unavailable | ready(plans:selected:)`.
- `PaywallStateResolver.resolve(phase:loadedIDs:preferred:order:)` — drops any plan StoreKit did
  not return, keeps display order, and falls back to the first sellable plan when the user's
  preferred plan is missing (so a partially approved catalogue still sells).

It lives in `NixringCore` because the app target has no test bundle; `NixringCoreTests` is where
this logic can be covered.

`SubscriptionManager` tracks `phase`, exposes `paywallState(preferred:)`, and surfaces purchase
and restore failures instead of swallowing them.

### The paywall never lies

- `ready` renders only plans that actually loaded, with real `displayPrice` values. No fallbacks.
- `unavailable` renders "Plans unavailable" plus a **Try again** button. No price, no buy button.
- `loading` renders a spinner.
- Restore, Terms and Privacy stay reachable in every state (App Review requires the first).

### Shipping

Version 1.0.1 (build 4). The first subscription of an app must be reviewed together with an app
version, so the review submission carries `appStoreVersion` + `subscriptionGroupVersion` +
both `subscriptionVersion` items.

## Testing

`NixringCoreTests/PaywallStateTests.swift` covers the resolver, including the exact 1.0 failure
(`loaded` + empty catalogue must be `unavailable`, never a priced plan) and a guard that the
product IDs still match App Store Connect. Both states were verified in the Simulator by
temporarily pointing the product IDs at non-existent products.
