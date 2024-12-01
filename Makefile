SHELL := /bin/bash
GDK_VERSION := 0.73.0
GDK_RELEASE_URL := https://github.com/Blockstream/gdk/releases/download/release_$(GDK_VERSION)

install:
	flutter pub get

shell:
	nix develop --experimental-features 'nix-command flakes'

get-gdk:
	rm -rf crypto
	mkdir crypto
	# gdk-iphone
	curl --location $(GDK_RELEASE_URL)/gdk-iphone.tar.gz --output /tmp/gdk-iphone.tar.gz
	echo "53dc64ddbf71057fd493f1334eff9fa9d4b1fb712e520eb2bdba7191a47617c0  /tmp/gdk-iphone.tar.gz" | shasum -a 256 --check
	tar --extract --file /tmp/gdk-iphone.tar.gz --directory crypto
	# gdk-android-jni
	curl --location $(GDK_RELEASE_URL)/gdk-release_$(GDK_VERSION).tar.gz --output /tmp/gdk-release.tar.gz
	echo "2bb9d517b0a5f31a65154ab449db469fa3e19852c1f39d17c8622776bf40249d  /tmp/gdk-release.tar.gz" | shasum -a 256 --check
	tar --extract --file /tmp/gdk-release.tar.gz --directory crypto
	mv crypto/gdk-release_$(GDK_VERSION) crypto/gdk
	cp -r gdk-includes/include crypto/gdk/

patch-ios-sim:
	# gdk-iphone-sim-x86_64
	curl --location $(GDK_RELEASE_URL)/gdk-iphone-sim-x86_64.tar.gz --output /tmp/gdk-iphone-sim-x86_64.tar.gz
	echo "c8fcee250be4f17563433bcc0a9ce3e198b3898fd1d082e67bac7ff9c308640a  /tmp/gdk-iphone-sim-x86_64.tar.gz" | shasum -a 256 --check
	tar --extract --file /tmp/gdk-iphone-sim-x86_64.tar.gz --directory crypto
	rm crypto/gdk-iphone/lib/arm64-apple-ios13.00/libgreen_gdk_full.a
	cp crypto/gdk-iphonesim-x86_64/lib/x86_64-apple-ios13.00/libgreen_gdk_full.a crypto/gdk-iphone/lib/arm64-apple-ios13.00/

get-boltz-rust:
	rm -rf boltz-rust boltz-rust.tar.gz
	curl -L https://github.com/AquaWallet/boltz-rust/releases/download/0.1.7/boltz-rust-0.1.7.tar.gz --output boltz-rust.tar.gz
	echo "8b450b0f4584cfa819b21741e2c98a7dde757c9a61c6202956e843ff6434be9a  boltz-rust.tar.gz" | shasum -a 256 --check
	tar -xzf boltz-rust.tar.gz
	rm boltz-rust.tar.gz
	mkdir -p android/app/src/main/jniLibs/arm64-v8a/ android/app/src/main/jniLibs/armeabi-v7a/ android/app/src/main/jniLibs/x86/ android/app/src/main/jniLibs/x86_64/
	cp boltz-rust/android/app/src/main/jniLibs/arm64-v8a/libboltz_rust.so android/app/src/main/jniLibs/arm64-v8a/
	cp boltz-rust/android/app/src/main/jniLibs/armeabi-v7a/libboltz_rust.so android/app/src/main/jniLibs/armeabi-v7a/
	cp boltz-rust/android/app/src/main/jniLibs/x86/libboltz_rust.so android/app/src/main/jniLibs/x86/
	cp boltz-rust/android/app/src/main/jniLibs/x86_64/libboltz_rust.so android/app/src/main/jniLibs/x86_64/
	cp boltz-rust/ios/libboltz_rust.a ios

generate-bindings:
	dart run ffigen --ignore-source-errors

freeze:
	dart run build_runner build --delete-conflicting-outputs

run-android-emulator-mac:
	~/Library/Android/sdk/emulator/emulator -avd Pixel_3a_API_34_extension_level_7_arm64-v8a -netdelay none -netspeed full

run-ios-emulator-mac:
	open -a Simulator

run-unit-tests:
	flutter test

run-integration-tests:
	flutter test integration_test

test-all: run-unit-tests run-integration-tests

setup: install get-gdk get-boltz-rust generate-bindings freeze

PHONY: setup run-ios-emulator-mac run-android-emulator-mac run-integration-tests run-unit-tests test-all

generate-assets: 
	dart run flutter_launcher_icons
	dart run flutter_native_splash:create
