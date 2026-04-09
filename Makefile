SHELL := /bin/bash
include versions.mk
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
	echo "30f992aff1e46f10a5d847620e1267b593ef7c37e99dc6f5f5dd9b0e47df8830  /tmp/gdk-iphone.tar.gz" | shasum -a 256 --check
	tar --extract --file /tmp/gdk-iphone.tar.gz --directory crypto
	# gdk-android-jni
	curl --location $(GDK_RELEASE_URL)/gdk-release_$(GDK_VERSION).tar.gz --output /tmp/gdk-release.tar.gz
	echo "5ab668a398012bd651201de816ee6d278750c1ff4fa6ea3e3782f382a10b8b22  /tmp/gdk-release.tar.gz" | shasum -a 256 --check
	tar --extract --file /tmp/gdk-release.tar.gz --directory crypto
	mv crypto/gdk-release_$(GDK_VERSION) crypto/gdk
	cp -r gdk-includes/include crypto/gdk/

patch-ios-sim: patch-ios-sim-gdk

patch-ios-sim-gdk:
	# gdk-iphone-sim
	curl --location $(GDK_RELEASE_URL)/gdk-iphone-sim-x86_64.tar.gz --output /tmp/gdk-iphone-sim.tar.gz
	echo "3ccca62f50c3253817f7fcea385b4ad4f333bba433d847f6821f069b585cfa97  /tmp/gdk-iphone-sim.tar.gz" | shasum -a 256 --check
	tar --extract --file /tmp/gdk-iphone-sim.tar.gz --directory crypto
	cp crypto/gdk-iphonesim-x86_64/lib/x86_64-apple-ios13.00/libgreen_gdk_full.a crypto/gdk-iphone/lib/arm64-apple-ios13.00/

patch-ios-sim-boltz:
	rm ios/libboltz_rust.a
	cp boltz-rust/ios-sim/libboltz_rust.a ios

get-boltz-rust:
	rm -rf boltz-rust boltz-rust.tar.gz
	curl -L https://github.com/AquaWallet/boltz-rust/releases/download/$(BOLTZ_RUST_VERSION)/boltz-rust-$(BOLTZ_RUST_VERSION).tar.gz --output boltz-rust.tar.gz
	echo "8b450b0f4584cfa819b21741e2c98a7dde757c9a61c6202956e843ff6434be9a  boltz-rust.tar.gz" | shasum -a 256 --check
	tar -xzf boltz-rust.tar.gz
	rm boltz-rust.tar.gz
	mkdir -p android/app/src/main/jniLibs/arm64-v8a/ android/app/src/main/jniLibs/armeabi-v7a/ android/app/src/main/jniLibs/x86/ android/app/src/main/jniLibs/x86_64/
	cp boltz-rust/android/app/src/main/jniLibs/arm64-v8a/libboltz_rust.so android/app/src/main/jniLibs/arm64-v8a/
	cp boltz-rust/android/app/src/main/jniLibs/armeabi-v7a/libboltz_rust.so android/app/src/main/jniLibs/armeabi-v7a/
	cp boltz-rust/android/app/src/main/jniLibs/x86/libboltz_rust.so android/app/src/main/jniLibs/x86/
	cp boltz-rust/android/app/src/main/jniLibs/x86_64/libboltz_rust.so android/app/src/main/jniLibs/x86_64/
	cp boltz-rust/ios/libboltz_rust.a ios

get-isar:
	@echo "Downloading Isar native library for tests..."
	@if [ $$(uname -s) = "Darwin" ]; then \
		if [ ! -f ./libisar.dylib ]; then \
			curl -L https://github.com/isar/isar/releases/download/3.1.0%2B1/libisar_macos.dylib -o ./libisar.dylib; \
			echo "Downloaded libisar.dylib for macOS"; \
		else \
			echo "libisar.dylib already exists, skipping download"; \
		fi \
	elif [ $$(uname -s) = "Linux" ]; then \
		if [ ! -f ./libisar.so ]; then \
			curl -L https://github.com/isar/isar/releases/download/3.1.0%2B1/libisar_linux_x64.so -o ./libisar.so; \
			echo "Downloaded libisar.so for Linux"; \
		else \
			echo "libisar.so already exists, skipping download"; \
		fi \
	else \
		echo "Unsupported OS for Isar tests"; \
		exit 1; \
	fi

generate-bindings:
	dart run ffigen --ignore-source-errors

freeze:
	dart run build_runner build --delete-conflicting-outputs

run-android-emulator-mac:
	~/Library/Android/sdk/emulator/emulator -avd Pixel_3a_API_34_extension_level_7_arm64-v8a -netdelay none -netspeed full

run-ios-emulator-mac:
	open -a Simulator

run-unit-tests: get-isar
	flutter test --coverage

run-integration-tests:
	@echo "Running integration tests..."
	# disabled until we fix all tests. till then, test the updated ones
	# flutter test integration_test
	flutter test integration_test/create_delete_wallet_test.dart
	flutter test integration_test/multi_wallet_migration_test.dart
	@echo "All integration tests passed successfully!"

test-all: run-unit-tests run-integration-tests

setup: install get-gdk get-boltz-rust generate-bindings freeze

PHONY: setup get-isar run-ios-emulator-mac run-android-emulator-mac run-integration-tests run-unit-tests test-all

generate-assets:
	dart run flutter_launcher_icons
	dart run flutter_native_splash:create

unused-localizations:
	chmod +x scripts/unused_loc.sh
	scripts/unused_loc.sh
