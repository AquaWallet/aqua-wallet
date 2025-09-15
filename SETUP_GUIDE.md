# Aqua Wallet First-Time Setup Guide

This guide provides the minimal necessary steps to compile and run the Aqua Wallet application on Android.

### 1. Set Up Environment Variables

First, you need to create a `.env` file to store the necessary environment variables. You can do this by copying the example file:

```bash
cp .env.example .env
```

### 2. Configure the Build Runner

Open the `build.yaml` file and add the following configuration for the `envied_generator`. This tells the build runner where to find your `.env` file.

```yaml
targets:
  $default:
    builders:
      json_serializable|json_serializable:
        options:
          # Options configure how source code is generated for every
          # `@JsonSerializable`-annotated class in the package.
          #
          # The default value for each is listed.
          any_map: true
          checked: false
          create_factory: true
          create_to_json: true
          disallow_unrecognized_keys: false
          explicit_to_json: false
          field_rename: none
          ignore_unannotated: false
          include_if_null: false
      envied_generator|envied:
        options:
          path: .env
      freezed|freezed:
        generate_for:
          - lib/**/*.dart
```

### 3. Fetch Native Dependencies

The project relies on native libraries that are not included in the repository. You can fetch them by running the following commands from the project root:

```bash
make get-gdk
make get-boltz-rust
```

### 4. Generate FFI Bindings

Next, you need to generate the Dart FFI (Foreign Function Interface) bindings for the native libraries. This is done using the `ffigen` tool.

First, open the `ffigen.yaml` file and add the following line to the `compiler-opts` section to suppress nullability warnings:

```yaml
  - "-Wno-nullability-completeness"
```

Then, run the following command to generate the bindings:

```bash
make generate-bindings
```

### 5. Generate Code with Build Runner

The project uses code generation to create necessary files. Run the following command to generate them:

```bash
/path/to/your/flutter pub run build_runner build --delete-conflicting-outputs
```
*Replace `/path/to/your/flutter` with the actual path to your Flutter SDK.*

### 6. Generate a Signing Key

To build the Android application, you need to generate a signing key. First, create a `key.properties` file in the `android/android_keys` directory with the following content:

```
keyAlias=aqua
keyPassword=password
storePassword=password
```

Then, create the `android/android_keys` directory if it doesn't exist:

```bash
mkdir -p android/android_keys
```

Finally, generate the `keystore.jks` file using the following command:

```bash
keytool -genkey -v -keystore android/android_keys/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias aqua -storepass password -keypass password -dname "CN=aqua, OU=aqua, O=aqua, L=aqua, S=aqua, C=US"
```

### 7. Run the Application

Now you are ready to run the application. Use the following command, making sure to replace `/path/to/your/flutter` with the actual path to your Flutter SDK:

```bash
/path/to/your/flutter run
```

This will build and launch the application on your connected device or emulator.
