package dict

const dictAssetDataDir = "data" // data dir 包含mp3,css,js,png
const htmlDir = "html"
const wordHtmlMapJsonName = "word_html_map.json"
const dictInfoJson = "dict_info.json" // zip 文件格式
const linkPrefix = "@@@LINK="

const entryDiv = `<big>👉<a class="Ref" href="entry://%s">%s</a></big>`

// tmpl webview 静态网页数据处理时,必须有head,body 标签
const tmpl = `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>%s</title>
    <style></style>
</head>
<body>
    %s
</body>
</html>`
