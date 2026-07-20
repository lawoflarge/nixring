# Nixring — Build Progress

## 🟢 SUBMITTED 2026-07-20 — version 1.0 + both subs = WAITING_FOR_REVIEW (AFTER_APPROVAL)
First-sub-with-version cracked via API: `POST /v1/reviewSubmissionItems` with a **`subscriptionVersion`**
relationship (item-type 18) per sub — the sub's version from `GET /v1/subscriptions/{id}/versions`,
NOT `subscription` (409) — into the version's reviewSubmission `d2a320a4`, then `asc review
submissions-submit --confirm`. Bundle: appStoreVersion(6) + subscriptionGroupVersion(19) + 2×subscriptionVersion(18).

**App:** Nixring — privacy-first spam call + junk SMS blocker (iOS 17+, SwiftUI)
**Repo:** lawoflarge/nixring (private) · **ASC App ID:** 6792562928 · **Team:** R95M36AU2X
Canonical identifiers → `.nixring-ids.env`

## STATUS: fully prepared, 0 blocking issues. Waiting on final web-gates (§14b/§14c) + review phone.

### ✅ DONE (autonomous)
- Market research (8 competitors) + naming: **Nixring** (verified free) → docs/
- ASC app record + 3 bundle IDs + App Group (assigned to all 3, verified in profile)
- NixringCore Swift package — **42 unit tests, all passing**
- Bundled blocklist (80 entries) + public auto-update repo (nixring-blocklist)
- Call Directory + Message Filter extensions (thin consumers of tested core)
- Full SwiftUI app: onboarding, home, blocklist/whitelist/rules, settings, diagnostics, StoreKit 2 paywall
- Designed geometric app icon (navy + cyan shield); UI verified in Simulator
- Provisioning profiles (App Store) — app-group entitlement confirmed
- **Build 1 archived (manual signing) + uploaded + VALID + attached to version 1.0**
- 5 App Store screenshots (1290×2796, thumbnail-readable) uploaded (IPHONE_67)
- Metadata: description, keywords, subtitle, promo text, support/marketing/privacy URLs
- Categories: Utilities / Productivity · Age rating (all NONE, advertising false)
- Copyright, contentRightsDeclaration, releaseType **AFTER_APPROVAL**
- App availability: **all 175 territories** (+ auto new territories)
- Pricing: weekly $4.99/€4.99/£4.49 (+3-day trial), yearly $29.99/€29.99/£27.99 — **€5.99 trap fixed**, 175/175
- Both subscriptions **READY_TO_SUBMIT** (group + sub localizations, review screenshots)
- Review details set (contact + reviewer notes) — ⚠️ PLACEHOLDER PHONE (+4915120000000)
- `asc review doctor` → **errors: 0, blocking: 0**

### 🔴 REMAINING — final human web-gates (need Levin + warm/2FA session)
- [ ] §14b **App Privacy publish** → declare "Data Not Collected", then Publish
- [ ] §14c **Attach both subs to version + Submit for Review** (2.1b-critical)
- [ ] Replace placeholder **review-contact phone** with Levin's real number
- [ ] Verify: version WAITING_FOR_REVIEW + both subs WAITING_FOR_REVIEW → done

## Key IDs
- App 6792562928 · Version 5c9b1f31-31f1-4cae-b20a-6bcfa24b1e63 (1.0, PREPARE_FOR_SUBMISSION)
- Build 89f09212-34ec-43f8-be18-97ac9c34485b (VALID, attached)
- Subs: weekly 6792570002 · yearly 6792569920 (both READY_TO_SUBMIT) · group 22249248
- Dist cert 2NSZGQ4M26 · profiles: main Y364XW6V36 / calldir L9V4D7KBQR / smsfilter 923XS2NQKT
- Review detail 9a436362-43af-48d9-9915-f82b359871d6

## Driver
`asc-main` Chromium kept alive by browser-automation/spamblock-asc-serve.mjs (CDP :9222).
IMPORTANT: keep ONE tab on the Nixring app (6792562928); stray tabs caused drift to another
app (Nixly 6792568860). Use nixring-tabs.mjs to clean tabs before CDP work.
