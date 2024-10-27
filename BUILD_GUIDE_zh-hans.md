## 开始使用指南

请根据你的使用平台选择正确的编译指令进行编译操作，可以选择 `Android`、`Linux`、`Windows` 或 `Web` 版本进行安装。

- **编译前提**：
    - 请确保你的设备上已经安装了`go`语言环境和`flutter`开发环境。
    - 请确保你的设备上已经安装了`make`、`zip`等工具。
    - Windows 环境下，需要对CGO进行支持
        - 如果没有安装对应的 `CGO` 运行时环境、则在运行的时候会引发如下错误。
          > exec: “gcc”: executable file not found in %PATH%
            - Windows GO 语言 CGO 运行时环境配置
                - https://www.expoli.tech/articles/2022/10/18/1666087321618
            - Make for Windows
                - https://gnuwin32.sourceforge.net/packages/make.htm
                - Complete package, except sources
- **编译Web静态资源文件**: 执行 `make build-web` 编译集成以及Web版本的静态资源文件。

### 1. 安卓、Linux、Windows版本编译指南

- **安装指南**：
    - 对于**安卓用户**：在终端执行 `make build-android`。
    - 对于**Linux用户**：在终端执行 `make build-linux`。
    - 对于**Windows用户**：在终端执行 `make build-windows`。


- **安装包位置**：
  编译完成后，相应的安装包文件将会位于项目的"bin"文件夹内。按照标准流程安装到你的设备上后即可开始使用。


### 2. web版本使用指南 (支持Linux、Windows、MacOS)

- **web版本**：

> web桌面版本是一个独立的web应用，可以在浏览器中运行，无需安装，只需在命令行中执行二进制文件，即可在浏览器中打开web应用。
>
> 支持在Linux、Windows、MacOS等平台上使用。你可以将web版本部署到你的本地计算机设备中使用，或者部署在云服务器上以便在任何设备上使用。

- 在终端执行 `make build-web-platform`。
- 在命令行中执行编译后的二进制文件，例如
    - 在Linux下执行`./bin/mywords-web-linux`
    - 在Windows下执行`./bin/mywords-web-windows.exe`
    - 在MacOS下执行`./bin/mywords-web-macos`
- Execute `make build-web-termux` in the terminal to compile the web version for Termux on Android.
    - Execute `./bin/mywords-web-termux` in the terminal to run the web version on Termux on Android.
- 执行 `make build-web-termux` 在终端编译安卓上的Termux的web版本。
    - 执行 `./bin/mywords-web-termux` 在终端运行安卓上的Termux的web版本。
- 执行后会在自动打开浏览器，访问`http://127.0.0.1:18960/web/`或者你指定的其他端口号。

- 已在移动版本中集成web版本，多设备间无缝学习。

## 项目结构

```
├── bin                   # 编译后的项目文件目录，安卓为.apk，Linux为.deb，Windows为.zip，Web版本为二进制文件，例如mywords-web-linux, mywords-web-windows.exe, mywords-web-macos
├── mywords-go            # 用于编译.so库的go核心逻辑源代码目录
├── mywords-flutter       # Flutter源代码目录，用于编译安装包
├── Makefile              # 项目的Makefile文件
├── README.md             # 项目的说明文档
```