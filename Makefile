install:
	fvm flutter pub get

get-gdk:
	curl -L https://github.com/sideswap-io/gdk/releases/download/aqua_0.0.55/gdk0.0.55.tar.gz --output crypto.tar.gz
	echo "d78f2f7a57f9ecb1bd2190e75051ff64b58a771df015514d67566a5bc5abf1ed  crypto.tar.gz" | shasum -a 256 --check
	tar -xzf crypto.tar.gz
	rm crypto.tar.gz

get-rust-elements-wrapper:
	curl -L https://github.com/AquaWalletIO/rust-elements-wrapper/releases/download/0.0.2/rust-elements-wrapper-0.0.2.tar.gz --output rust-elements-wrapper.tar.gz
	echo "e180bcef9f2fd13708e7bc92e20ed3dd4ff2a244ae0363bbe4d3eae9562d4291  rust-elements-wrapper.tar.gz" | shasum -a 256 --check
	tar -xzf rust-elements-wrapper.tar.gz
	rm rust-elements-wrapper.tar.gz
	mkdir -p android/app/src/main/jniLibs/arm64-v8a/ android/app/src/main/jniLibs/armeabi-v7a/ android/app/src/main/jniLibs/x86/ android/app/src/main/jniLibs/x86_64/
	cp rust-elements-wrapper/android/app/src/main/jniLibs/arm64-v8a/librust_elements_wrapper.so android/app/src/main/jniLibs/arm64-v8a/
	cp rust-elements-wrapper/android/app/src/main/jniLibs/armeabi-v7a/librust_elements_wrapper.so android/app/src/main/jniLibs/armeabi-v7a/
	cp rust-elements-wrapper/android/app/src/main/jniLibs/x86/librust_elements_wrapper.so android/app/src/main/jniLibs/x86/
	cp rust-elements-wrapper/android/app/src/main/jniLibs/x86_64/librust_elements_wrapper.so android/app/src/main/jniLibs/x86_64/
	cp rust-elements-wrapper/ios/librust_elements_wrapper.a ios

generate-bindings:
	fvm flutter pub run ffigen

freeze:
	fvm flutter pub run build_runner build

setup-git-hooks:
	cp pre-commit .git/hooks/pre-commit

run-emulator:
	~/Library/Android/sdk/emulator/emulator -avd Pixel_3a_API_34_extension_level_7_arm64-v8a -netdelay none -netspeed full

setup: install get-gdk get-rust-elements-wrapper generate-bindings freeze setup-git-hooks

PHONY: setup run-emulator
