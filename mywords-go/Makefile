ifeq ($(OS),Windows_NT)
 	PLATFORM="windows"
 	WEB_BIN_NAME="mywords-web-windows.exe"
else ifeq ($(shell uname),Darwin)
  	PLATFORM="macos"
	WEB_BIN_NAME="mywords-web-macos"
else ifeq ($(shell uname),Linux)
	PLATFORM="linux"
	WEB_BIN_NAME="mywords-web-linux"
else
  	PLATFORM="unkonwn"
endif
platform:
	@echo "platform: $(PLATFORM)"

#// different platform must specify the compile platform, or flutter will report error: for example, open android so in linux,
#// report cannot open shared object file: No such file or directory

# TODO
# Important: Please set the CC environment variable to the compiler of your platform.
# e.g.
# CC=~/Android/Sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64/bin/aarch64-linux-android33-clang
# Or
# export PATH="$HOME/Android/Sdk/ndk/25.2.9519653/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH"
CC=aarch64-linux-android35-clang
 	# if not set CC, will report error:
	# runtime/cgo
	#gcc_android.c:6:10: fatal error: android/log.h: No such file or directory
	#    6 | #include <android/log.h>
	#      |          ^~~~~~~~~~~~~~~
	#compilation terminated.
ldflags="-s -w  -X 'main.buildTime=$$(date '+%Y-%m-%d %H:%M:%S')'  -X 'main.gitCommit=$$(git rev-parse --short HEAD)'"

FLUTTER_DIR=../mywords-flutter

build-web:
# this is a must of all build
	@echo "build web for $(PLATFORM) platform"
	cd $(FLUTTER_DIR) && make build-web
	rm -rf cmd/web/
	mv $(FLUTTER_DIR)/build/web ./cmd/
if-build-web:
	[ -d ./cmd/web ] || make build-web
build-so: if-build-web build-so-linux build-so-android
	@echo "build .so for all platform successfully"
build-so-linux:if-build-web
	@echo "build so for linux platform"
	@go build -tags=flutter -buildmode=c-shared -ldflags $(ldflags) -o $(FLUTTER_DIR)/libs/libgo_linux.so ./cmd/
	@echo "build .so for linux platform successfully!"
build-so-windows:if-build-web
	@echo "build so for windows platform"
	@go build -tags=flutter -buildmode=c-shared -ldflags $(ldflags) -o $(FLUTTER_DIR)/libs/libgo_windows.so ./cmd/
	@echo "build .so for windows platform successfully!"
build-so-android:if-build-web
	@echo "build .so for android platform"
	@CC=${CC} GOOS=android CGO_ENABLED=1 GOARCH=arm64 go build  -tags=flutter -buildmode=c-shared -ldflags $(ldflags) -o $(FLUTTER_DIR)/android/app/jniLibs/arm64-v8a/libgo.so ./cmd/
	@echo "build .so for android platform successfully!"
go-build:if-build-web
	@echo "build web for $(PLATFORM) platform"
	- mkdir bin
	CGO_ENABLED=1 go build -ldflags $(ldflags) -o ./bin/$(WEB_BIN_NAME) ./cmd/
build-web-platform: if-build-web
	make go-build
	@echo "build web for $(PLATFORM) platform successfully!"
#    now you can run the binary file to start the web client
	@echo "run the binary file '$(WEB_BIN_NAME)' to start the web server"
	@echo "$$ cd bin && ./$(WEB_BIN_NAME)"
	@echo "Open your browser and visit 'http://localhost:18960/web/', or use the port that you have specified."

build-web-termux:if-build-web
	@echo "build cli for android termux platform"
	@CC=${CC} GOOS=android CGO_ENABLED=1 GOARCH=arm64 go build -ldflags $(ldflags) -o ./bin/mywords-web-termux ./cmd/
	@echo "build cli for android termux platform successfully!"
clean:
	rm -rf bin/
	rm -rf cmd/web/
