# Servio Mobile App Setup Guide

## Prerequisites
- Flutter SDK (Latest Stable)
- Android Studio / Xcode (for simulators)
- VS Code (Recommended) with Flutter extensions

## Getting Started

1. **Navigate to the mobile directory:**
   ```bash
   cd mobile
   ```

2. **Install Dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run the App:**
   ```bash
   flutter run
   ```

## Project Structure

The project follows a **Feature-First** architecture:

```
lib/
├── src/
│   ├── core/               # App-wide configurations (Theme, Constants)
│   ├── features/           # Feature modules (Auth, Home, Services, etc.)
│   │   ├── auth/           # Login & Welcome screens
│   │   ├── home/           # Dashboard
│   │   ├── services/       # Service catalog
│   │   └── ...
│   ├── shared/             # Reusable widgets (Buttons, Inputs, Navbar)
│   ├── app.dart            # Main App Widget & Theme Setup
│   └── app_router.dart     # Navigation Configuration (GoRouter)
└── main.dart               # Entry Point
```

## State Management
We use **Riverpod** for state management.
- Use `ConsumerWidget` instead of `StatelessWidget` when you need access to providers.
- Use `ref.watch(provider)` to listen to changes.

## Navigation
We use **GoRouter** for navigation.
- Define routes in `lib/src/app_router.dart`.
- Navigate using `context.go('/path')` or `context.push('/path')`.

## Adding Assets
1. Place images in `assets/images/`.
2. Place icons in `assets/icons/`.
3. Register them in `pubspec.yaml`.

## Next Steps
- Implement screens based on Figma designs.
- Connect to the backend API.
