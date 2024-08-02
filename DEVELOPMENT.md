# Documentation for developers

# Setup

We use Nix package manager for reproducible dev environment. Make sure you have Nix installed, then:

1. Run `make shell` to build shell environment with all system dependencies.

2. **Only for Linux users**: Search for `Linux build:` in `gdk.dart` and `pubspec.yaml`, then follow instructions.

3. Run `make setup` (run it whenever you pull from upstream.)

- `make setup` pulls all the dependencies configured in `pubspec.yaml` as well as pre-built binaries for GDK as well as `boltz-rust`.
- The source for `GDK` can be found in https://github.com/Blockstream/gdk . Instead of using the pre-built binaries you can build it from source and use it as well.
- The source for `boltz-rust` can be found in https://github.com/AquaWallet/boltz-rust which can also be built from source.

# Run the app from source

## Run the emulator

Start your prefered emulator, then run app with:

```bash
flutter run
```
or through VSCODE: Run -> Start debugging (F5)

## IOS

Verify that GDK has been patched by the `make patch-ios-sim` command (this folder `crypto/gdk-iphonesim-x86_64` should exist).

You can open emulator through Xcode, or from command-line: `make run-ios-emulator-mac`

# Troubleshooting

- Always run commands from `Makefile` unless a dedicated command is not available there.
- Changing Flutter version might require `flutter clean` and `vscode` restart to pick-up the correct version.

## Testing on various screen sizes

Device Preview dependency can be enabled with an environment variable named `DEVICE_PREVIEW` using `--dart-define` flag with the `flutter run` command. The same can be acheive in VS Code by adding `toolArgs` in the `launch.json` file:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "aqua",
      "request": "launch",
      "type": "dart",
      "toolArgs": ["--dart-define", "DEVICE_PREVIEW=true"]
    }
  ]
}
```
