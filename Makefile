install:
	fvm flutter pub get

get-gdk:
	rm -rf crypto
	curl -L https://github.com/sideswap-io/gdk/releases/download/aqua_0.0.55/gdk0.0.55.tar.gz --output crypto.tar.gz
	echo "d78f2f7a57f9ecb1bd2190e75051ff64b58a771df015514d67566a5bc5abf1ed  crypto.tar.gz" | shasum -a 256 --check
	tar -xzf crypto.tar.gz
	rm crypto.tar.gz


get-boltz-rust:
	rm -rf boltz-rust boltz-rust.tar.gz
	curl -L https://github.com/AquaWallet/boltz-rust/releases/download/0.1.6/boltz-rust-0.1.6.tar.gz --output boltz-rust.tar.gz
	echo "45b5ac8e9ba177f5f48881b94b7276cc2513fdc21f8f89b197e9bffc9ab86521  boltz-rust.tar.gz" | shasum -a 256 --check
	tar -xzf boltz-rust.tar.gz
	rm boltz-rust.tar.gz
	mkdir -p android/app/src/main/jniLibs/arm64-v8a/ android/app/src/main/jniLibs/armeabi-v7a/ android/app/src/main/jniLibs/x86/ android/app/src/main/jniLibs/x86_64/
	cp boltz-rust/android/app/src/main/jniLibs/arm64-v8a/libboltz_rust.so android/app/src/main/jniLibs/arm64-v8a/
	cp boltz-rust/android/app/src/main/jniLibs/armeabi-v7a/libboltz_rust.so android/app/src/main/jniLibs/armeabi-v7a/
	cp boltz-rust/android/app/src/main/jniLibs/x86/libboltz_rust.so android/app/src/main/jniLibs/x86/
	cp boltz-rust/android/app/src/main/jniLibs/x86_64/libboltz_rust.so android/app/src/main/jniLibs/x86_64/
	cp boltz-rust/ios/libboltz_rust.a ios

generate-bindings:
	fvm flutter pub run ffigen

freeze:
	fvm flutter pub run build_runner build

setup-git-hooks:
	cp pre-commit .git/hooks/pre-commit

run-emulator:
	~/Library/Android/sdk/emulator/emulator -avd Pixel_3a_API_34_extension_level_7_arm64-v8a -netdelay none -netspeed full

setup: install get-gdk get-boltz-rust generate-bindings freeze setup-git-hooks

PHONY: setup run-emulator
