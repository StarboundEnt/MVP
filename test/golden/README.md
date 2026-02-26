# Golden Test Files

This directory contains golden test files for visual regression testing.

## What are Golden Tests?

Golden tests (also known as snapshot tests) capture the rendered output of widgets and compare them against previously approved "golden" images. This helps catch unintentional visual changes.

## Running Golden Tests

To run golden tests:

```bash
# Run all tests including golden tests
flutter test

# Run only golden tests
flutter test --tags golden

# Update golden files when UI changes are intentional
flutter test --update-goldens
```

## File Organization

```
golden/
├── components/           # Component-level golden tests
│   ├── bottom_nav/
│   ├── buttons/
│   └── cards/
├── pages/               # Full page golden tests
│   ├── home_page/
│   ├── habit_tracker/
│   └── onboarding/
└── themes/              # Theme-based golden tests
    ├── dark_theme/
    └── light_theme/
```

## Best Practices

1. **Keep golden files small**: Test individual components rather than entire screens when possible
2. **Use descriptive names**: Include device type, theme, and state in file names
3. **Test different states**: Test components in various states (loading, error, success)
4. **Test responsiveness**: Include tests for different screen sizes
5. **Update carefully**: Only update golden files when visual changes are intentional

## Naming Convention

Use the following naming pattern for golden test files:
```
component_name_device_theme_state.png
```

Examples:
- `bottom_nav_phone_dark_active.png`
- `habit_card_tablet_light_completed.png`
- `loading_spinner_phone_dark_animating.png`

## Troubleshooting

### Golden tests failing after dependency updates
1. Check if the visual changes are expected
2. If expected, update goldens: `flutter test --update-goldens`
3. If unexpected, investigate the dependency causing the change

### Platform-specific differences
- Golden tests may produce slightly different results on different platforms
- Use CI/CD with consistent environment for reliable golden testing
- Consider platform-specific golden files if necessary

### Performance considerations
- Golden tests can be slower than unit tests
- Run them in CI/CD but consider excluding from quick local test runs
- Use `testWidgets` with `tags` to control when golden tests run