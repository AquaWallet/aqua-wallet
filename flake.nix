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
        androidEnv = pkgs.androidenv.override { licenseAccepted = true; };
        androidComposition = androidEnv.composeAndroidPackages {
          cmdLineToolsVersion = "8.0"; # emulator related: newer versions are not only compatible with avdmanager
          platformToolsVersion = "34.0.4";
          buildToolsVersions = [ "30.0.3" "33.0.2" "34.0.0" ];
          platformVersions = [ "30" "31" "32" "33" "34" ];
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

            androidSdk
            qemu_kvm
            gradle
            jdk17

            rustup
          ];
          # emulator related: vulkan-loader and libGL shared libs are necessary for hardware decoding
          LD_LIBRARY_PATH = "${pkgs.lib.makeLibraryPath [vulkan-loader libGL]}";

          LIBCLANG_PATH = "${llvmPackages.libclang.lib}/lib";


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
          '';
        };
      }
    );
}