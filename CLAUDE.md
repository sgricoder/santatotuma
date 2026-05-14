# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

```bash
# Run the app (defaults to connected device or Chrome)
flutter run

# Run on a specific platform
flutter run -d chrome        # Web
flutter run -d windows       # Windows desktop
flutter run -d android       # Android emulator/device

# Build
flutter build apk            # Android APK
flutter build web            # Web (output in build/web/)
flutter build windows        # Windows

# Tests
flutter test                 # All tests
flutter test test/widget_test.dart  # Single test file

# Lint / analysis
flutter analyze

# Format
dart format lib/
```

## Architecture

This is a Flutter multi-platform app targeting Android, iOS, Web, and Desktop (Windows/Linux/macOS). The project is in early development — currently only the default counter scaffold exists in [lib/main.dart](lib/main.dart).

- **Entry point**: `lib/main.dart` — `main()` → `runApp(MyApp())`
- **Platform configs**: `android/`, `ios/`, `macos/`, `windows/`, `linux/`, `web/` — each contains platform-specific build configuration
- **Dependencies**: declared in [pubspec.yaml](pubspec.yaml); run `flutter pub get` after changes
- **Linting**: `analysis_options.yaml` uses `flutter_lints` defaults; run `flutter analyze` to check

State management, routing, and feature code have not yet been added. When expanding, add new Dart files under `lib/` organized by feature or layer.
