# Servio Mobile App Architecture

## Overview
The Servio mobile application is built using **Flutter** and follows a **Feature-First** architecture. This ensures scalability, maintainability, and clear separation of concerns.

## Tech Stack
- **Framework**: Flutter (Dart)
- **State Management**: Riverpod (Hooks & Code Generation)
- **Navigation**: GoRouter (Declarative Routing)
- **Networking**: Dio (HTTP Client) - *To be implemented*
- **Local Storage**: Shared Preferences / Flutter Secure Storage - *To be implemented*

## Directory Structure
The `lib/src` directory is organized by features:

```
lib/src/
├── core/               # App-wide core functionality
│   ├── theme/          # App theme and color palette
│   ├── constants/      # App constants (API keys, URLs)
│   └── utils/          # Helper functions and extensions
│
├── features/           # Feature modules
│   ├── auth/           # Authentication (Login, Signup)
│   ├── home/           # Home Dashboard
│   ├── services/       # Service Catalog
│   ├── bookings/       # Activity/Bookings
│   └── profile/        # User Profile
│
├── shared/             # Shared UI components and widgets
│   ├── widgets/        # Reusable widgets (Buttons, Inputs)
│   └── scaffold_with_navbar.dart # Bottom Navigation Shell
│
├── app.dart            # Main App Widget
└── app_router.dart     # Router Configuration
```

## Key Components

### 1. State Management (Riverpod)
We use Riverpod for dependency injection and state management.
- **Providers**: Define shared state or dependencies.
- **ConsumerWidget**: UI components that listen to providers.

### 2. Navigation (GoRouter)
- **ShellRoute**: Used for the Bottom Navigation Bar to keep it persistent across tabs.
- **GoRoute**: Defines individual screens.

### 3. Theming
- Custom theme defined in `app.dart`.
- Uses `GoogleFonts` for typography.
- `ColorScheme` derived from the primary Servio Orange (`#FF5D2E`).

## Implementation Guidelines
- **New Features**: Create a new folder in `features/`.
- **UI Components**: Place reusable widgets in `shared/widgets/`.
- **Logic**: Use Riverpod providers for business logic, keeping UI code clean.
