
## Getting Started Guide

Please choose the correct compilation command according to your platform for compiling operations. You can select the `Android`, `Linux`, `Windows`, or `Web` version for installation.

- **Prerequisites**：
    - Ensure that you have installed the `go` language environment and `flutter` development environment on your device.
    - Make sure that tools such as `make` and `zip` are installed on your device.
    - For `Windows` environment, support for `CGO` is required
        - If the corresponding CGO runtime environment is not installed, you will encounter the following error when running:
          > exec: “gcc”: executable file not found in %PATH%
            - Windows Go Language CGO Runtime Environment Configuration
              - https://www.expoli.tech/articles/2022/10/18/1666087321618
            - Make for Windows
              - https://gnuwin32.sourceforge.net/packages/make.htm
                - Complete package, except sources
- **Build-Web**: execute `make build-web` to compile the integrated and Web version static resource files.

### 1. Compilation Guide for Android, Linux, Windows Versions

- **Installation Guide**：
    - For `Android` users: Execute `make build-android`in the terminal.
    - For `Linux` users: Execute `make build-linux` in the terminal.
    - For `Windows` users: Execute `make build-windows` in the terminal.

- **Package Location**：
  After compilation, the corresponding installation package files will be located in the `bin` folder of the project. Follow the standard installation process on your device to start using.



### 2. Web Version Usage Guide (Supports Linux, Windows, MacOS)


- **Web Version**：

> The web desktop version is a standalone web application that can be run in a browser without installation. Simply execute the binary file in the command line to open the web application in your browser.
>
> It supports usage on platforms such as Linux, Windows, and macOS. You can deploy the web version to your local computer device or deploy it on a cloud server for use on any device.
> 

- Execute `make build-web-platform` in the terminal.
  - Execute the compiled binary file in the command line, for example:
      - Execute `./bin/mywords-web-linux` on Linux.
      - Execute `./bin/mywords-web-windows.exe` on Windows.
      - Execute `./bin/mywords-web-macos` on MacOS.
- Execute `make build-web-termux` in the terminal to compile the web version for Termux on Android.
  - Execute `./bin/mywords-web-termux` in the terminal to run the web version on Termux on Android.
- After execution, the browser will automatically open and access http://127.0.0.1:18960/web/ or the specified port number.
- Already integrated the web version in the mobile version, seamless learning between multiple devices.

## Project Structure

```
├── bin                   # Directory for compiled project files, .apk for Android, .deb for Linux, .zip for Windows, binary files for Web version (e.g., mywords-web-linux, mywords-web-windows.exe, mywords-web-macos)
├── mywords-go            # Directory for Go core logic source code used to compile .so library
├── mywords-flutter       # Directory for Flutter source code used to compile installation packages
├── Makefile              # Makefile for the project
├── README.md             # Project documentation
├── CHANGE_LOG.md         # Project change log
├── BUILD_GUIDE.md        # Project compilation guide
├── ADD_DICTIONARY_GUIDE.md # Guide for adding dictionaries
├── LICENSE               # Project license
```
