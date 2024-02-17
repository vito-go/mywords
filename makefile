ifeq ($(OS),Windows_NT)
 PLATFORM="Windows"
else
 ifeq ($(shell uname),Darwin)
  PLATFORM="MacOS"
 else
  PLATFORM="Unix-Like"
 endif
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

clean:
	rm -rf bin/
	cd $(FLUTTER_DIR) && make clean
	@echo "clean done"

build-linux:
	cd $(GO_DIR) && make build-so-linux
	cd $(FLUTTER_DIR) && make build-linux
	cp -r $(FLUTTER_DIR)/bin/ ./
	@echo "PLATFORM: $(PLATFORM) all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
	@ls -lha bin
build-windows:
	cd $(GO_DIR) && make build-so-windows
	cd $(FLUTTER_DIR) && make build-windows
	cp -r $(FLUTTER_DIR)/bin/ ./
	@echo "PLATFORM: $(PLATFORM) all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
	@ls -lha bin

build-android:
	cd $(GO_DIR) && make build-so-android
	cd $(FLUTTER_DIR) && make build-apk
	cp -r $(FLUTTER_DIR)/bin/ ./
	@echo "PLATFORM: $(PLATFORM) all done, look at the directory bin/"
	@echo "--------$$ ls -lha bin --------"
	@ls -lha bin
build-la: build-android build-linux