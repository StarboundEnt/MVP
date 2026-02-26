# iOS Release Build Setup

## 1. Update Bundle Identifier

The bundle identifier needs to be changed from `com.example.starbound` to `com.starbound.app`.

### Manual Update (via Xcode):

1. Open the project in Xcode:
   ```bash
   cd ios
   open Runner.xcodeproj
   ```

2. Select the Runner project in the navigator
3. Select the Runner target
4. Go to "Signing & Capabilities" tab
5. Update Bundle Identifier to: `com.starbound.app`

### Alternative: Command-line update

```bash
# Update the bundle identifier in project.pbxproj
cd ios
sed -i '' 's/com.example.starbound/com.starbound.app/g' Runner.xcodeproj/project.pbxproj
```

## 2. Configure Signing

### Development Signing (Automatic):

1. In Xcode, select Runner target
2. Go to "Signing & Capabilities"
3. Check "Automatically manage signing"
4. Select your Team
5. Xcode will create a development provisioning profile

### Release Signing (Manual - Recommended for App Store):

1. Create an App Store Connect account
   - Go to https://developer.apple.com
   - Enroll in Apple Developer Program ($99/year)

2. Create App ID:
   - Go to https://developer.apple.com/account/resources/identifiers
   - Click "+" to add new identifier
   - Select "App IDs" → "App"
   - Description: Starbound
   - Bundle ID: `com.starbound.app` (Explicit)
   - Enable capabilities:
     - Associated Domains (if using universal links)
     - Push Notifications
     - HealthKit (if using health data)
     - Sign in with Apple (if using)

3. Create Distribution Certificate:
   ```bash
   # Generate CSR (Certificate Signing Request)
   # Open Keychain Access → Certificate Assistant → Request Certificate
   # Save to disk: CertificateSigningRequest.certSigningRequest
   ```

   - Upload CSR to https://developer.apple.com/account/resources/certificates
   - Select "Apple Distribution"
   - Download and install certificate

4. Create Provisioning Profile:
   - Go to https://developer.apple.com/account/resources/profiles
   - Click "+" to create new profile
   - Select "App Store"
   - Select App ID: com.starbound.app
   - Select Distribution Certificate
   - Name: "Starbound App Store"
   - Download profile

5. Configure in Xcode:
   - Uncheck "Automatically manage signing" for Release
   - Import provisioning profile
   - Select the provisioning profile for Release builds

## 3. Build Schemes for Different Environments

### Create build configurations:

1. In Xcode, select Runner project
2. Go to Info tab
3. Under Configurations, duplicate Release:
   - Release-Dev
   - Release-Staging
   - Release-Prod

### Create schemes:

1. Product → Scheme → Manage Schemes
2. Duplicate Runner scheme for each environment:
   - Runner-Dev (uses Release-Dev)
   - Runner-Staging (uses Release-Staging)
   - Runner-Prod (uses Release-Prod)

### Update Info.plist for different bundles:

For each configuration, you can set different bundle identifiers:
- Dev: `com.starbound.app.dev`
- Staging: `com.starbound.app.staging`
- Prod: `com.starbound.app`

## 4. Build Commands

### Debug Build
```bash
flutter build ios --debug
```

### Release Build for Testing
```bash
flutter build ios --release
```

### Build for specific device
```bash
# Get device ID
flutter devices

# Build and install
flutter build ios --release --device-id <DEVICE_ID>
```

### Create IPA for TestFlight
```bash
flutter build ipa --release
```

The IPA will be at:
`build/ios/ipa/starbound.ipa`

## 5. TestFlight Setup

### First-time setup:

1. **Create App Store Connect listing**
   - Go to https://appstoreconnect.apple.com
   - Click "+" → "New App"
   - Platform: iOS
   - Name: Starbound
   - Primary Language: English
   - Bundle ID: com.starbound.app
   - SKU: STARBOUND001
   - User Access: Full Access

2. **Configure TestFlight**
   - Select your app
   - Go to "TestFlight" tab
   - Add internal testers (up to 100)
   - Add external testers (need Beta App Review)

### Upload build to TestFlight:

#### Method 1: Using Xcode

1. Build archive:
   ```bash
   # First, build the app
   flutter build ios --release
   ```

2. Open Xcode:
   ```bash
   open ios/Runner.xcworkspace
   ```

3. Select "Any iOS Device" as target
4. Product → Archive
5. Wait for archive to complete
6. Organizer window opens automatically
7. Select the archive → "Distribute App"
8. Choose "App Store Connect"
9. Upload

#### Method 2: Using fastlane (Recommended)

Install fastlane:
```bash
gem install fastlane
cd ios
fastlane init
```

Create `ios/fastlane/Fastfile`:
```ruby
default_platform(:ios)

platform :ios do
  desc "Push a new beta build to TestFlight"
  lane :beta do
    # Build the app
    build_app(
      scheme: "Runner",
      export_method: "app-store",
      export_options: {
        provisioningProfiles: {
          "com.starbound.app" => "Starbound App Store"
        }
      }
    )

    # Upload to TestFlight
    upload_to_testflight(
      skip_waiting_for_build_processing: true,
      apple_id: "YOUR_APPLE_ID_EMAIL"
    )
  end
end
```

Then run:
```bash
cd ios
fastlane beta
```

#### Method 3: Using Flutter build + Transporter

1. Build IPA:
   ```bash
   flutter build ipa --release
   ```

2. Upload using Transporter app:
   - Install Transporter from Mac App Store
   - Open Transporter
   - Drag and drop the IPA file
   - Click "Deliver"

#### Method 4: Using altool (command line)

```bash
xcrun altool --upload-app \
  --type ios \
  --file build/ios/ipa/starbound.ipa \
  --apiKey YOUR_API_KEY \
  --apiIssuer YOUR_ISSUER_ID
```

To create API keys:
- Go to https://appstoreconnect.apple.com/access/api
- Click "+" under Keys
- Name: "Starbound CI/CD"
- Access: Developer
- Download key file (only available once!)

### After upload:

1. Build processes in App Store Connect (10-15 minutes)
2. Once processed, assign to testers
3. Testers receive email notification
4. They install via TestFlight app

## 6. Version Management

Update in `pubspec.yaml`:
```yaml
version: 1.0.0+1
```

- CFBundleShortVersionString: 1.0.0 (user-visible)
- CFBundleVersion: 1 (build number)

**Apple Requirements:**
- Each upload must have unique build number
- Version must be incremented for App Store release
- TestFlight builds can share version with different build numbers

## 7. App Store Release Checklist

### Before submission:

- [ ] Update app version
- [ ] Complete App Information
- [ ] Add App Privacy details
- [ ] Prepare screenshots (see IOS_STORE_METADATA.md)
- [ ] Write App Description
- [ ] Add App Preview video (optional)
- [ ] Set pricing and availability
- [ ] Configure In-App Purchases (if any)
- [ ] Add App Store review information
- [ ] Test on real devices
- [ ] Pass TestFlight beta testing

### Screenshots required:

- 6.7" iPhone (iPhone 15 Pro Max): 1290 x 2796 pixels
- 6.5" iPhone (iPhone 14 Plus): 1242 x 2688 pixels
- 5.5" iPhone (iPhone 8 Plus): 1242 x 2208 pixels
- 12.9" iPad Pro: 2048 x 2732 pixels

Minimum: 3 screenshots, Maximum: 10 screenshots

### Submit for review:

1. In App Store Connect, select your app
2. Click "+ Version or Platform"
3. Select iOS
4. Enter version number
5. Fill in "What's New" description
6. Select build from TestFlight
7. Click "Add for Review"
8. Submit

### Review times:

- Average: 24-48 hours
- Can be expedited with justification

## 8. Code Signing Best Practices

### Use Match (fastlane):

```bash
fastlane match init
fastlane match development
fastlane match appstore
```

This stores certificates in Git and shares across team.

### Certificate expiration:

- Development: 1 year
- Distribution: 1 year
- Set calendar reminders before expiration

### Provisioning profile updates:

- Automatic: Xcode manages
- Manual: Download from developer portal every 30 days

## 9. Common Issues

### Issue: "Code signing error"
**Solution**:
- Verify certificate is installed in Keychain
- Check provisioning profile is downloaded
- Ensure bundle ID matches

### Issue: "Version already exists"
**Solution**: Increment build number in pubspec.yaml

### Issue: "Missing compliance"
**Solution**: Answer export compliance questions in App Store Connect

### Issue: "Invalid provisioning profile"
**Solution**:
- Regenerate profile on developer portal
- Download and install in Xcode

### Issue: "The bundle is invalid"
**Solution**: Check that all required icons and assets are included

## 10. CI/CD Integration

### GitHub Actions example:

```yaml
name: iOS Release

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install Flutter
        uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.8'

      - name: Install dependencies
        run: flutter pub get

      - name: Build IPA
        run: flutter build ipa --release

      - name: Upload to TestFlight
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
        run: |
          xcrun altool --upload-app --type ios \
            --file build/ios/ipa/starbound.ipa \
            --apiKey ${{ secrets.API_KEY_ID }} \
            --apiIssuer ${{ secrets.API_ISSUER_ID }}
```

## 11. Security Considerations

- [ ] Enable App Transport Security (ATS)
- [ ] Configure NSAppTransportSecurity in Info.plist
- [ ] Use HTTPS for all network calls
- [ ] Implement certificate pinning
- [ ] Enable Data Protection
- [ ] Use Keychain for sensitive data
- [ ] Add Face ID/Touch ID permissions
- [ ] Configure proper entitlements

## 12. Required Capabilities

Add to Info.plist as needed:

```xml
<!-- Camera (for QR scanning) -->
<key>NSCameraUsageDescription</key>
<string>We need camera access to scan QR codes</string>

<!-- Microphone (for speech-to-text) -->
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for voice journaling</string>

<!-- Notifications -->
<key>NSUserNotificationsUsageDescription</key>
<string>We send reminders for journaling and habit tracking</string>

<!-- Face ID -->
<key>NSFaceIDUsageDescription</key>
<string>Unlock app with Face ID for quick access</string>
```

## 13. Resources

- [Apple Developer Portal](https://developer.apple.com)
- [App Store Connect](https://appstoreconnect.apple.com)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [fastlane Documentation](https://docs.fastlane.tools)
- [App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
