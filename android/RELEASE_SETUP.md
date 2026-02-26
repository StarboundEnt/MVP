# Android Release Build Setup

## 1. Generate Release Keystore

### Create a new keystore (one-time setup):

```bash
# Navigate to the android directory
cd android

# Create keystore directory
mkdir -p keystore

# Generate release keystore
keytool -genkey -v -keystore keystore/release.keystore \
  -alias starbound-release \
  -keyalg RSA \
  -keysize 2048 \
  -validity 10000

# You will be prompted for:
# - Keystore password (STARBOUND_KEYSTORE_PASSWORD)
# - Key password (STARBOUND_KEY_PASSWORD)
# - Your name, organization, location, etc.
```

**IMPORTANT**: Keep the keystore file and passwords secure! Store them in:
- Password manager
- Secure team vault (1Password, LastPass, etc.)
- CI/CD secrets manager

### Add keystore to gitignore

The keystore is already gitignored in `android/.gitignore`:
```
keystore/
*.keystore
*.jks
key.properties
```

## 2. Configure Environment Variables

### For local builds:

Create `android/key.properties`:
```properties
starboundKeystorePath=../keystore/release.keystore
starboundKeystorePassword=YOUR_KEYSTORE_PASSWORD
starboundKeyAlias=starbound-release
starboundKeyPassword=YOUR_KEY_PASSWORD
```

**Note**: This file is gitignored and should NEVER be committed!

### For CI/CD (GitHub Actions, etc.):

Set these as secrets:
- `STARBOUND_KEYSTORE_PATH` - Path to keystore file
- `STARBOUND_KEYSTORE_PASSWORD` - Keystore password
- `STARBOUND_KEY_ALIAS` - Key alias (starbound-release)
- `STARBOUND_KEY_PASSWORD` - Key password

## 3. Build Flavors

The app supports three environment flavors:

### Development Build
```bash
flutter build apk --flavor dev --debug
# Output: com.starbound.app.dev (debug)
```

### Staging Build
```bash
flutter build apk --flavor staging --release
# Output: com.starbound.app.staging
```

### Production Build
```bash
flutter build apk --flavor prod --release
# Output: com.starbound.app
```

## 4. Build Types

### APK (for testing)
```bash
flutter build apk --flavor prod --release
```

### App Bundle (for Play Store)
```bash
flutter build appbundle --flavor prod --release
```

The bundle will be at:
`build/app/outputs/bundle/prodRelease/app-prod-release.aab`

## 5. Play Store Internal Testing

### First-time setup:

1. **Create Google Play Console account**
   - Go to https://play.google.com/console
   - Pay the $25 one-time registration fee

2. **Create app listing**
   - App name: Starbound
   - Package name: com.starbound.app
   - Category: Health & Fitness

3. **Complete store listing**
   - See `../docs/PLAY_STORE_METADATA.md` for required assets

### Upload to Internal Testing:

1. Build the app bundle:
   ```bash
   flutter build appbundle --flavor prod --release
   ```

2. In Play Console:
   - Go to "Testing" → "Internal testing"
   - Create a new release
   - Upload the AAB file
   - Add release notes
   - Review and roll out

3. Add internal testers:
   - Create an email list of testers
   - Share the opt-in URL with them

### Using fastlane (automated):

Install fastlane:
```bash
gem install fastlane
cd android
fastlane init
```

Create `android/fastlane/Fastfile`:
```ruby
lane :internal do
  gradle(
    task: "bundle",
    flavor: "prod",
    build_type: "Release"
  )
  upload_to_play_store(
    track: 'internal',
    aab: '../build/app/outputs/bundle/prodRelease/app-prod-release.aab',
    skip_upload_metadata: true,
    skip_upload_images: true,
    skip_upload_screenshots: true
  )
end
```

Then run:
```bash
cd android
fastlane internal
```

## 6. Version Management

Update version in `pubspec.yaml`:
```yaml
version: 1.0.0+1
# Format: MAJOR.MINOR.PATCH+BUILD_NUMBER
```

- Version name: 1.0.0 (user-visible)
- Version code: 1 (incremental, Play Store requirement)

**Increment for each release:**
- Patch: Bug fixes (1.0.1+2)
- Minor: New features (1.1.0+3)
- Major: Breaking changes (2.0.0+4)

## 7. Testing Release Build

### Install on device:
```bash
# Development flavor
flutter install --flavor dev --release

# Production flavor
flutter install --flavor prod --release
```

### Verify signing:
```bash
# Check APK signature
jarsigner -verify -verbose -certs \
  build/app/outputs/flutter-apk/app-prod-release.apk

# Check bundle signature
jarsigner -verify -verbose -certs \
  build/app/outputs/bundle/prodRelease/app-prod-release.aab
```

### Test ProGuard obfuscation:
```bash
# Check if code is properly obfuscated
unzip -p build/app/outputs/flutter-apk/app-prod-release.apk classes.dex | dexdump /dev/stdin | grep "com.starbound"
```

## 8. Common Issues

### Issue: "Keystore file not found"
**Solution**: Check the path in environment variables or key.properties

### Issue: "Failed to read key from store"
**Solution**: Verify passwords are correct

### Issue: "Upload failed: Version code already used"
**Solution**: Increment the build number in pubspec.yaml

### Issue: "Resource shrinking failed"
**Solution**: Check ProGuard rules or disable with `isShrinkResources = false`

## 9. Security Checklist

Before releasing:
- [ ] Remove all debug logging
- [ ] Verify API keys are not hardcoded
- [ ] Check that .env is properly loaded
- [ ] Test with ProGuard enabled
- [ ] Verify network security config
- [ ] Test offline functionality
- [ ] Check SSL pinning (if implemented)
- [ ] Verify data encryption
- [ ] Test permission handling
- [ ] Review third-party dependencies

## 10. Play Store Release Checklist

- [ ] Update version number
- [ ] Build signed bundle
- [ ] Test on multiple devices
- [ ] Update release notes
- [ ] Prepare screenshots (see PLAY_STORE_METADATA.md)
- [ ] Update store listing
- [ ] Configure rollout percentage
- [ ] Monitor crash reports
- [ ] Monitor user reviews
- [ ] Plan rollback strategy
