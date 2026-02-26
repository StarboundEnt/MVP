# Starbound Accessibility Audit & Implementation Checklist

## Overview
This document outlines accessibility requirements and current implementation status for Starbound. Our goal is WCAG 2.1 Level AA compliance.

---

## 1. Visual Accessibility

### Color & Contrast
- [ ] **Color contrast ratio ≥ 4.5:1 for normal text**
  - Status: Needs audit with design system colors
  - Action: Test all text/background combinations
  - Tool: Use WebAIM Contrast Checker

- [ ] **Color contrast ratio ≥ 3:1 for large text (18pt+)**
  - Status: Needs audit
  - Action: Verify headings and large UI elements

- [ ] **Don't rely solely on color to convey information**
  - Status: Partial - some status indicators use only color
  - Action: Add icons, patterns, or text labels
  - Example: Mood tracking should have icons + colors

- [ ] **Support for system color settings (dark mode, contrast)**
  - Status: Dark mode not implemented
  - Action: Implement dark theme variant
  - File: lib/design_system/colors.dart

### Text & Typography
- [ ] **Minimum font size 14sp for body text**
  - Status: Needs verification
  - File: lib/design_system/typography.dart

- [ ] **Scalable text (respects system font size)**
  - Status: Needs testing
  - Action: Test with iOS Dynamic Type and Android font scaling
  - Test: Settings → Display → Font Size

- [ ] **Clear font hierarchy (headings vs body)**
  - Status: ✓ Implemented via design system
  - File: lib/design_system/typography.dart

- [ ] **Avoid italic-only text for emphasis**
  - Status: Needs audit
  - Action: Use bold or combine bold + italic

### Visual Feedback
- [ ] **Focus indicators on interactive elements**
  - Status: Needs implementation
  - Action: Add focus borders/outlines for keyboard navigation
  - File: lib/design_system/components/

- [ ] **Visible loading states**
  - Status: ✓ Partial - cosmic_loading.dart
  - File: lib/design_system/components/cosmic_loading.dart

- [ ] **Error states clearly indicated**
  - Status: Needs audit
  - Action: Ensure errors have icons + color + text

---

## 2. Screen Reader Support

### Semantic Labels
- [ ] **All interactive elements have semantic labels**
  - Status: Partial
  - Action: Add Semantics widgets to custom components
  - Priority files:
    - lib/components/habit_card.dart
    - lib/components/nudge_banner.dart
    - lib/design_system/components/cosmic_button.dart

- [ ] **Images have alt text (Semantics label)**
  - Status: Needs audit
  - Action: Add semantic labels to all images and icons

- [ ] **Decorative images excluded from screen readers**
  - Status: Needs implementation
  - Action: Use `Semantics(container: true, excludeSemantics: true)`

- [ ] **Dynamic content announces changes**
  - Status: Needs implementation
  - Action: Use `SemanticsService.announce()` for updates
  - Examples: Habit completed, new nudge, sync status

### Navigation
- [ ] **Logical focus order (top to bottom, left to right)**
  - Status: Needs testing
  - Action: Test with screen reader navigation

- [ ] **Skip to main content (if applicable)**
  - Status: N/A for mobile app

- [ ] **Proper heading hierarchy (H1, H2, H3)**
  - Status: Needs implementation
  - Action: Use Semantics header: true

### Form Accessibility
- [ ] **All form inputs have labels**
  - Status: Partial
  - Files to audit:
    - lib/components/smart_input_widget.dart
    - lib/pages/onboarding_page.dart

- [ ] **Error messages associated with inputs**
  - Status: Needs implementation
  - Action: Use `semanticsLabel` for error text

- [ ] **Required fields clearly marked**
  - Status: Needs implementation
  - Action: Add "required" to labels, not just asterisks

---

## 3. Motor Accessibility

### Touch Targets
- [ ] **Minimum touch target size: 44x44 points (iOS) / 48x48dp (Android)**
  - Status: Needs audit
  - Action: Test all buttons, checkboxes, toggles
  - Files to check:
    - lib/components/habit_card.dart (habit completion button)
    - lib/components/interactive_tag_chip.dart
    - All icon buttons

- [ ] **Adequate spacing between touch targets (8dp minimum)**
  - Status: Needs audit
  - File: lib/design_system/spacing.dart

- [ ] **Support for alternative input methods (keyboard, switch control)**
  - Status: Needs testing
  - Action: Test keyboard navigation on Android
  - Action: Test Switch Control on iOS

### Gesture Alternatives
- [ ] **Swipe actions have alternatives**
  - Status: Needs audit
  - Action: Provide button alternatives to swipe-to-delete, etc.

- [ ] **No time-based interactions (or adjustable timeouts)**
  - Status: Needs audit
  - Action: Check for auto-dismissing dialogs/toasts

---

## 4. Cognitive Accessibility

### Content & Language
- [ ] **Clear, simple language (avoid jargon)**
  - Status: Needs review
  - Action: Content audit by UX writer

- [ ] **Consistent terminology throughout app**
  - Status: Needs audit
  - Action: Create glossary of terms

- [ ] **Clear error messages with solutions**
  - Status: Partial
  - Action: Review all error messages

### Navigation & Flow
- [ ] **Consistent navigation patterns**
  - Status: ✓ Bottom navigation bar
  - File: lib/main.dart

- [ ] **Clear page titles/headings**
  - Status: Needs audit
  - Action: Ensure all pages have AppBar with title

- [ ] **Breadcrumb navigation (if deep hierarchy)**
  - Status: N/A for current flat structure

### Reduce Cognitive Load
- [ ] **Break complex tasks into steps**
  - Status: ✓ Onboarding is multi-step
  - File: lib/pages/onboarding_page.dart

- [ ] **Provide clear progress indicators**
  - Status: Partial
  - Action: Add progress bars to multi-step flows

- [ ] **Allow users to review before submit**
  - Status: Needs implementation
  - Example: Review journal entry before saving

---

## 5. Audio & Video Accessibility

### Media Accessibility
- [ ] **Captions for video content**
  - Status: N/A - no videos currently

- [ ] **Transcripts for audio content**
  - Status: N/A - no audio content

- [ ] **Audio descriptions (if applicable)**
  - Status: N/A

### Sound & Haptics
- [ ] **Don't rely solely on sound for feedback**
  - Status: Needs audit
  - Action: Pair sounds with visual feedback

- [ ] **Haptic feedback for key actions**
  - Status: Needs implementation
  - Action: Add HapticFeedback calls
  - Example: Habit completion, nudge dismissed

---

## 6. Testing Requirements

### Manual Testing
- [ ] **Test with TalkBack (Android)**
  - Action: Enable TalkBack in Settings → Accessibility
  - Test all major user flows

- [ ] **Test with VoiceOver (iOS)**
  - Action: Enable VoiceOver in Settings → Accessibility
  - Test all major user flows

- [ ] **Test with keyboard navigation (Android)**
  - Action: Connect Bluetooth keyboard
  - Navigate using Tab, Enter, Arrow keys

- [ ] **Test with large text sizes**
  - Android: Settings → Display → Font size (Largest)
  - iOS: Settings → Accessibility → Larger Text (Max)

- [ ] **Test with reduced motion**
  - Android: Settings → Accessibility → Remove animations
  - iOS: Settings → Accessibility → Reduce Motion

- [ ] **Test with high contrast**
  - iOS: Settings → Accessibility → Increase Contrast

### Automated Testing
- [ ] **Run Flutter accessibility scanner**
  ```dart
  testWidgets('meets accessibility guidelines', (tester) async {
    await tester.pumpWidget(MyApp());
    await expectLater(tester, meetsGuideline(textContrastGuideline));
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  });
  ```

- [ ] **Lint for accessibility issues**
  - Add to analysis_options.yaml:
  ```yaml
  linter:
    rules:
      - use_semantics
      - avoid_returning_null_for_void
  ```

---

## 7. Implementation Priorities

### High Priority (Before Launch)
1. Add semantic labels to all interactive elements
2. Ensure minimum touch target sizes (44x44 / 48x48)
3. Test with screen readers (VoiceOver + TalkBack)
4. Verify color contrast ratios
5. Add focus indicators
6. Test with large text sizes

### Medium Priority (v1.1)
1. Implement dark mode
2. Add haptic feedback
3. Review and simplify language
4. Add progress indicators to multi-step flows
5. Implement dynamic announcements

### Low Priority (v1.2+)
1. Add customizable color themes
2. Implement advanced keyboard shortcuts
3. Add voice commands
4. Support for external switches

---

## 8. Specific File Actions

### lib/design_system/components/cosmic_button.dart
```dart
// Add semantic label
Semantics(
  button: true,
  enabled: enabled,
  label: semanticLabel ?? label,
  child: GestureDetector(...),
)
```

### lib/components/habit_card.dart
```dart
// Add semantic actions
Semantics(
  label: 'Habit: ${habit.name}. Completed ${habit.completionCount} times',
  customSemanticsActions: {
    CustomSemanticsAction(label: 'Complete habit'): () => onComplete(),
    CustomSemanticsAction(label: 'Edit habit'): () => onEdit(),
  },
  child: ...,
)
```

### lib/components/nudge_banner.dart
```dart
// Announce when new nudge appears
SemanticsService.announce(
  'New suggestion: ${nudge.message}',
  TextDirection.ltr,
);
```

---

## 9. Resources

### Tools
- **Contrast Checker**: https://webaim.org/resources/contrastchecker/
- **Color Blind Simulator**: https://www.color-blindness.com/coblis-color-blindness-simulator/
- **Flutter Accessibility**: https://docs.flutter.dev/development/accessibility-and-localization/accessibility

### Guidelines
- **WCAG 2.1**: https://www.w3.org/WAI/WCAG21/quickref/
- **iOS Accessibility**: https://developer.apple.com/accessibility/
- **Android Accessibility**: https://developer.android.com/guide/topics/ui/accessibility
- **Material Design Accessibility**: https://material.io/design/usability/accessibility.html

### Testing
- **Accessibility Scanner (Android)**: https://play.google.com/store/apps/details?id=com.google.android.apps.accessibility.auditor
- **Xcode Accessibility Inspector**: Xcode → Open Developer Tool → Accessibility Inspector

---

## 10. Success Criteria

App is considered accessible when:
- [x] All automated tests pass
- [x] Manual testing with screen readers succeeds
- [x] All critical user flows work with assistive technology
- [x] WCAG 2.1 Level AA compliance achieved
- [x] User testing with people with disabilities completed
- [x] Accessibility statement published

---

## Contact

Accessibility feedback: accessibility@starbound.app

We welcome feedback from users with disabilities to improve our app.
