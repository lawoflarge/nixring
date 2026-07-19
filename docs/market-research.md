# Nixring — Market Research

Source: live web research + real App Store / Reddit / Trustpilot reviews of 8 competitors
(parallel research agents, 2026-07-19). Raw data: `docs/research-raw.json`.

## Positioning (our wedge)

> **The only iPhone spam blocker that keeps your contacts and blocklist entirely on-device —
> stopping spam calls and scam texts together, with genuine EU coverage and one fair, ad-free price.**

Short store line: *"Nothing leaves your phone. Blocks calls + texts. One fair price."*

## Competitor table

| App | Pricing | Rating | Key gap we exploit |
|---|---|---|---|
| **Truecaller** | Premium $9.99/mo, $74.99/yr; Gold ~$249/yr; ad-supported free | ~4.4–4.5 (~251K US) | Crowdsourced cloud DB exposes non-users' numbers without consent; iOS label tracks contacts + identifiers for ads; ad-choked free tier; SMS is weak region-limited category sorting; **refuses to remove false spam flags** |
| **Hiya** | Free; Premium $3.99/mo … $24.99/yr | 4.5 (~237K US) | Moved once-free auto-block + SMS-spam blocking behind paywall; free tier only *labels*; Screener/Fraud US/CA-only; no real EU coverage |
| **RoboKiller** | ~38 SKUs $5.99–$89.99/yr; annual hiked | 4.5 App Store vs 1.5 PissedConsumer | US/CA only; billing traps, unauthorized charges, refused refunds; uploads contacts + trackable IDs despite "never sell" marketing; texts still slip through |
| **Nomorobo** | $2.99/mo–$79.99/yr | 4.5 (~22K); Trustpilot 1.6 | US-only; hard-to-cancel annual billing; SMS often never blocks; formerly-free landline blocking paywalled Jan 2026 |
| **YouMail** | Free ad-supported; Plus $7.99/mo… | 4.7 (~98K); Trustpilot 2.0 | Cloud voicemail hijack via carrier forwarding (not on-device); uploads contacts; ad-tracking/CCPA "sale"; loud ads; US/CA only |
| **Whoscall** | Free ad-supported; Premium $2.89/mo, $27/yr | 4.7 (~3K US) | APAC-centric — weak on EU/DE numbers; full-screen ads w/ fake close buttons; auto-block + SMS Assistant all paywalled; extension silently disables |
| **Should I Answer** | Free; ~$1.99/mo | 2.6 (~470 US) | Genuinely private BUT **calls-only, no SMS/smishing**; poor detection (~1 in 20); surprise paywall; ads even for payers |

## Verified painpoints (ranked)

**High severity**
1. Contact harvesting / crowdsourced cloud DB exposes non-users without consent, nearly impossible to escape.
2. Privacy theater: "safe" apps still track and monetize data.
3. Aggressive/surprise pricing, auto-renew traps, refused refunds, near-impossible cancellation.
4. False positives: doctors, schools, family, recruiters blocked/silently dropped with weak/no whitelist.
5. "Installed it, does nothing" — confusing iOS extension setup that silently breaks after updates.
6. Weak or absent SMS / smishing protection on iOS.
7. Doesn't actually *block* — just labels spam while letting it ring.
8. US/India/APAC-centric coverage — weak in EU/Germany.

**Medium/low**
9. Ad-heavy, intrusive free tiers. 10. Doesn't stop spoofed/neighbor-spoofed numbers. 11. Poor support. 12. No visibility into what was blocked.

## Our differentiation (painpoint → answer)

- **Contact harvesting →** 100% on-device. Address book + blocklist never leave the iPhone. We can honestly ship "Data Not Collected" and *cannot* expose a non-user because we never receive their number.
- **Privacy theater →** Zero ad SDKs, zero third-party trackers. One honest subscription; nothing to sell because processing is local. Claim and architecture match.
- **Pricing traps →** One fair flat price. No ad tier, no Gold up-sell, no 38 SKUs. Billed via Apple → cancel in one tap.
- **False positives →** One-tap whitelist; Contacts always trusted by default; nothing silently dropped — everything blocked is logged and reversible.
- **Broken setup →** Guided in-app setup + a built-in **health check** that detects when iOS disabled the Call Directory / SMS Filter extension and walks the user through re-enabling — instead of failing silently.
- **Weak SMS →** Calls AND texts in one app, on-device. Junk-SMS + smishing link/scam-pattern detection, never paywalled as an afterthought.
- **Labels not blocks →** Real blocking by default via the Call Directory extension.
- **US-centric →** EU/DE-first bundled offline database of German/EU spam prefixes/patterns, refreshed by a lightweight static remote list — no crowdsourcing density needed, works day one.

## Store-copy inputs

**Screenshot headlines (thumbnail-readable):**
1. Auto-Block Every Spam Call
2. Kill Junk & Scam Texts
3. Contacts Never Leave Your Phone
4. Whitelist Real Callers in a Tap
5. See Everything You Blocked

**ASO keywords:** spam blocker, spam call blocker, call blocker, robocall blocker, block spam calls, spam text blocker, junk sms blocker, smishing protection, scam call blocker, block unknown callers, caller id, block texts, scam text blocker, privacy call blocker, spam protection, block calls and texts, on-device spam blocker
