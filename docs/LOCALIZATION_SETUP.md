# Localization Setup Guide

## Overview

Starbound uses Flutter's official localization system with ARB (Application Resource Bundle) files for internationalization.

---

## 1. Setup Dependencies

### Add to pubspec.yaml

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter
  intl: any

flutter:
  generate: true
```

### Create l10n.yaml in project root

```yaml
arb-dir: l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
```

---

## 2. ARB File Structure

### Current Files

- `l10n/app_en.arb` - English (base language)

### Add New Languages

Create additional ARB files:
- `l10n/app_es.arb` - Spanish
- `l10n/app_fr.arb` - French
- `l10n/app_de.arb` - German
- `l10n/app_pt.arb` - Portuguese

### Example: Spanish (app_es.arb)

```json
{
  "@@locale": "es",
  "appName": "Starbound",
  "appTagline": "Tu Compañero de Salud Inteligente",
  "welcomeMessage": "Bienvenido a Starbound",
  "getStarted": "Comenzar",
  "navHome": "Inicio",
  "navJournal": "Diario",
  "navAnalytics": "Análisis",
  "navSettings": "Configuración"
}
```

---

## 3. Integration with Flutter App

### Update lib/main.dart

```dart
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // Localization delegates
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Supported locales
      supportedLocales: const [
        Locale('en', ''), // English
        Locale('es', ''), // Spanish
        Locale('fr', ''), // French
        Locale('de', ''), // German
        Locale('pt', ''), // Portuguese
      ],

      // Optional: Set default locale
      locale: const Locale('en'),

      // App content
      home: HomePage(),
    );
  }
}
```

---

## 4. Using Localized Strings

### In Widgets

```dart
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.navHome),
      ),
      body: Column(
        children: [
          Text(l10n.welcomeMessage),
          ElevatedButton(
            onPressed: () {},
            child: Text(l10n.getStarted),
          ),
        ],
      ),
    );
  }
}
```

### With Placeholders

```dart
// In ARB file
{
  "habitCompletedCount": "{count} habits completed",
  "@habitCompletedCount": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}

// In code
final message = l10n.habitCompletedCount(5); // "5 habits completed"
```

### With Plurals

```dart
// In ARB file
{
  "streakDays": "{count, plural, =1{1 day} other{{count} days}}",
  "@streakDays": {
    "placeholders": {
      "count": {
        "type": "int"
      }
    }
  }
}

// In code
final streak = l10n.streakDays(1); // "1 day"
final streak = l10n.streakDays(7); // "7 days"
```

---

## 5. Translation Workflow

### Step 1: Extract Strings

All user-facing strings should be in ARB files, not hardcoded.

**Before:**
```dart
Text('Add Habit')
```

**After:**
```dart
Text(l10n.addHabit)
```

### Step 2: Add to Base ARB (app_en.arb)

```json
{
  "addHabit": "Add Habit",
  "@addHabit": {
    "description": "Button text to add a new habit"
  }
}
```

### Step 3: Generate Localizations

```bash
flutter gen-l10n
# or
flutter pub get
```

This generates:
- `.dart_tool/flutter_gen/gen_l10n/app_localizations.dart`
- Locale-specific files for each ARB file

### Step 4: Translate to Other Languages

Send ARB files to translators or use translation service:
- Manual translation
- Professional service (e.g., Lokalise, Crowdin)
- Machine translation (for initial draft)

---

## 6. Testing Localizations

### Change Device Language

**iOS Simulator:**
1. Settings → General → Language & Region
2. Add Language → Select language
3. Restart app

**Android Emulator:**
1. Settings → System → Languages & input
2. Languages → Add a language
3. Restart app

### Programmatic Testing

```dart
testWidgets('displays Spanish text', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('es'),
      home: HomePage(),
    ),
  );

  expect(find.text('Inicio'), findsOneWidget); // "Home" in Spanish
});
```

---

## 7. Best Practices

### DO:
- ✅ Use descriptive key names (`addHabit` not `btn1`)
- ✅ Add `@description` for translators' context
- ✅ Extract ALL user-visible strings
- ✅ Use placeholders for dynamic values
- ✅ Handle plurals properly
- ✅ Test with long strings (German, Finnish)
- ✅ Support RTL languages (Arabic, Hebrew) if needed

### DON'T:
- ❌ Hardcode strings in UI
- ❌ Concatenate translated strings
- ❌ Use string interpolation for sentences
- ❌ Assume English word order in other languages

---

## 8. Translation Checklist

### Pre-Translation
- [ ] All strings extracted to ARB files
- [ ] Descriptions added for context
- [ ] Placeholders properly defined
- [ ] Plural forms identified

### Translation
- [ ] Base language (English) complete
- [ ] Priority languages translated
  - [ ] Spanish
  - [ ] French
  - [ ] German
  - [ ] Portuguese
- [ ] Translations reviewed by native speakers

### Post-Translation
- [ ] Generated files committed to repo
- [ ] UI tested with each locale
- [ ] Text truncation/overflow fixed
- [ ] Date/number formatting localized

---

## 9. Locale-Specific Formatting

### Dates

```dart
import 'package:intl/intl.dart';

// Automatic locale detection
final now = DateTime.now();
final formattedDate = DateFormat.yMMMd().format(now);
// English: Jan 15, 2025
// Spanish: 15 ene 2025
```

### Numbers

```dart
import 'package:intl/intl.dart';

final number = 1234.56;
final formatted = NumberFormat.decimalPattern().format(number);
// English: 1,234.56
// German: 1.234,56
```

### Currency

```dart
import 'package:intl/intl.dart';

final price = 99.99;
final formatted = NumberFormat.simpleCurrency().format(price);
// USD: $99.99
// EUR: €99.99
```

---

## 10. RTL (Right-to-Left) Support

For Arabic, Hebrew, etc.

### Add RTL Locales

```dart
supportedLocales: const [
  Locale('en', ''),
  Locale('ar', ''), // Arabic (RTL)
  Locale('he', ''), // Hebrew (RTL)
],
```

### Auto-Detection

Flutter automatically handles text direction:
```dart
Directionality(
  textDirection: Directionality.of(context),
  child: YourWidget(),
)
```

### Testing RTL

In developer options:
- Android: Settings → Developer Options → Force RTL
- iOS: Settings → Developer → RTL Layout

---

## 11. Priority Languages (Phased Rollout)

### Phase 1 (Launch)
- English (en) - Base language

### Phase 2 (1-2 months post-launch)
- Spanish (es) - 2nd largest user base
- Portuguese (pt) - Brazilian market

### Phase 3 (3-6 months)
- French (fr)
- German (de)
- Italian (it)

### Phase 4 (6-12 months)
- Japanese (ja)
- Korean (ko)
- Simplified Chinese (zh)

### Future
- Arabic (ar)
- Hindi (hi)
- Russian (ru)

---

## 12. Translation Services

### Professional Services
- **Lokalise** - https://lokalise.com
  - Integrates with development workflow
  - Translation memory
  - Supports ARB format

- **Crowdin** - https://crowdin.com
  - Community translations
  - Quality assurance tools

- **POEditor** - https://poeditor.com
  - Simple interface
  - API for automation

### Cost-Effective Options
- **Google Translate API** - Initial drafts
- **Community translations** - For open-source projects
- **Freelance translators** - Fiverr, Upwork

---

## 13. Continuous Localization

### CI/CD Integration

```yaml
# .github/workflows/localization.yml
name: Update Localizations

on:
  push:
    paths:
      - 'l10n/*.arb'

jobs:
  generate:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: subosito/flutter-action@v2
      - run: flutter gen-l10n
      - name: Commit generated files
        run: |
          git config user.name github-actions
          git config user.email github-actions@github.com
          git add .dart_tool/flutter_gen
          git commit -m "Update generated localizations"
          git push
```

---

## 14. Accessibility + Localization

Ensure screen readers work properly:

```dart
Semantics(
  label: l10n.addHabit, // Localized semantic label
  button: true,
  child: IconButton(
    icon: Icon(Icons.add),
    onPressed: () {},
  ),
)
```

---

## 15. Resources

- **Flutter i18n Guide**: https://docs.flutter.dev/development/accessibility-and-localization/internationalization
- **ARB Format Spec**: https://github.com/google/app-resource-bundle
- **Intl Package**: https://pub.dev/packages/intl
- **Locale Codes**: https://www.localeplanet.com/icu/

---

## Support

For localization questions: i18n@starbound.app

To contribute translations: https://github.com/starbound/translations
