# AGENTS.md - AI Agent Guidelines for AQUA Wallet

## Build Commands

**Note:** Always run flutter commands from the `flutter/` submodule folder.

```bash
# Setup (run after pulling from upstream)
make setup

# Install dependencies
flutter pub get
# OR
make install

# Run code generation (Freezed, Isar, JSON serializable, Riverpod)
dart run build_runner build --delete-conflicting-outputs
# OR
make freeze

# Generate FFI bindings
dart run ffigen --ignore-source-errors

# Generate assets (icons, splash screen)
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

## Test Commands

```bash
# Run all unit tests with coverage
make run-unit-tests

# Run a single test file
flutter test test/features/send/providers/new/send_asset_input_provider_test.dart

# Run tests matching a pattern
flutter test --name="sendAsset"

# Run integration tests
make run-integration-tests

# Run all tests (unit + integration)
make test-all
```

## Lint Commands

```bash
# Analyze code
flutter analyze

# Format code
dart format lib/ test/

# Check for unused localizations
make unused-localizations
```

## Code Style Guidelines

### General Principles
- Write concise, technical Dart code with accurate examples
- Use functional and declarative programming patterns
- Prefer composition over inheritance
- Use descriptive variable names with auxiliary verbs (e.g., `isLoading`, `hasError`)
- Structure files: exported widget, subwidgets, helpers, static content, types

### Dart/Flutter
- Use `const` constructors for immutable widgets
- Leverage Freezed for immutable state classes and unions
- Use arrow syntax for simple functions and methods
- Prefer expression bodies for one-line getters and setters
- Use trailing commas for better formatting and diffs
- Use `log` instead of `print` for debugging

### Imports
- Use barrel files (e.g., `features/shared/shared.dart`) for clean imports
- Group imports: Dart SDK, Flutter, third-party, local (aqua), ui_components
- Use `package:aqua/` prefix for all local imports

### Types & Naming
- Use Freezed sealed unions for state unless the state type is primitive
- Use `@JsonSerializable(fieldRename: FieldRename.snake)` for models
- Use `@JsonKey(includeFromJson: true, includeToJson: false)` for read-only fields
- Use `@JsonValue(int)` for enums that go to the database
- Include `createdAt`, `updatedAt`, and `isDeleted` fields in database tables

### Error Handling
- Use `AsyncValue` for proper error handling and loading states
- Handle empty states within the displaying screen
- Implement proper cancellation of asynchronous operations when widgets are disposed

### Riverpod Guidelines
- Prefer using `ChangeNotifier`, `StateNotifier`, and `AsyncNotifier`
- Avoid using `StateProvider`, `FutureProvider`, and `StreamProvider`
- Use `ref.invalidate()` for manually triggering provider updates
- Do not expose methods that return values in Riverpod notifiers
- Keep notifier's state as private as possible
- Do not pass `Ref` to service classes - inject concrete dependencies instead

### Service Classes
- Services should be independent of state management implementation
- Use dependency injection through constructors
- Keep services focused on a single responsibility
- Handle cleanup in the provider, not the service

### Widgets & UI
- Use `ConsumerWidget` with Riverpod for state-dependent widgets
- Use `HookConsumerWidget` when combining Riverpod and Flutter Hooks
- Create small, private widget classes instead of methods like `Widget _build...`
- Use private `StatelessWidget` or `ConsumerWidget` classes instead of widget-building functions
- Use `Theme.of(context).textTheme.titleLarge` instead of deprecated `headline6`
- Implement `RefreshIndicator` for pull-to-refresh functionality
- Always include an `errorBuilder` when using `Image.network`

### Performance
- Use const widgets where possible to optimize rebuilds
- Implement list view optimizations using value keys and pagination
- Use `AssetImage` for static images and `cached_network_image` for remote images

### Testing
- Use Mocktail for mocking dependencies
- Use existing mocks in `test/mocks/`, create new mocks there for reuse
- Use `createContainer()` helper from `test/helpers.dart` for provider testing

### Database (Isar)
- Use Isar for local database
- Include `createdAt`, `updatedAt`, and `isDeleted` fields in all tables

### Navigation
- Use GoRouter for navigation and deep linking

## Project Structure

```
lib/
  common/          # Shared utilities, extensions
  config/          # Configuration, router
  data/            # Data providers, repositories
  features/        # Feature modules (home, wallet, send, receive, etc.)
  l10n/            # Localization
  services/        # App-level services
  utils/           # Utility functions
  ffi/             # FFI generated bindings (excluded from linting)
  gen/             # Generated code (excluded from linting)
test/
  mocks/           # Mock classes for testing
  fixtures/        # Test fixtures
  features/        # Feature-specific tests
  helpers.dart     # Test utilities
```

## Excluded from Analysis

- `lib/ffi/**`
- `lib/gen/**`
- `**/*.g.dart`
- `**/*.freezed.dart`
- `flutter/**`
- `packages/**/`

## Environment Setup

1. Run `make shell` to enter Nix development environment
2. Copy `.env.example` to `.env` and fill in values
3. Run `make setup` to install dependencies and binaries

## Flutter/Dart Versions

Check `pubspec.yaml` for current SDK and Flutter version requirements.
