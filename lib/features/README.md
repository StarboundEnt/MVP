# Feature-Based Architecture for Starbound

This directory contains the feature-based architecture implementation for the Starbound health app. Each feature is organized into its own domain with clear separation of concerns.

## Architecture Overview

```
features/
├── shared/
│   ├── data/          # Shared data sources, repositories
│   ├── domain/        # Shared entities, value objects, use cases
│   └── presentation/  # Shared UI components, themes
├── habits/
│   ├── data/          # Habit-specific data layer
│   ├── domain/        # Habit business logic
│   └── presentation/  # Habit UI components
├── analytics/
│   ├── data/          # Analytics data layer
│   ├── domain/        # Analytics business logic
│   └── presentation/  # Analytics UI components
├── notifications/
│   ├── data/          # Notification data layer
│   ├── domain/        # Notification business logic
│   └── presentation/  # Notification UI components
└── user/
    ├── data/          # User data layer
    ├── domain/        # User business logic
    └── presentation/  # User UI components
```

## Principles

### 1. Clean Architecture
Each feature follows Clean Architecture principles:
- **Domain Layer**: Contains business logic, entities, and use cases
- **Data Layer**: Handles data persistence and external APIs
- **Presentation Layer**: Contains UI components and state management

### 2. Feature Independence
- Features should be as independent as possible
- Shared functionality goes in the `shared/` directory
- Dependencies flow inward (presentation → domain ← data)

### 3. Testability
- Each layer is easily testable in isolation
- Business logic is pure and doesn't depend on Flutter
- Repository pattern abstracts data sources

### 4. Scalability
- New features can be added without affecting existing ones
- Code is organized by feature rather than technical concerns
- Clear boundaries prevent feature bleeding

## Migration from AppState

The original `AppState` class has been broken down into feature-specific providers:

- `HabitsProvider` - Manages habit state and operations
- `AnalyticsProvider` - Handles analytics and insights
- `UserProvider` - Manages user profile and settings
- `NotificationsProvider` - Handles nudges and notifications

## Usage Examples

### Accessing Feature Providers

```dart
// Access habits functionality
final habitsProvider = context.read<HabitsProvider>();
await habitsProvider.updateHabit(habitId, status);

// Access analytics
final analyticsProvider = context.read<AnalyticsProvider>();
final insights = await analyticsProvider.getInsights();

// Access user settings
final userProvider = context.read<UserProvider>();
await userProvider.updateComplexityProfile(newProfile);
```

### Creating New Features

1. Create feature directory: `features/new_feature/`
2. Add data, domain, and presentation layers
3. Register provider in main.dart
4. Add to dependency injection

## Dependencies

Features can depend on:
- `shared/` components
- Other features through well-defined interfaces
- External packages (with careful consideration)

## Testing Strategy

Each feature should have:
- Unit tests for domain logic
- Widget tests for UI components
- Integration tests for complete workflows
- Mock implementations for dependencies

## Migration Guide

To migrate existing code to the new architecture:

1. **Identify Feature Boundaries**: Group related functionality
2. **Extract Domain Logic**: Move business rules to domain layer
3. **Create Repositories**: Abstract data access patterns
4. **Update Providers**: Replace monolithic state with feature providers
5. **Update UI**: Use new providers and components
6. **Add Tests**: Ensure coverage for each layer

## Benefits

- **Maintainability**: Code is easier to understand and modify
- **Testability**: Each component can be tested in isolation
- **Scalability**: New features don't affect existing ones
- **Team Collaboration**: Multiple developers can work on different features
- **Code Reusability**: Shared components reduce duplication