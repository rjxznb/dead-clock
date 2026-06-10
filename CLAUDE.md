# CLAUDE.md

OneLife — a life-countdown iOS/watchOS app. Developed on Windows with no local Xcode; all builds, signing, and uploads run on GitHub Actions.

## Key values

- Repo: `rjxznb/dead-clock` (public — free macOS Actions minutes)
- Bundle IDs: `com.rjxznb.deadclock` (+ `.widget` / `.watchkitapp` / `.watchkitapp.widget`)
- App Group: `group.com.rjxznb.deadclock` (shared data across all targets)
- Team ID: `Q3BK52FQT9` · ASC App ID: 6778642991
- TestFlight build number = GitHub run_number + 100

## Workflow

- `git push` is the release flow: CI (~4 min, simulator build + screenshot artifact) and TestFlight (~10 min, main branch only)
- Verify UI changes by downloading the CI screenshots artifact
- `xcodegen` runs in CI; `.xcodeproj` is not committed — the project structure lives entirely in `project.yml`
- Docs-only commits should use `[skip ci]`

## Product tone

The app is **positive motivation** (cherish time, record good moments). Default copy and colors must avoid morbid framing; the "Alert red" theme (`AppTheme.red` / `isFearMode`) is the only place fear-based wording is allowed.

## Localization

Standard `.strings` localization (en is the development language, zh-Hans provided). Every user-facing string goes through `Localizable.strings` in its target's `en.lproj` / `zh-Hans.lproj`; never hardcode UI text. Dates use locale-aware `formatted()`, not fixed-locale DateFormatter.

## Hard-won gotchas (do not repeat)

- Pushing the `.p8` to GitHub Secrets must use bash `<` redirection; PowerShell pipes corrupt the encoding (CryptoKit invalidPEMDocument)
- Portrait-only apps need `UIRequiresFullScreen: true`, or Apple rejects with ITMS-90474
- ITMS errors arrive by email **after** a successful altool upload; transient `ERROR:` lines (e.g. retried HTTP 500s) in altool logs are not failures — trust the `UPLOAD SUCCEEDED` marker
- New targets' bundle IDs must be registered manually in the developer portal (with App Group attached); cloud-signing auto-registration is unreliable (misleading "bearer token" errors)
- This network drops GitHub SSL connections intermittently: always retry `git push` / `gh api`
- App icons must be 1024×1024 RGB with no alpha channel
