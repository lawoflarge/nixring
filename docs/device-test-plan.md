# Nixring — Manual Device Test Plan

The Call Directory and Message Filter extensions only take effect on a **physical iPhone**
(not the Simulator). Run these once on a real device before/after release.

## Setup
1. Install the build (TestFlight or Xcode run on device).
2. Launch Nixring → complete onboarding.
3. Settings ▸ Phone ▸ Call Blocking & Identification → enable **Nixring**.
4. Settings ▸ Messages ▸ Unknown & Spam ▸ SMS Filtering → **Nixring** (Pro).

## Call blocking
- [ ] Add a test number under Blocklist ▸ Numbers, tap Reload protection.
- [ ] From another phone, call from that number → call is silenced/blocked.
- [ ] Add the number to Whitelist, reload → same number now rings through.
- [ ] Home shows "Protected" and a non-zero "Numbers Shielded".
- [ ] Diagnostics ▸ Protection status shows call blocking = Active.

## Text filtering (Pro)
- [ ] Enable Pro (sandbox tester) → Junk text filter toggle on.
- [ ] From a non-contact, send a text containing a suspicious link (e.g. `verify at secure-bank.xyz`) → lands in the **Junk** folder in Messages.
- [ ] Send a normal text from a non-contact → stays in the main inbox.
- [ ] Home "Texts Filtered" increments after a junked message.

## StoreKit (sandbox)
- [ ] Paywall shows weekly $4.99 (3-day trial) + yearly $29.99.
- [ ] Purchase weekly (sandbox) → Pro unlocks (PRO badge, Pro features enabled).
- [ ] Restore purchases works.
- [ ] Terms + Privacy links open.

## Health check
- [ ] Disable Nixring in Settings → app shows "Call blocking is off" banner.
- [ ] Re-enable → banner clears, ring returns to Protected.
