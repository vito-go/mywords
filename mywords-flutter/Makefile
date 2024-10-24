mkdir-apk-libs:
	mkdir -p android/app/jniLibs/arm64-v8a
	mkdir -p android/app/jniLibs/armeabi-v7a
	mkdir -p android/app/jniLibs/x86_64
clean:
	rm -rf bin
	flutter clean
	rm -rf linux-deb/opt/mywords/*
	rm -rf android/app/jniLibs/*

build-la:build-apk build-linux
FLUTTER_VERSION=$(shell flutter --version)
GO_DIR=../mywords-go

build-apk:if-build-so-android
	- mkdir bin
	flutter build apk  --dart-define=FLUTTER_VERSION="$(FLUTTER_VERSION)" --target-platform android-arm64
	mv build/app/outputs/flutter-apk/app-release.apk ./bin/mywords-arm64-v8a-release.apk
build-aab:
	- mkdir bin
	flutter build appbundle  --dart-define=FLUTTER_VERSION="$(FLUTTER_VERSION)" --target-platform android-arm64
	mv build/app/outputs/bundle/release/app-release.aab ./bin/mywords.aab

if-build-so-android:
	[ -f "android/app/jniLibs/arm64-v8a/libgo.so" ] || make build-so-android
if-build-so-linux:
	[ -f "libs/libgo_linux.so" ] || make build-so-linux
if-build-so-windows:
	[ -f "libs/libgo_windows.so" ] || make build-so-windows
build-so-android:
	cd $(GO_DIR) && make build-so-android
build-so-linux:
	cd $(GO_DIR) && make build-so-linux
build-so-windows:
	cd $(GO_DIR) && make build-so-windows

build-linux:if-build-so-linux
	flutter build linux -v  --dart-define=FLUTTER_VERSION="$(FLUTTER_VERSION)"
	- mkdir -p linux-deb/opt/mywords/libs
	cp -r build/linux/x64/release/bundle/* linux-deb/opt/mywords/
	cp  libs/*.so linux-deb/opt/mywords/libs/
	cp  logo.png linux-deb/opt/mywords/
	- mkdir bin
	dpkg -b linux-deb/ bin/mywords.deb
build-windows:if-build-so-windows
	flutter build windows -v  --dart-define=FLUTTER_VERSION="$(FLUTTER_VERSION)"
	- mkdir  build/windows/x64/runner/Release/libs/
	cp  libs/*.so  build/windows/x64/runner/Release/libs/
	- mkdir bin
	rm -rf bin/mywords-windows
	cp -r build/windows/x64/runner/Release bin/mywords-windows
build-web:
	 # flutter clean
	rm -rf build/web
	flutter build web  --dart-define=FLUTTER_VERSION="$(FLUTTER_VERSION)"