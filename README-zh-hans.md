## [English Version](README.md) | [中文版](README-zh-hans.md)

## 项目概览

本项目提供一个英语单词学习工具，专为英语学习者设计，通过阅读英文或双语文章来扩充词汇库。用户能够自动提取学习文章中的单词、统计词频、筛选过滤，同时跟踪和记录单词掌握程度。
- 背单词神器! 输入一个英语或双语文章的网址，本工具将自动提取文章中所有单词及其所在句子，对文章单词进行去重、统计汇总。你可以过滤筛选只显示出你不认识的单词。
- 本工具支持自定义词典库，用户可以添加自己的词典库，以便在学习过程中查阅单词释义。

## 下载和安装
- 请跳转到 [GitHub Release](https://github.com/vito-go/mywords/releases) 页面下载适合您平台的版本。
- Google Play Store:
  > https://play.google.com/store/apps/details?id=com.mywords.android
- 苹果App Store: 等待中


## 更新日志
- [CHANGE_LOG.md](CHANGE_LOG.md)

## 功能特点

- **单词提取与记录**：输入一个网址，工具自动检索网页文章并提取里面的**所有单词**和它们的语境**句子**。同时，会计算并展示文章的**词汇量**。
- **智能管理与筛选**：避免重复学习你已知晓的单词，通过去重功能和排除掉你已掌握词汇选项以集中精力学习新词汇。
- **学习进度跟踪**：单词可标记为不同认知等级，包括“0:陌生”，“1:了解”，“2:认识”，“3:熟悉”。这有助于定制化学习路径，同时加深记忆。
- **筛选浏览功能**：过滤出特定认知等级的单词，例如选定标记“0”能显示所有你尚不了解的单词。
- **同步和平台兼容性**： 基于`Go`和`Flutter`开发的跨平台应用，支持在 Android、Linux 和 Windows 使用，支持设备间数据同步，便捷学习不受限制。
- **web版本支持**：支持本地部署或云端部署，可以在浏览器打开web应用，使用体验与桌面应用和移动应用一致。
- **本地数据存储**：无需依赖后台服务器，确保所有数据均在本地安全存储。

## 开发与技术支持
该工具的开发考虑到跨平台兼容性和用户方便性，不仅采用了性能优良的`go`语言实核心逻辑，同时以`flutter`保证了良好的用户界面体验和跨平台的一致性。用户无论在何种设备上学习，都能确保学习进展无缝同步。

立足于学习英语的需求，我们的目标是创建一个简洁、高效且用户友好的单词学习辅助工具。欢迎使用本工具加速你的语言学习旅程。

## 阅读与词汇量提升
阅读英文文章被广泛认为是提高词汇量的有效手段。根据数据分析，每篇英文文章中约有50%至70%的有效词汇。请注意，已经自动剔除了文章中的标点符号、冠词、介词等简单词汇（例如a, in, on, the, I, than, you, he等）。我们建议你应该：

- **坚持每天阅读**：形成每日阅读英文文章的习惯，无论是新闻、专业论文或是小说。
- **记录新词汇**：遇到新单词时，利用本工具记录下来，并分类它们的认知程度。

## 进步的衡量
持续的阅读实践将直接反映在你词汇量的增长上。随着时间的积累，你会发现：

- **“0级陌生单词”减少**：读每一篇新文章时，遇到完全不认识的单词数量会逐渐减少。
- **读懂文章的速度提升**：你会越来越快地读懂文章，理解深度和速度都会有显著提升。

坚持在阅读中实践并使用工具来辅助你记录和回顾这些新词汇，是促进你英语能力提高的关键。随着你词汇量的增加，不仅能更流畅地阅读，更能提升写作和对话能力。

## 学习资源推荐
为了有效使用本工具并提升你的英语水平，本项目推荐以下英文阅读资源，它们不仅提供了丰富的双语内容，还覆盖了广泛的主题，适合各水平的学习者:

- **The New York Times 中英文版**：访问[The New York Times 中英文版](https://cn.nytimes.com/zh-hant/)来获取优质的双语阅读材料，这将有助于提升你的英语理解能力和词汇量。
  ![双语英文学习资源图标](https://raw.githubusercontent.com/vito-go/assets/master/mywords/images/dual.png)


- **The Economist China 经济学人-中国**: [The Economist China](https://www.economist.com/topics/china): 贴近中国读者的英语内容，覆盖政治、经济、科技等领域，对于希望深入了解全球话题的学习者来说非常有益。
  ![img.png](https://raw.githubusercontent.com/vito-go/assets/master/mywords/images/the-economist-china.png)
利用这些资源，你不仅能够有针对性地扩充你的词汇，也可以深入了解不同的话题和背景知识，全方位提升英语能力。
## 构建指南
- [Build Guide](BUILD_GUIDE_zh-hans.md)

## 预览
<img src="https://raw.githubusercontent.com/vito-go/assets/master/mywords/images/mywords.jpg">

## 添加词典指南
[添加词典指南](ADD_DICTIONARY_GUIDE_zh-hans.md)

## TODO
- [x] 暗黑主题色
- [x] 桌面web版本支持，支持本地部署及云端部署. 并支持在android设备Termux中运行.
- [x] 在移动版本中集成web版本，多设备间无缝学习.
- [x] README.md of English version
- [x] 代理设置支持配置用户名和密码
- [x] 在web版本中，敏感函数如`DelDict`只允许在本地环境中调用

---

## 联系和支持**：
- 如果你在使用本工具或添加词典时遇到了问题，或者想要与我们分享你的学习经验和进度，请通过以下方式联系我们：
  - Email：`vitogo2024@gmail.com`
  - 加入我们的 Telegram 群组： https://t.me/+O6mfB2ElB_ViYmM1


## 鸣谢

我们衷心感谢以下个人和组织对本项目的支持和贡献：

- 感谢 [The New York Times 中英文版](https://cn.nytimes.com/zh-hant/)为我们提供了优质的双语阅读材料，这对于英语学习者们非常有帮助。
- 感谢 [The Economist China](https://www.economist.com/topics/china) 为我们提供的高质量英文阅读材料，为我们的学习提供了丰富的内容。
- 我们对 [Bitbucket.org/xwang](https://bitbucket.org/xwang/mdict-analysis/src/master/)提供的 Python 词典解析工具表示特别鸣谢，这对我们构建词汇数据库至关重要。
- 特别感谢[louischeung.top](http://louischeung.top:225/mdict%E8%AF%8D%E5%85%B8%E5%8C%85/) 提供的牛津高阶英汉双解词典，这资源对于英语学习者们非常有价值。
- 我们对所有通过 Telegram 或 Email 主动提供反馈和建议的用户表示深深的谢意。
- 感谢所有贡献者、测试者和使用我们工具的用户，是你们的支持让这个项目不断进步。

此外，我们还要感谢所有在幕后默默支持这个项目的朋友们。你们的鼓励和意见是项目不断发展的源泉。

