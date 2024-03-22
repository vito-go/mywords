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

build-apk:
	- mkdir bin
	flutter build apk  --target-platform android-arm64
	mv build/app/outputs/flutter-apk/app-release.apk ./bin/mywords-arm64-v8a-release.apk
build-linux:
	flutter build linux -v
	- mkdir -p linux-deb/opt/mywords/libs
	cp -r build/linux/x64/release/bundle/* linux-deb/opt/mywords/
	cp  libs/*.so linux-deb/opt/mywords/libs/
	cp  logo.png linux-deb/opt/mywords/
	- mkdir bin
	dpkg -b linux-deb/ bin/mywords.deb
build-windows:
	flutter build windows -v
	- mkdir  build/windows/x64/runner/Release/libs/
	cp  libs/*.so  build/windows/x64/runner/Release/libs/
	- mkdir bin
	rm -rf bin/mywords-windows
	cp -r build/windows/x64/runner/Release bin/mywords-windows