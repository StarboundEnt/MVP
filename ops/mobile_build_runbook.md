# Mobile Build & Release Runbook

Covers producing release builds for iOS (TestFlight) and Android (Play Store internal track) using production environment credentials.

## Prerequisites
- Flutter SDK (stable channel) installed.
- Xcode (latest) configured with signing certificates + provisioning profiles.
- Android SDK/NDK installed with keystore for release signing.
- Access to Apple App Store Connect and Google Play Console.
- `.env` production values stored in secure location (`ops/secrets/mobile_prod.env`).

## 1. Pre-Build Checklist
1. Update version in `pubspec.yaml` (e.g., `version: 1.2.0+45`).
2. Update changelog/release notes.
3. Run code quality checks:
   ```bash
   flutter clean
   flutter pub get
   flutter analyze
   flutter test
   ```
4. Verify assets (`flutter pub run flutter_launcher_icons`, etc.) if changed.

## 2. Configure Environment
Create `.env` file for production build (do not commit). Use `ops/secrets/.env.prod.template` as a starting point:
```
cp .env .env.prod
# edit .env.prod with production Complexity Profile backend endpoints, API keys, etc.
```
Ensure build pipeline injects this file at runtime (e.g., via `--dart-define` or build script).

## 3. Android Build
1. Set keystore variables:
   ```bash
   export KEYSTORE_PATH=~/keys/starbound.keystore
   export KEYSTORE_ALIAS=starbound
   export KEYSTORE_PASSWORD=***
   export KEY_PASSWORD=***
   ```
2. Build App Bundle:
   ```bash
   flutter build appbundle --release \
     --dart-define-from-file=.env.prod
   ```
3. Output: `build/app/outputs/bundle/release/app-release.aab`.
4. Upload to Play Console internal testing track, attach release notes, start review.

## 4. iOS Build
1. Select signing identity:
   ```bash
   export IOS_TEAM_ID=YOURTEAMID
   export IOS_PROFILE=Starbound_Prod_Profile
   ```
2. Build archive:
   ```bash
   flutter build ipa --release \
     --export-options-plist=ops/ios/exportOptions.plist \
     --dart-define-from-file=.env.prod
   ```
3. Upload using Transporter or `xcrun altool`:
   ```bash
   xcrun altool --upload-app -f build/ios/ipa/starbound.ipa \
     -u appleid@example.com -p app-specific-password
   ```
4. In App Store Connect, submit for TestFlight review, attach metadata and testers.

## 5. Post-Build Verification
- Install builds on physical devices (iOS + Android) using internal links.
- Verify login, journaling, Complexity Profile screens, and push notifications.
- Confirm `/health` endpoint reachable from mobile (No CORS issues).

## 6. Release Coordination
- Update release notes in App/Play store entries.
- Notify marketing/support teams of intended launch date.
- Record build numbers, dates, and testers in launch log.

## Appendices
- `docs/mvp_launch_checklist.md` for overall status.
- `ops/backend_deployment_runbook.md` for backend release steps.
