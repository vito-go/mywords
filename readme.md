# mywords
1. 输入一个英语或双语文章的网址，本工具将自动提取文章中所有单词及其所在句子，并计算词汇总数。它还能去除重复的单词，并允许你排除那些你已经认识的单词。
2. 为单词打上标签，分为“0:陌生”，“1:了解”，“2:认识”，“3:熟悉”，以帮助跟踪学习进度。一旦标记完成，单词将自动被加入你的词库中。
3. 对已解析的文章单词进行筛选，根据标记等级进行。例如，选择“0”将显示所有“陌生”的单词。
4. 本工具支持安卓(Android)、Linux和Windows平台上的使用。
5. 推荐使用以下英语学习资源：[The New York Times 中英文版](https://cn.nytimes.com/zh-hant/)，以获取优质的英文阅读材料。
## Getting Started
```shell
make build-android
make build-linux
make build-windows
```
the binary file will be generated in the `bin` directory. linux, windows and android are supported.


## Project Tree
```
├── bin
├── mywords-go
├── mywords-flutter
├── makefile
└── readme.md
```
- bin: the compiled result of the project. .apk for android,.deb for linux, and -windows.zip for windows.
- mywords-flutter: the `flutter` source code of the file share server.
- mywords-go: the `go` source code of the file share server.
- makefile: the makefile of the project.
- readme.md: the readme file of the project.

## Dependencies
- windows环境下，需要对CGO进行支持
- 如果没有安装对应的 CGO 运行时环境、则在运行的时候会引发如下错误。
  > exec: “gcc”: executable file not found in %PATH%
  - Windows GO 语言 CGO 运行时环境配置
      - https://www.expoli.tech/articles/2022/10/18/1666087321618
        
  - Make for Windows
      - https://gnuwin32.sourceforge.net/packages/make.htm
      - Complete package, except sources
## Preview

<img src="images/home-article-page.png" style="width: 49%"> <img src="images/home-dict-page.png" style="width: 49%">
<img src="images/home-dict-page-apple.png" style="width: 49%"> <img src="images/word-page.png" style="width: 49%">
<img src="images/article-page.png" style="width: 49%"> <img src="images/article-page-no-sentences.png" style="width: 49%">
<img src="images/drawer.png" style="width: 49%"> <img src="images/chart.png" style="width: 49%">
<img src="images/share.png" style="width: 49%"> <img src="images/sync-data.png" style="width: 49%">
<img src="images/my-known-words.png" style="width: 49%">


## 添加词典
- 由于词典数据库文件过大，无法上传至此，下面是详细的制作步骤。
- 同时，对学习英语感兴趣的朋友，如果不清楚的地方也可以添加我的WeChat(vitogo-chat)进行沟通。

- 词典库源文件应当是一个zip压缩文件，压缩文件包含:
<img src="images/zip-dict.png">
```
├── data
├── html
├── *.css
├── *.js
└── word_html_map.json
// data: 文件夹，用于存放字典资源文件，包含图片、声音等
// html: 文件夹，用于存放单词释义页面的html文件
// *.js,*.css: 文件，html文件夹下的html文件需要引用的资源，文件名应当包含.html后缀
// word_html_map.json: 文件，用于存放单词和html文件名的映射关系，是一个map,key是单词，value是html文件名(不包含.html后缀)，例如：
  {
  "applauses": "179677",
  "applausive": "179678",
  "applausively": "179679",
  "apple": "769680"
  ...
  }
```
 以上zip文件的制作, 可以下载 mdx/mdd格式词典文件，如[mdict词典包/牛津高阶英汉双解词典（第10版）V3](http://louischeung.top:225/mdict%E8%AF%8D%E5%85%B8%E5%8C%85/%E7%89%9B%E6%B4%A5%E9%AB%98%E9%98%B6%E8%8B%B1%E6%B1%89%E5%8F%8C%E8%A7%A3%E8%AF%8D%E5%85%B8%EF%BC%88%E7%AC%AC10%E7%89%88%EF%BC%89V3/)，然后进行提取制作。解析、提取mdx/mdd词典资源请参考下载python代码: https://bitbucket.org/xwang/mdict-analysis/src/master/

示例:
1. 提取制作html文件 及 `word_html_map.jso`n:

```pythnon
# coding: utf-8
import hashlib
import json
import os
from readmdict import MDX, MDD
def str_encrypt(bytes):
    """
    使用sha1加密算法，返回str加密后的字符串
     # string.encode('utf-8')
    """
    sha1 = hashlib.sha1()
    sha1.update(bytes)
    return sha1.hexdigest()
 
def makeHtml():
    mdx = MDX('<.mdx文件路径>')
    os.makedirs("html",exist_ok=True)
    i=0
    wordsHtmlSha1Map={}
    items=mdx.items()
    for key,value in items:
        i+=1
        word=key.decode(encoding='utf-8')
        sa1Str=str_encrypt(value)
        dir=sa1Str[:2]
        fName=dir+str(i)
        wordsHtmlSha1Map[word]=fName
        df = open("html/"+fName+".html", 'wb')
        df.write(value)
        df.close()
    b = json.dumps(wordsHtmlSha1Map,sort_keys=True,separators=None,indent="  ",ensure_ascii=False,)
    f2 = open('word_html_map.json', 'w')
    f2.write(b)
    f2.close()
    print(i,"exit with 0")

if __name__ == '__main__':
    makeHtml()
  

```
2. 提取图片、声音资源文件(data 文件夹):
  ```shell
     python readmdict.py -x <.mdd文件>
  ```
3. 制作zip词典数据库压缩文件:
  ```shell
     zip -q -r -9 mydict.zip data/ html/ *.css *.js word_html_map.json
  ```
4. 将以上词典数据库文件添加设置为词典数据库文件
- > 加载本地词典数据库文件--开始解析 
- > <img src="images/add-dict.png" style="width: 49%">

## TODO
- 暗黑主题色