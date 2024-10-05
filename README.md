## [English Version](README.md) | [中文版](README-zh-hans.md)


## Project Overview
This project provides a tool for learning English vocabulary, designed specifically for English learners, by expanding their vocabulary through reading English or bilingual articles. Users can automatically extract words from the learning articles, analyze word frequency, filter words, and track and record their mastery level.

- Vocabulary Learning Tool! Enter the URL of an English or bilingual article, and this tool will automatically extract all words and their corresponding sentences from the article, deduplicate and summarize the words in the article. You can filter to display only the words you don't know.
- This tool supports custom dictionary libraries, allowing users to add their own dictionary libraries for referencing word meanings during the learning process.


## Changelog
- 20240324: Important: v2.0.0 adds the web version, supporting local deployment or cloud deployment.

### v3.0.0
- The underlying code has been refactored totally to make it clearer. Using `sqlite` to store data, making the project more stable and easier to maintain.
- Mobile/desktop client version directly integrates Web, seamless learning between multiple devices. It called `Web Online` in the client version.
- Totally new design and user experience; Using English as the default language.
- Support for dark mode and light mode.
- Web support uploading super large (>2GB) dictionary files. Client version also supports uploading large files.
- Support for edit the name of the dictionary.
- Sharing  and Syncing data between devices is easier and faster.
- **Important**: Starting from version v3.0.0, we plan to no longer provide separately compiled Linux, Windows, and MacOS client versions. Please use the desktop Web version or the mobile integrated Web version for learning. This makes installation and usage simpler and more convenient.

## Key Features
- **Word Extraction and Recording**: Enter a URL, and the tool automatically retrieves and extracts all words and their contextual sentences from the web article. Additionally, it calculates and displays the vocabulary size of the article.
- **Intelligent Management and Filtering**: Avoid redundant learning of words you already know by utilizing deduplication and excluding options for mastered vocabulary, allowing you to focus on learning new words.
- **Learning Progress Tracking**: Words can be marked with different cognitive levels, including "0: Unknown," "1: Recognized", "2: Familiar", "3: Proficient". This helps customize the learning path while enhancing memory retention.
- **Filtered Browsing Functionality**: Filter out words of specific cognitive levels, for example, selecting the "0" tag displays all the words you are yet to understand.
- **Synchronization and Platform Compatibility**: Developed using Go and Flutter for cross-platform applications, supports usage on Android, Linux, and Windows, with data synchronization between devices, enabling convenient learning without constraints.
- **Web Version Support**: Supports local or cloud deployment, enabling access to the web application via a browser, offering a consistent user experience with desktop and mobile applications.
- **Local Data Storage**: No reliance on backend servers, ensuring all data is securely stored locally.

## Development and Technical Support
- This tool is developed with a focus on cross-platform compatibility and user convenience. It not only utilizes the high-performance Go language for core logic but also employs Flutter to ensure a smooth user interface experience and consistency across platforms. Whether users are learning on any device, they can ensure seamless synchronization of their learning progress.

- With a focus on English learning needs, our goal is to create a simple, efficient, and user-friendly vocabulary learning aid. We welcome you to use this tool to accelerate your language learning journey.

## Reading and Vocabulary Expansion
Reading English articles is widely recognized as an effective way to expand vocabulary. According to data analysis, about 50% to 70% of the vocabulary in each English article is considered effective. Please note that punctuation marks, articles, prepositions, and other simple vocabulary (such as "a," "in," "on," "the," "I," "than," "you," "he," etc.) have been automatically excluded from the articles. We suggest you:

- **Consistently Read Daily**: Develop a habit of reading English articles daily, whether it's news, academic papers, or novels.
- **Record New Vocabulary**: When encountering new words, use this tool to record them and classify their cognitive levels.


## Measuring Progress
Continuous reading practice will directly reflect in the growth of your vocabulary. Over time, you will notice:

- **Reduction in "0-level Unknown Words**": The number of completely unfamiliar words encountered when reading each new article will gradually decrease.
- **Improved Reading Speed**: You will read articles faster and with a significant increase in comprehension depth and speed.
Consistently practicing reading and using tools to assist you in recording and reviewing these new words is key to improving your English proficiency. As your vocabulary grows, you will not only read more fluently but also enhance your writing and conversational skills.


## Recommended Learning Resources
To effectively use this tool and enhance your English proficiency, this project recommends the following English reading resources. They provide rich bilingual content covering a wide range of topics suitable for learners of all levels:
- **The New York Times (Chinese-English Edition)**：Visit[ The New York Times Chinese-English Edition ](https://cn.nytimes.com/zh-hant/)for high-quality bilingual reading materials. This will help improve your English comprehension and vocabulary.
  ![Bilingual English Learning Resource Icon](https://raw.githubusercontent.com/vito-go/assets/master/mywords/images/dual.png)


- **The Economist China**: [The Economist China](https://www.economist.com/topics/china): English content tailored for Chinese readers, 
covering politics, economics, technology, and more. It's very beneficial for learners who want to gain in-depth understanding of global topics.
  ![img.png](https://raw.githubusercontent.com/vito-go/assets/master/mywords/images/the-economist-china.png)

By utilizing these resources, you can not only expand your vocabulary in a targeted manner but also gain insights into 
different topics and background knowledge, comprehensively enhancing your English proficiency.

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

### 1. Compilation Guide for Android, Linux, Windows Versions

- **Installation Guide**：
    - For `Android` users: Execute `make build-android`in the terminal.
    - For `Linux` users: Execute `make build-linux` in the terminal. 
    - For `Windows` users: Execute `make build-windows` in the terminal.

- **Package Location**：
  After compilation, the corresponding installation package files will be located in the "bin" folder of the project. Follow the standard installation process on your device to start using.



### 2. Web Version Usage Guide (Supports Linux, Windows, MacOS)


- **Web Version**：

> The web desktop version is a standalone web application that can be run in a browser without installation. Simply execute the binary file in the command line to open the web application in your browser.
>
> It supports usage on platforms such as Linux, Windows, and macOS. You can deploy the web version to your local computer device or deploy it on a cloud server for use on any device.

- Execute `make build-web-platform` in the terminal.
- Execute the compiled binary file in the command line, for example:
    - Execute `./bin/mywords-web-linux` on Linux.
    - Execute `./bin/mywords-web-windows.exe` on Windows.
    - Execute `./bin/mywords-web-macos` on MacOS.
- After execution, the browser will automatically open and access http://127.0.0.1:18960 or the specified port number.
- Already integrated the web version in the mobile version, seamless learning between multiple devices.

## Project Structure

```
├── bin                   # Directory for compiled project files, .apk for Android, .deb for Linux, .zip for Windows, binary files for Web version (e.g., mywords-web-linux, mywords-web-windows.exe, mywords-web-macos)
├── mywords-go            # Directory for Go core logic source code used to compile .so library
├── mywords-flutter       # Directory for Flutter source code used to compile installation packages
├── Makefile              # Makefile for the project
├── README.md             # Project documentation
```

## Screenshots
<img src="https://raw.githubusercontent.com/vito-go/assets/master/mywords/images/mywords.jpg">

## Adding Dictionary Guide
[Adding Dictionary Guide](ADD_DICTIONARY_GUIDE.md)


## TODO
- [x] Dark theme color
- [x] Web version support, supporting local deployment and cloud deployment. Support for running in Termux on Android devices.
- [x] On mobile versions, integrate the web version for seamless learning between multiple devices. 
- [x] README.md of English version
- [ ] Net Proxy support configuration of username and password 
- [ ] Web version supports configuring usernames and passwords
---

## Acknowledgements

We sincerely thank the following individuals and organizations for their support and contributions to this project:

- Thanks to  [The New York Times Chinese and English Edition ](https://cn.nytimes.com/zh-hant/) for providing us with high-quality bilingual reading materials, which are very helpful for English learners.
- Thanks to  [The Economist China ](https://www.economist.com/topics/china) for providing us with high-quality English reading materials, enriching our learning with abundant content.
- Special thanks to [Bitbucket.org/xwang](https://bitbucket.org/xwang/mdict-analysis/src/master/)for providing the Python dictionary parsing tool, which is crucial for us to build the vocabulary database.
- Special thanks to [louischeung.top](http://louischeung.top:225/mdict%E8%AF%8D%E5%85%B8%E5%8C%85/)  for providing the Oxford Advanced English-Chinese bilingual dictionary, which is highly valuable for English learners.
- We express our deep gratitude to all users who have actively provided feedback and suggestions through WeChat or Email.
- Thanks to all contributors, testers, and users who have supported and used our tool. It is your support that drives the continuous improvement of this project.


Additionally, we would like to thank all friends who have quietly supported this project behind the scenes. Your encouragement and feedback are the sources of the project's continuous development.

