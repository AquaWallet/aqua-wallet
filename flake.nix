{
  description = "AQUA dev environment";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachSystem [ "x86_64-linux" "aarch64-darwin" "x86_64-darwin" ] (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          android_sdk.accept_license = true;
        };
        lib = pkgs.lib;
        androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
        androidComposition = androidEnv.composeAndroidPackages {
          cmdLineToolsVersion = "8.0"; # emulator related: newer versions are not only compatible with avdmanager
          platformToolsVersion = "34.0.4";
          buildToolsVersions = [ "30.0.3" "33.0.2" "34.0.0" ];
          platformVersions = [ "29" "30" "31" "32" "33" "34" ];
          abiVersions = [ "x86_64" ]; # emulator related: on an ARM machine, replace "x86_64" with
          # either "armeabi-v7a" or "arm64-v8a", depending on the architecture of your workstation.
          cmakeVersions = [ "3.22.1" ];
          includeNDK = true;
          ndkVersions = ["23.1.7779620"];
          includeSystemImages = false; # needed for the emulator.
          systemImageTypes = [ "google_apis" "google_apis_playstore" ];
          includeEmulator = false; # You can enable on Linux to get emulator support. Still not working on mac.
          useGoogleAPIs = true;
          extraLicenses = [
            "android-googletv-license"
            "android-sdk-arm-dbt-license"
            "android-sdk-license"
            "android-sdk-preview-license"
            "google-gdk-license"
            "intel-android-extra-license"
            "intel-android-sysimage-license"
            "mips-android-sysimage-license"            ];
        };
        androidSdk = androidComposition.androidsdk;
      in
      {
        devShell = with pkgs; mkShellNoCC rec {
          ANDROID_HOME = "${androidSdk}/libexec/android-sdk";
          ANDROID_SDK_ROOT = "${androidSdk}/libexec/android-sdk";
          JAVA_HOME = jdk17.home;
          GRADLE_OPTS = "-Dorg.gradle.project.android.aapt2FromMavenOverride=${androidSdk}/libexec/android-sdk/build-tools/33.0.2/aapt2";
          buildInputs = [
            llvmPackages.libclang
            llvmPackages.libcxxClang
            clang
            glibc.dev

            androidSdk
            qemu_kvm
            gradle
            jdk17

            rustup
          ];
          # emulator related: vulkan-loader and libGL shared libs are necessary for hardware decoding
          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [vulkan-loader libGL]}";

          LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";
          CLANG_INCLUDE = "${llvmPackages.libclang.lib}/lib/clang/${lib.versions.major llvmPackages.clang.version}/include";
          GLIBC_INCLUDE = "${pkgs.glibc.dev}/include";

          # Globally installed packages, which are installed through `dart pub global activate package_name`,
          # are located in the `$PUB_CACHE/bin` directory.
          shellHook = ''
            if [ -z "$PUB_CACHE" ]; then
              export PATH="$PATH:$HOME/.pub-cache/bin"
            else
              export PATH="$PATH:$PUB_CACHE/bin"
            fi

            export PATH="$(git rev-parse --show-toplevel)/flutter/bin:$PATH"

            git submodule update --init

            if [ ! -f "$LIBCLANG_PATH/libclang.so" ]; then
              echo "ERROR: libclang.so not found in $LIBCLANG_PATH"
              exit 1
            fi

            if [ ! -f "$CLANG_INCLUDE/stddef.h" ]; then
              echo "ERROR: stddef.h not found in $CLANG_INCLUDE"
              exit 1
            fi

            rm -f ffigen.yaml

            cat > ffigen.yaml <<EOF
name: "NativeLibrary"
description: "Bindings created by ffigen"
output: "lib/ffi/generated_bindings.dart"
headers:
  entry-points:
    - "crypto/gdk/include/gdk/gdk.h"
    - "boltz-rust/bindings.h"
  include-directives:
    - "**/*.h"
typedefs:
  include:
    - ".*"
functions:
  expose-typedefs:
    include:
      - ".*"
structs:
  exclude:
    - "(.*)sigaction(.*)"
unions:
  exclude:
    - "(.*)sigaction(.*)"

llvm-path:
  - "${llvmPackages.libclang.lib}"

compiler-opts:
  - "-I$CLANG_INCLUDE"
  - "-I$GLIBC_INCLUDE"
  - "-I/usr/include"
  - "-I/usr/local/include"
  - "-Icrypto/gdk/include"
  - "-Iboltz-rust"
EOF

echo "ffigen.yaml created ok"
          '';
        };
      }
    );
}
