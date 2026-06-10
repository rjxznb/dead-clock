# OneLife ⏳ — Make Time Count

A life countdown app that turns your remaining time into motivation. Set your date of birth and life expectancy, and OneLife counts down every second you have left — a constant reminder that time is finite, so spend it on what makes you happy and matters.

> App Store: **OneLife - Make Time Count** · iOS 16+ / watchOS 9+ · English & 简体中文

## Features

- **Live countdown** — rainbow-gradient digits ticking every 0.1s, with years/days/hours/minutes/seconds breakdown and a life progress bar
- **Daily check-in** — record the happiest or most meaningful moment of each day, with streak tracking
- **Shareable posters** — turn any moment into a gradient poster (two styles) to share or save
- **Five themes** — Dark / Light / Flowing gradient / Photo slideshow (up to 9 photos with crossfade) / Alert-red fear mode
- **Bedtime reminder** — a nightly nudge to check in, automatically silenced once you have
- **Lock screen & home screen widgets** — iOS 16 lock screen accessories plus home screen widgets
- **Apple Watch** — standalone watch app and four watch-face complications; settings sync from iPhone automatically
- **Localized** — UI follows the device language (English / Simplified Chinese)

## Architecture

- **SwiftUI** end to end: TimelineView-driven live updates, WidgetKit widgets and complications, ImageRenderer for posters, WatchConnectivity for watch sync
- **XcodeGen**: the Xcode project is generated from `project.yml`; `.xcodeproj` is not committed
- **Zero local Xcode**: every build, signing, and upload runs on GitHub Actions (macOS runners) — developed entirely from a Windows machine

```
DeadClock/            iOS app (countdown, check-in, posters, themes, reminders)
DeadClock/Shared/     Models shared across targets (DeathClock, JournalStore)
DeadClockWidget/      iOS lock screen / home screen widgets
DeadClockWatch/       watchOS app
DeadClockWatchWidget/ watchOS watch-face complications
.github/workflows/    ci.yml (simulator build + screenshot), testflight.yml (sign + upload)
```

## CI / Release Pipeline

1. Push to any branch → **CI**: simulator build + launch screenshot (downloadable artifact for UI preview)
2. Push to `main` → **TestFlight**: cloud signing (ASC API key) → archive → upload; build number = run_number + 100
3. After 5–15 minutes of Apple-side processing, the build is installable via TestFlight

Required repository secrets: `APP_STORE_CONNECT_API_KEY_P8` / `_KEY_ID` / `_ISSUER_ID` (Admin role key).

## Local Development (optional, requires a Mac)

```bash
brew install xcodegen
xcodegen generate
open DeadClock.xcodeproj
```

---

🤖 Built with [Claude Code](https://claude.com/claude-code)
