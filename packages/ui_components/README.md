A reusable component library based on AQUA design system.

## Getting started

Add the dependency to your `pubspec.yaml` file:

```yaml
dependencies:
  ui_components:
    path: packages/ui_components
```

## Usage

To use the components, you need to import the package in your Dart file:

```dart
import 'package:ui_components/ui_components.dart';
```

## Fonts

This package includes custom fonts that need to be declared in your app's `pubspec.yaml` file:

```yaml
flutter:
  fonts:
    - family: RobotoMono
      fonts:
        - asset: assets/fonts/roboto_mono/RobotoMono-Regular.ttf
          weight: 400
        - asset: assets/fonts/roboto_mono/RobotoMono-Medium.ttf
          weight: 500
        - asset: assets/fonts/roboto_mono/RobotoMono-SemiBold.ttf
          weight: 600

    - family: Inter
      fonts:
        - asset: packages/ui_components/assets/fonts/inter/Inter-Regular.ttf
          weight: 400
        - asset: packages/ui_components/assets/fonts/inter/Inter-Medium.ttf
          weight: 500
        - asset: packages/ui_components/assets/fonts/inter/Inter-SemiBold.ttf
          weight: 600
        - asset: packages/ui_components/assets/fonts/inter/Inter-Bold.ttf
          weight: 700
```
