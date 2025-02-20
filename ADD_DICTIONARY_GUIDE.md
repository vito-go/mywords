
## Adding Dictionary Guide

To fully utilize the word learning and lookup features of this tool, you may need to add dictionary libraries with detailed word definitions. As dictionary database files can be large, please follow these steps to add them:


1. **Download Dictionary Database**：
- Visit the provided non-permanent download link  `http://vitogo.tpddns.cn:19081/_download/dict-ox10-v3.zip` and copy the link to your browser to download the dictionary data file.。

2. **Contact and Support**：
- If you encounter any issues while using this tool or adding dictionaries, or if you want to share your learning experiences and progress with us, please contact us via:
    - Email：`vitogo2024@gmail.com`
    - 加入我们的 Telegram 群组： https://t.me/+O6mfB2ElB_ViYmM1

3. **Dictionary Library Format Description**:
- The dictionary library should be a zip compressed file containing the following contents:

  ![zip-dict.png](https://raw.githubusercontent.com/vito-go/assets/master/mywords/images/zip-dict.png)

- Structure Description:
    - `data/`: Folder containing dictionary resource files such as images, sounds, etc.
    - `html/`: Folder containing html page files for word definitions, with filenames including the `.html` suffix.
    - `*.css`, `*.js`:  Static resource files, can be placed in the root directory of the zip file or in the data folder.
    - `word_html_map.json`: JSON file containing the mapping between words and html filenames, in key-value pairs ("key" is the word, "value" is the html filename without the `.html` suffix).

4. **Creating Custom Dictionary Data**:
- You can download mdx/mdd format dictionary files, for example, [牛津高阶英汉双解词典（第10版）V3](http://louischeung.top:225/mdict%E8%AF%8D%E5%85%B8%E5%8C%85/%E7%89%9B%E6%B4%A5%E9%AB%98%E9%98%B6%E8%8B%B1%E6%B1%89%E5%8F%8C%E8%A7%A3%E8%AF%8D%E5%85%B8%EF%BC%88%E7%AC%AC10%E7%89%88%EF%BC%89V3/)
- Obtain and use related Python code for extracting and converting mdx/mdd resources:
    - Resource conversion code link: [https://bitbucket.org/xwang/mdict-analysis/src/master/](https://bitbucket.org/xwang/mdict-analysis/src/master/)

## Creating Dictionary Database Files


After downloading the MDX/MDD format dictionary files and extracting the code files for dictionary resources, you need to follow these steps to create the dictionary database file:
1. **Extract and create HTML files and `word_html_map.json`:**:
    ```python
    # coding: utf-8
    import json
    import os
    from readmdict import MDX
    import os
    import sys
    
     
    def makeHtml(mdxPath):
        mdx = MDX(mdxPath)
        base_dir=os.path.dirname(mdxPath)
        all_words_path=os.path.join(base_dir,"word_html_map.json")
        html_dir=os.path.join(base_dir,"html")
        print("html directory is: "+html_dir)
        print("all words json file path: "+all_words_path)
        os.makedirs(html_dir,exist_ok=True)
        i=1
        allWordsMap={}
        items=mdx.items()
        for key,value in items:
            word=key.decode(encoding='utf-8')
            # ### Fix the issue where some image tags are incorrectly placed within span tags in certain dictionary HTML files. If there are no such issues, you can comment out the replacement logic below.
            htmlContent=value.decode().strip()
            if htmlContent.startswith("<span id=")and htmlContent.endswith("</span>") and 'src="data:image/' in htmlContent:
                htmlContent=htmlContent.replace("<span id=","<img id=")
                htmlContent=htmlContent.replace("</span>","</img>")
                htmlContent=htmlContent.replace('style="display:none"','style="max-width: 100%"')
            value=htmlContent.encode()
            # ##############
            work_html_name = str(i)
            allWordsMap[word]=work_html_name
            html_path=os.path.join(html_dir,work_html_name+".html")
            df = open(html_path, 'wb')
            df.write(value)
            df.close()
            i+=1
        b = json.dumps(allWordsMap,sort_keys=True,separators=None,indent="  ",ensure_ascii=False,)
        f2 = open(all_words_path, 'w')
        f2.write(b)
        f2.close()
        print(i,"exit with 0")
    
    if __name__ == '__main__':
        # python extract_html.py <mdx_path>
        mdx_path=sys.argv[1]
        makeHtml(mdx_path)
    ```


- 2. **Extract image and sound resource files (data folder)**:
```shell
   python readmdict.py -x <.mdd file>
```
- 3. **Create a zip dictionary database compression file**:
```shell
   zip -q -r -9 mydict.zip data/ html/ *.css *.js word_html_map.json
```
    - If the compression file contains other files, such as .ini files, you can add the corresponding file names in the zip command.
- 4. **Set the above dictionary database files as the dictionary database files**
    - > Load local dictionary database file -- start parsing
    - > <img src="https://raw.githubusercontent.com/vito-go/assets/master/mywords/images/add-dict.png" style="width: 256px">

Please follow the above steps to ensure that the dictionary data is correctly added to your learning tool, so that you can refer to detailed definitions of words and phrases during your learning process, thereby effectively improving your language skills.
