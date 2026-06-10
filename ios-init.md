---
description: Bootstrap a new iOS app with XcodeGen + GitHub Actions CI + TestFlight upload, using the whatsub-mobile pattern. Works on Windows (no local Xcode required).
argument-hint: [optional: bundle id + app name]
allowed-tools: Bash, Read, Write, Edit, Grep, Glob, AskUserQuestion
---

# /ios-init — Bootstrap a CI/TestFlight-ready iOS app

Set up a fresh iOS Swift/SwiftUI app whose entire build, sign, and TestFlight
upload pipeline runs on GitHub Actions, with **zero local Xcode setup
required** on the developer's machine. This is the exact pattern proven on
[whatsub-mobile](https://github.com/rjxznb/whatsub-mobile) — every gotcha
below is one we already hit in production.

## What you (the agent) do

Walk the user through three phases:

1. **Apple's web consoles** (user does, you guide) — register Bundle ID,
   create ASC app, register ≥1 device, mint an ASC API key with **Admin**
   role. You can't do these for them; check off completion.
2. **Local file scaffolding** (you do via Write/Edit) — `project.yml`,
   `ExportOptions.plist`, `.gitignore`, minimal Swift sources, two workflow
   files. Templates embedded below — replace `{{...}}` placeholders with
   user-supplied values.
3. **GitHub Secrets push** (user does, you can suggest `gh` commands) —
   three secrets: `APP_STORE_CONNECT_API_KEY_P8`, `_KEY_ID`, `_ISSUER_ID`.

After all three: first `git push` triggers CI (sim build + screenshot, ~3 min)
and TestFlight (archive + sign + upload, ~10 min) in parallel.

---

## Step 0 — collect user input

Before scaffolding, ask via `AskUserQuestion` ONE question at a time (don't
batch — the answers feed into each other):

1. **Bundle Identifier** — e.g. `com.example.myapp.mobile`. Must already
   be registered on developer.apple.com (or we'll do it in Step 1.2).
2. **App display name** — what shows under the home-screen icon
   (e.g. `MyApp`). Will become `CFBundleDisplayName`.
3. **Marketing version** — start at `0.0.1` if user has no preference.
4. **Repo directory name** — the folder + Swift target name.
   Convention: lowercase + hyphens (e.g. `myapp-mobile`).
5. **Apple Team ID** — 10-char alphanumeric from
   developer.apple.com → Membership. If user doesn't have one, they need
   a paid Apple Developer account first; pause here.
6. **Done with the Apple web-console prerequisites?** (Yes / Walk me
   through them) — if no, do Phase 1 first.

Save these as `{{BUNDLE_ID}}`, `{{APP_NAME}}`, `{{VERSION}}`, `{{TARGET}}`,
`{{TEAM_ID}}` — used in every template below.

---

## Phase 1 — Apple's web consoles (user does)

Surface this only if user hasn't done it. If they have, skip to Phase 2.

### 1.1 — Apple Developer account
- Paid Individual ($99/year) or Organization ($299/year).
- `developer.apple.com → Account → Membership` shows status "Active".

### 1.2 — Register Bundle ID
- `developer.apple.com → Certificates, Identifiers & Profiles → Identifiers → +`
- Type: **App IDs → App**
- Description: free-form (e.g. "MyApp iOS")
- Bundle ID: **Explicit**, type the literal `{{BUNDLE_ID}}` value
- Capabilities: tick only what the app needs (Sign in with Apple, Push, etc.)

### 1.3 — Create App Store Connect record
- `appstoreconnect.apple.com → My Apps → +` → New App
- Platform: iOS
- Name: marketing name (what shows in the App Store)
- Primary language: zh-Hans or en-US
- Bundle ID: pick the one from 1.2
- SKU: any unique string (it's an internal id you won't see again)
- User Access: Full

### 1.4 — Register ≥1 device UDID (CRITICAL — apps with zero devices fail signing)
- Apple's automatic provisioning flow fails with the misleading error
  "Communication with Apple failed: Your team has no devices..." for
  App Store distribution if the team has zero registered devices.
  This is **not** an ad-hoc requirement; it's an initialization gate.
- `developer.apple.com → Devices → +`
- Get a UDID: Finder on Mac (click iPhone serial to cycle) OR Safari on
  iPhone → `get.udid.io`. One device is enough.

### 1.5 — Create ASC API Key with **Admin** role
- `appstoreconnect.apple.com → Users and Access → Integrations → Keys → +`
- Name: "GitHub Actions" (anything memorable)
- Access: **Admin** ← critical, NOT App Manager
  - Why: App Manager role can't create Distribution certificates. CI fails
    with the same misleading "no devices" error from 1.4 but the real cause
    is the permission level. API key roles cannot be changed in-place;
    revoke + recreate is the only fix.
- Click Generate → **download the `.p8` immediately** (one-time download)
- Note three values you need for GitHub Secrets:
  - **Key ID**: the 10-char string in the filename `AuthKey_<KEY_ID>.p8`
  - **Issuer ID**: shown on the Keys page (UUID format)
  - **Private Key**: the full text of the .p8 file including the BEGIN/END
    lines

### 1.6 — Tax/Banking (only if app will have In-App Purchase)
- `appstoreconnect.apple.com → Agreements, Tax, and Banking`
- All three sections (Paid Apps Agreement, Tax Forms, Banking) must show
  "Active". Missing any one = all paid products locked across all your apps.

---

## Phase 2 — Local file scaffolding (you do)

In the repo root, write the following six files. Replace `{{PLACEHOLDERS}}`
with the values collected in Step 0.

### 2.1 — `.gitignore`

```gitignore
# Xcode build artifacts
build/
DerivedData/
*.xcodeproj
*.xcworkspace
xcuserdata/
*.xcuserstate

# XcodeGen regenerates .xcodeproj from project.yml each run, so the
# generated project is intentionally ignored. Local devs run
# `xcodegen generate` before opening Xcode.

# Apple Developer artifacts — never commit
*.p8
AuthKey_*.p8
*.mobileprovision
*.cer
*.p12

# OS / IDE noise
.DS_Store
*.swp
Thumbs.db
```

### 2.2 — `project.yml`

```yaml
name: {{TARGET}}
options:
  bundleIdPrefix: {{BUNDLE_ID_PREFIX}}   # e.g. com.example.myapp (drop the trailing .mobile)
  deploymentTarget:
    iOS: "16.0"
  developmentLanguage: zh-Hans            # change to en if app is English-only
  xcodeVersion: "16.0"
  createIntermediateGroups: true
  generateEmptyDirectories: true
  groupSortPosition: top

settings:
  base:
    DEVELOPMENT_TEAM: {{TEAM_ID}}
    MARKETING_VERSION: "{{VERSION}}"
    CURRENT_PROJECT_VERSION: "1"
    SWIFT_VERSION: "5.10"
    IPHONEOS_DEPLOYMENT_TARGET: "16.0"
    TARGETED_DEVICE_FAMILY: "1,2"           # iPhone + iPad
    # Automatic signing — Xcode's Cloud Signing flow. CI uses
    # -allowProvisioningUpdates + ASC API key. We intentionally do NOT
    # set CODE_SIGN_IDENTITY; forcing it conflicts with Automatic mode.
    CODE_SIGN_STYLE: Automatic
    SWIFT_EMIT_LOC_STRINGS: NO
  configs:
    Debug:
      ENABLE_TESTABILITY: YES
      SWIFT_OPTIMIZATION_LEVEL: "-Onone"
    Release:
      SWIFT_OPTIMIZATION_LEVEL: "-O"

targets:
  {{TARGET}}:
    type: application
    platform: iOS
    sources:
      - path: {{TARGET}}
        excludes:
          - "Info.plist"
    resources:
      - {{TARGET}}/Assets.xcassets
    info:
      path: {{TARGET}}/Info.plist
      properties:
        CFBundleDisplayName: {{APP_NAME}}
        CFBundleShortVersionString: $(MARKETING_VERSION)
        CFBundleVersion: $(CURRENT_PROJECT_VERSION)
        UILaunchScreen:
          UIColorName: AccentColor
        UISupportedInterfaceOrientations:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
        UISupportedInterfaceOrientations~ipad:
          - UIInterfaceOrientationPortrait
          - UIInterfaceOrientationPortraitUpsideDown
          - UIInterfaceOrientationLandscapeLeft
          - UIInterfaceOrientationLandscapeRight
        ITSAppUsesNonExemptEncryption: false
```

### 2.3 — `ExportOptions.plist`

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key>
  <string>app-store</string>
  <key>destination</key>
  <string>export</string>
  <key>teamID</key>
  <string>{{TEAM_ID}}</string>
  <key>signingStyle</key>
  <string>automatic</string>
  <key>stripSwiftSymbols</key>
  <true/>
  <key>uploadSymbols</key>
  <true/>
  <key>uploadBitcode</key>
  <false/>
  <key>compileBitcode</key>
  <false/>
</dict>
</plist>
```

### 2.4 — Minimal Swift sources

`{{TARGET}}/App/{{APP_NAME}}App.swift`:

```swift
import SwiftUI

@main
struct {{APP_NAME}}App: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Hello, {{APP_NAME}}")
                .font(.title2.weight(.semibold))
        }
        .padding()
    }
}
```

`{{TARGET}}/Info.plist`: XcodeGen regenerates this from `project.yml`, so
create a one-line placeholder file (`{}`) just so the path exists, OR omit
and let xcodegen write it on first generate.

`{{TARGET}}/Assets.xcassets/AppIcon.appiconset/Contents.json`: standard
Xcode template — easiest to copy from
`whatsub-mobile/whatsub-mobile/Assets.xcassets/` if available, else
generate via `xcrun appiconset` after first xcodegen run.

**App icon constraint**: 1024×1024 PNG must be **RGB (no alpha)**. Apple
rejects icons with alpha channel on upload. If converting from RGBA, fill
transparency with a solid color first.

### 2.5 — `.github/workflows/ci.yml`

```yaml
name: CI

on:
  push:
    branches: ['**']
  pull_request:

concurrency:
  group: ci-${{ github.ref }}
  cancel-in-progress: true

jobs:
  build-simulator:
    name: Build for iOS Simulator + Screenshot
    # macos-15 has Xcode 16+ by default. macos-14 (Xcode 15.4) can't read
    # the objectVersion 77 .xcodeproj that current XcodeGen generates.
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4

      - name: Select latest Xcode
        # Apple requires iOS 26 SDK (Xcode 26+) for App Store submission
        # as of 2026. macos-15 ships several Xcode versions side-by-side;
        # this picks the newest installed.
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Install XcodeGen + xcbeautify
        run: brew install xcodegen xcbeautify

      - name: Show Xcode + SDK
        run: |
          xcodebuild -version
          xcrun --show-sdk-version --sdk iphonesimulator

      - name: Generate .xcodeproj
        run: xcodegen generate --quiet

      - name: Pick a stable iOS Simulator
        id: pick-sim
        run: |
          DEVICE_UDID=$(xcrun simctl list devices available -j | jq -r '.devices | to_entries | .[] | select(.key | contains("iOS")) | .value[] | select(.name == "iPhone 15 Pro") | .udid' | head -1)
          if [ -z "$DEVICE_UDID" ]; then
            DEVICE_UDID=$(xcrun simctl list devices available -j | jq -r '.devices | to_entries | .[] | select(.key | contains("iOS")) | .value[] | select(.name | startswith("iPhone")) | .udid' | head -1)
          fi
          echo "Using device UDID: $DEVICE_UDID"
          echo "udid=$DEVICE_UDID" >> "$GITHUB_OUTPUT"

      - name: Build for Simulator
        env:
          UDID: ${{ steps.pick-sim.outputs.udid }}
        run: |
          set -o pipefail
          xcodebuild \
            -project {{TARGET}}.xcodeproj \
            -scheme {{TARGET}} \
            -configuration Debug \
            -destination "platform=iOS Simulator,id=${UDID}" \
            -derivedDataPath ./DerivedData \
            CODE_SIGN_IDENTITY="" CODE_SIGNING_REQUIRED=NO CODE_SIGNING_ALLOWED=NO \
            build | xcbeautify

      - name: Boot simulator + install + screenshot
        env:
          UDID: ${{ steps.pick-sim.outputs.udid }}
        run: |
          xcrun simctl boot "$UDID" || true
          xcrun simctl bootstatus "$UDID" -b
          APP_PATH=$(find DerivedData/Build/Products/Debug-iphonesimulator -maxdepth 2 -name "{{TARGET}}.app" | head -1)
          xcrun simctl install "$UDID" "$APP_PATH"
          xcrun simctl launch "$UDID" {{BUNDLE_ID}}
          sleep 3
          mkdir -p screenshots
          xcrun simctl io "$UDID" screenshot screenshots/01-launch.png
          ls -la screenshots/

      - name: Upload screenshots artifact
        uses: actions/upload-artifact@v4
        with:
          name: simulator-screenshots-${{ github.sha }}
          path: screenshots/
          retention-days: 14
          if-no-files-found: error
```

### 2.6 — `.github/workflows/testflight.yml`

```yaml
name: TestFlight

on:
  push:
    branches: [main]
  workflow_dispatch:

concurrency:
  group: testflight
  cancel-in-progress: false   # never cancel an upload in flight

jobs:
  upload:
    name: Archive + Upload to TestFlight
    runs-on: macos-15
    steps:
      - uses: actions/checkout@v4

      - name: Select latest Xcode
        uses: maxim-lobanov/setup-xcode@v1
        with:
          xcode-version: latest-stable

      - name: Install XcodeGen + xcbeautify
        run: brew install xcodegen xcbeautify

      - name: Generate .xcodeproj
        run: xcodegen generate --quiet

      - name: Write ASC API key to disk
        env:
          ASC_API_KEY_P8: ${{ secrets.APP_STORE_CONNECT_API_KEY_P8 }}
          ASC_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
        run: |
          # Safety check: empty secret → printf creates empty .p8 → downstream
          # xcodebuild fails with cryptic "flag -authenticationKeyID is required"
          # even though the flag IS in the command. Catch it here loudly.
          if [ -z "$ASC_API_KEY_P8" ] || [ -z "$ASC_KEY_ID" ]; then
            echo "::error::APP_STORE_CONNECT_API_KEY_P8 or _KEY_ID secret is empty"
            exit 1
          fi
          mkdir -p ~/.appstoreconnect/private_keys
          printf '%s' "$ASC_API_KEY_P8" > ~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8
          chmod 600 ~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8
          BYTES=$(wc -c < ~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8)
          if [ "$BYTES" -lt 200 ]; then
            echo "::error::AuthKey .p8 is only $BYTES bytes — secret content is malformed"
            exit 1
          fi
          cp ~/.appstoreconnect/private_keys/AuthKey_${ASC_KEY_ID}.p8 $RUNNER_TEMP/AuthKey.p8

      - name: Set CURRENT_PROJECT_VERSION = run_number + 100
        run: |
          # Each TestFlight upload needs a unique (version, build) pair.
          # +100 offset gives headroom if you ever do manual uploads outside CI.
          BUILD_NUM=$((${{ github.run_number }} + 100))
          echo "BUILD_NUM=$BUILD_NUM" >> $GITHUB_ENV

      - name: Archive
        env:
          ASC_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
        run: |
          set -o pipefail
          xcodebuild \
            -project {{TARGET}}.xcodeproj \
            -scheme {{TARGET}} \
            -configuration Release \
            -destination "generic/platform=iOS" \
            -archivePath ./build/{{TARGET}}.xcarchive \
            -allowProvisioningUpdates \
            -authenticationKeyID "$ASC_KEY_ID" \
            -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
            -authenticationKeyPath "$RUNNER_TEMP/AuthKey.p8" \
            CURRENT_PROJECT_VERSION=$BUILD_NUM \
            DEVELOPMENT_TEAM={{TEAM_ID}} \
            archive | xcbeautify

      - name: Export IPA
        env:
          ASC_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
        run: |
          set -o pipefail
          xcodebuild \
            -exportArchive \
            -archivePath ./build/{{TARGET}}.xcarchive \
            -exportPath ./build/export \
            -exportOptionsPlist ExportOptions.plist \
            -allowProvisioningUpdates \
            -authenticationKeyID "$ASC_KEY_ID" \
            -authenticationKeyIssuerID "$ASC_ISSUER_ID" \
            -authenticationKeyPath "$RUNNER_TEMP/AuthKey.p8" | xcbeautify

      - name: Upload to TestFlight
        env:
          ASC_KEY_ID: ${{ secrets.APP_STORE_CONNECT_KEY_ID }}
          ASC_ISSUER_ID: ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
        run: |
          set -o pipefail
          IPA=$(find ./build/export -name "*.ipa" | head -1)
          UPLOAD_LOG=$(mktemp)
          # altool exits 0 even when validation fails (daily upload limit,
          # duplicate build, missing icon, etc.). Tee + grep for failure
          # markers so the workflow step actually fails on these cases.
          xcrun altool --upload-app \
            -f "$IPA" \
            -t ios \
            --apiKey "$ASC_KEY_ID" \
            --apiIssuer "$ASC_ISSUER_ID" 2>&1 | tee "$UPLOAD_LOG"
          if grep -qE "Validation failed|UPLOAD FAILED|ERROR:|Upload limit reached" "$UPLOAD_LOG"; then
            echo "::error::altool reported a validation/upload error"
            exit 1
          fi

      - name: Upload archive artifact (for forensics)
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: xcarchive-${{ github.sha }}
          path: build/{{TARGET}}.xcarchive
          retention-days: 7
```

---

## Phase 3 — GitHub Secrets (user does)

Three secrets, in repo Settings → Secrets and variables → Actions → New
repository secret. Suggest the `gh` CLI commands if `gh` is installed:

```bash
# From the directory containing the AuthKey file:
gh secret set APP_STORE_CONNECT_API_KEY_P8 < AuthKey_XXXXXXXXXX.p8

# Direct values:
gh secret set APP_STORE_CONNECT_KEY_ID --body "XXXXXXXXXX"
gh secret set APP_STORE_CONNECT_ISSUER_ID --body "abcd1234-ef56-..."
```

After confirming all three are set, tell the user to **delete the local
`.p8` file** — they can't re-download it, but the GitHub Secret is now
the source of truth.

---

## Phase 4 — First push + verify

```bash
git add .
git commit -m "init: iOS app scaffold + CI/TestFlight workflows"
git push origin main
```

- CI workflow runs (sim build + screenshot) — green in ~3 min
- TestFlight workflow runs (archive + sign + upload) — green in ~10 min
- TestFlight processes the binary — appears in ASC → TestFlight tab
  after another 5-15 min of Apple-side processing
- Internal testers added in ASC see the build available immediately
  after processing

Watch the runs:

```bash
gh run list --limit 4
gh run watch <run-id>
```

---

## Common gotchas (every one we hit on whatsub-mobile)

### GitHub Actions / billing

- **Private repos may hit billing block** with cryptic
  "recent account payments have failed or your spending limit needs to be
  increased" — blocks even Linux runs.
  Fix for solo-dev hobby apps: `gh repo edit <repo> --visibility public
  --accept-visibility-change-consequences`. Public repos get unlimited
  free Actions minutes including macOS. Secrets stay encrypted.

### Xcode / SDK / xcodebuild

- **XcodeGen 2.43+ emits `objectVersion 77`** which only Xcode 16+ reads.
  Symptom: `xcodebuild: error: The project … is in a future Xcode project
  file format (77).` Fix: `runs-on: macos-15` (Xcode 16.x default), NOT
  `macos-14` (Xcode 15.4).

- **Apple requires iOS 26 SDK** for any TestFlight or App Store upload
  as of 2026. macos-15 ships multiple Xcode versions side-by-side; the
  `maxim-lobanov/setup-xcode@v1 latest-stable` step picks the newest.

### ASC API key

- **API Key with "App Manager" role can NOT create Distribution certs.**
  Symptom: `Communication with Apple failed: Your team has no devices
  from which to generate a provisioning profile.` This is misleading —
  the real cause is the API key's permission level, not a missing device.
  Fix: revoke + recreate the API key with **Admin** role. Role can't be
  changed in place.

- **`CODE_SIGN_STYLE=Automatic` + forced `CODE_SIGN_IDENTITY` = conflict
  error.** When using Automatic signing, do NOT manually set
  CODE_SIGN_IDENTITY anywhere (project.yml, CLI, .xcconfig).

- **Zero registered devices on team** = signing fails even for App Store
  Distribution. Apple's auto-provisioning has an init door — without ≥1
  device in Developer Portal, signing can't proceed even for distribution
  that logically shouldn't need devices. One-time fix.

### App icon

- **App Store rejects icons with alpha channel.** Symptom on `altool`:
  `Validation failed (409) Invalid large app icon. … can't be
  transparent or contain an alpha channel.` The 1024×1024 PNG must be
  RGB. If source is RGBA, fill transparency with solid color first.
  PowerShell one-liner (Windows):

  ```powershell
  Add-Type -AssemblyName System.Drawing;
  $s = [Drawing.Image]::FromFile('icon.png');
  $d = New-Object Drawing.Bitmap($s.Width, $s.Height, 'Format24bppRgb');
  $g = [Drawing.Graphics]::FromImage($d);
  $g.Clear([Drawing.Color]::Black);
  $g.DrawImage($s, 0, 0);
  $d.Save('icon.png', 'Png');
  $s.Dispose(); $g.Dispose(); $d.Dispose()
  ```

### Distribution cert pool

- **Frequent CI fills the Distribution cert quota** (~5-8 active certs).
  Symptom: `archive` fails with "Choose a certificate to revoke. Your
  account has reached the maximum number of certificates." Fix
  (one-time, ~2 min): developer.apple.com → Certificates → revoke older
  Apple Distribution certs (keep ≤1). CI mints a fresh one next run.
  Rerun without new commit: `gh run rerun <run-id>`.

### Secrets pitfalls

- **`printf '%s' "$EMPTY_VAR" > file.p8` creates an empty file silently**,
  causing downstream xcodebuild to fail with cryptic flag errors. The
  testflight.yml template above includes a `wc -c < AuthKey.p8` check
  (must be > 200 bytes) to catch this loudly.

### altool false success

- **`altool` exits 0 even when validation fails** (upload limit reached,
  duplicate build, invalid icon, etc.). The workflow template above
  tees altool output and greps for failure markers — without this,
  GitHub reports "success" when the upload actually failed silently.
  Daily TestFlight upload limit is ~25-50 per app per day.

---

## After it ships once

- TestFlight build number is automatically `github.run_number + 100`
  (testflight.yml computes this). Each upload is unique without manual
  bumps.
- Internal testers in ASC see the build immediately after Apple's 5-15
  min processing window.
- For App Store public release (after testing in TestFlight): ASC →
  App Store tab → version → fill metadata, screenshots, privacy labels,
  pricing → Submit for Review.
- ASC reviewer's checklist of common rejection causes is captured in
  the whatsub-mobile CLAUDE.md "踩过的坑" section. Read before
  resubmitting if rejected.

---

## Re-invocation

`/ios-init` is idempotent. If files already exist when you re-run it:
- Diff what's there vs the template
- Suggest patches (don't auto-overwrite)
- Update workflows in-place if user confirms

Good for: bringing an existing iOS project up to the current proven
pattern, or fixing drift after Apple/Xcode toolchain bumps.
