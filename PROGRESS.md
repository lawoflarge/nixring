# Nixring — Build Progress

**App:** Nixring — privacy-first spam call + junk SMS blocker (iOS, SwiftUI, iOS 17+)
**Repo:** lawoflarge/nixring (private) · **Local:** ~/Data/Claude/nixring
**ASC App ID:** 6792562928 · **Team:** R95M36AU2X

## Canonical identifiers → see `.nixring-ids.env`

## Status legend: ✅ done · 🔄 in progress · ⬜ todo · 🔴 blocked (needs Levin)

### Phase 0 — Research & ASC setup
- ✅ Market research (8 competitors, workflow) → `docs/market-research.md`
- ✅ Naming: **Nixring** (verified free US+DE) → `docs/naming.md`
- ✅ App record created (ASC New App form, CDP): id 6792562928, "Nixring: Spam Call Blocker"
- ✅ 3 bundle IDs: main 79RM8Q68ZS · calldir J5VC4JTD85 · smsfilter 78Y6Y592BX
- ✅ App Groups capability on all 3 (API)
- ✅ App Group `group.com.levinschwab.nixring` created + assigned to all 3 (portal, CDP)

### Phase 1 — Code (TDD core → extensions → app)
- ⬜ NixringCore Swift package: models + phone-number normalization + Int64/CallKit list gen + SMS rule engine + App-Group JSON store + merge logic (unit-tested)
- ⬜ Bundled base blocklist JSON (DE/EU prefixes + known spam)
- ⬜ Call Directory Extension (CXCallDirectoryProvider)
- ⬜ Message Filter Extension (ILMessageFilterExtension, offline rule engine)
- ⬜ SwiftUI app: onboarding, home (Protected status + stat tiles), settings, custom list, whitelist, rules, diagnostics ("Protection active?"), paywall
- ⬜ StoreKit 2 (weekly $4.99 + 3d trial, yearly $29.99), entitlement `pro`
- ⬜ XcodeGen project.yml (TARGETED_DEVICE_FAMILY=1 per target)

### Phase 2 — Assets
- ⬜ App icon (geometric, no-AI-look) + 1024² imageset
- ⬜ 5 App Store screenshots (glowup generator, 1290×2796, thumbnail-readable headlines)

### Phase 3 — Build & upload
- ⬜ Provisioning profiles (asc profiles create) — HARD CHECK for app-group assignment
- ⬜ xcodebuild archive (manual signing, Apple Distribution) → export IPA
- ⬜ altool upload → build processing → attach → encryption-exempt

### Phase 4 — ASC config (API)
- ⬜ Categories (Utilities / Productivity), availability 175/175
- ⬜ Subscription group + 2 subs, pricing equalize 4.99 / 29.99, availability 175/175
- ⬜ Metadata push (description, keywords, subtitle, promo, support/marketing URLs)
- ⬜ Screenshots upload IPHONE_67
- ⬜ Age rating (advertising:false), copyright, contentRightsDeclaration, review details

### Phase 5 — Submit (🔴 Levin web-gates)
- ⬜ App Privacy: "Data Not Collected" (web wizard)
- ⬜ First-subscription-attach + Submit for Review (web, 2.1b-critical)
- ⬜ releaseType AFTER_APPROVAL
- ⬜ Verify: version WAITING_FOR_REVIEW + both subs WAITING_FOR_REVIEW

## Long-lived driver
`asc-main` Chromium kept alive by `browser-automation/spamblock-asc-serve.mjs` (CDP :9222).
Drive it with CDP step scripts (connectOverCDP) — never launchProfile (lock clash).
