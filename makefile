ifeq ($(OS),Windows_NT)
 	PLATFORM="windows"
else ifeq ($(shell uname),Darwin)
  	PLATFORM="macos"
else ifeq ($(shell uname),Linux)
	PLATFORM="linux"
else
  	PLATFORM="unkonwn"
endif
build:
ifeq ($(OS),Windows_NT)
	make build-windows
else
 ifeq ($(shell uname),Darwin)
	echo "not supported: Darwin"
	exit 1
 else
	make build-linux
 endif
endif

FLUTTER_DIR='mywords-flutter'
GO_DIR='mywords-go'

bin:
	@mkdir -p bin
clean:
	rm -rf bin/
	cd $(FLUTTER_DIR) && make clean
	@echo "clean done"

build-linux:bin
	cd $(GO_DIR) && make build-so-linux
	cd $(FLUTTER_DIR) && make build-linux
	mv $(FLUTTER_DIR)/bin/* ./bin/
	@echo "PLATFORM: $(PLATFORM) all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
	@ls -lha bin
build-windows:bin
	cd $(GO_DIR) && make build-so-windows
	cd $(FLUTTER_DIR) && make build-windows
	mv $(FLUTTER_DIR)/bin/* ./bin/
	@echo "PLATFORM: $(PLATFORM) all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
	@ls -lha bin

build-android:bin
	cd $(GO_DIR) && make build-so-android
	cd $(FLUTTER_DIR) && make build-apk
	mv $(FLUTTER_DIR)/bin/* ./bin/
	@echo "PLATFORM: $(PLATFORM) all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
	@ls -lha bin
build-la: build-android build-linux

build-web-platform:bin
	cd $(GO_DIR) && make build-web-platform
	mv $(GO_DIR)/bin/* ./bin/
	@echo "PLATFORM: $(PLATFORM) all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
