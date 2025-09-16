# Aqua Wallet First-Time Setup Guide

This guide provides the minimal necessary steps to compile and run the **Aqua Wallet** application on Android.

---

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) installed
- [Dart](https://dart.dev/get-dart) available in your PATH
- Android SDK & emulator or a physical device connected
- `make` installed (for running dependency commands)
- Also change Flutter path in the `MakeFile` with the local installed required flutter version path.

---

## 1. Set Up Environment Variables

First, create a `.env` file to store the necessary environment variables.  
You can do this by copying the example file:

```bash
cp .env.example .env
```

---


## 2. Fetch Native Dependencies

The project relies on native Rust libraries (`boltz_rust`) that must be compiled locally.  
To install Rust and Cargo, run the following command:

```bash
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
```
---

The project relies on native libraries that are not included in the repository.  
Fetch them by running the following commands from the project root:


```bash
make get-gdk && make get-boltz-rust && make generate-bindings
```

---

## 3. Generate Code with Build Runner

The project uses code generation to create necessary files.  
Run the following command to generate them:

```bash
/path/to/your/flutter pub run build_runner build --delete-conflicting-outputs
```

> 💡 Replace `/path/to/your/flutter` with the path to your Flutter binary if not already in your PATH.

---

## 4. Run the Application

After completing the above steps, you can run the application on Android:

```bash
flutter run
```

---

## Notes

- Make sure your emulator or physical device is running before executing `flutter run`.
- If you run into build issues, try cleaning the project:

```bash
flutter clean
```

---

✨ You’re now ready to use **Aqua Wallet** on Android!
