# Nixring — Spam Call & Text Blocker

On-device spam call and text blocker for iPhone. Nixring uses Apple's Call Directory and Message Filter extensions to silence known spam numbers — no account, no tracking, and your call history never leaves your device.

## How the blocklist works
The app ships with a bundled blocklist and refreshes from a public JSON feed served out of this repo's `web/` folder:

- **Live feed:** <https://nixring.vercel.app/blocklist.json>

The feed is public by design so the app can fetch it without credentials. This repository is intentionally public for that reason.

## Monorepo layout
- `App/` — SwiftUI host app
- `CallDirectory/` — Call Directory extension (blocks/identifies numbers)
- `MessageFilter/` — Message Filter extension (filters spam SMS)
- `Packages/` — local Swift packages
- `Resources/blocklist.json` — bundled fallback blocklist
- `web/` — marketing site, privacy/support pages **and `blocklist.json`**, deployed to <https://nixring.vercel.app>
- `scripts/`, `docs/` — supporting material
- `project.yml` — XcodeGen project definition

## Build
```bash
xcodegen generate
open *.xcodeproj
```

## Privacy
Privacy policy: <https://nixring.vercel.app/privacy.html> · Support: <https://nixring.vercel.app/support.html>
