import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler.dart';

import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/widgets/word_common.dart';

class LoopUpWord extends StatefulWidget {
  const LoopUpWord({super.key});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<LoopUpWord> with AutomaticKeepAliveClientMixin {
  List<String> searchResult = [];

  Widget get buildSearchResult {
    return ListView.separated(
        itemBuilder: (context, index) {
          final word = searchResult[index];
          return InkWell(
            child: Text(
              word,
              style: const TextStyle(fontSize: 20),
            ),
            onTap: () {
              showWord(context, word);
            },
          );
        },
        separatorBuilder: (context, index) {
          return const Divider();
        },
        itemCount: searchResult.length);
  }

  void onChange(String v) async {
    v = v.trim();
    if (v == "") {
      searchResult = [];
      setState(() {});
      return;
    }
    final RespData<List<String>> respData;
    final defaultDict = (await handler.getDefaultDict()).data ?? '';
    if (defaultDict == "") {
      respData = await handler.searchByKeyWordWithDefault(v);
    } else {
      respData = await handler.searchByKeyWord(v);
    }
    searchResult = respData.data ?? [];
    setState(() {});
  }

  TextEditingController controller = TextEditingController();

  Widget buildBody() {
    const padding = EdgeInsets.only(left: 10, right: 10, top: 10);
    List<Widget> children = [
      CupertinoSearchTextField(
        controller: controller,
        onChanged: onChange,
        style: TextStyle(
            color: prefs.themeMode == ThemeMode.dark
                ? Colors.white70
                : Colors.black),
      ),
    ];
/*
    if (defaultDict.isEmpty) {
      children.add(Expanded(
          child: Center(
              child: InkWell(
        child: Text(
          "当前无数据库, 点击设置",
          style: TextStyle(fontSize: 22, color: Theme.of(context).primaryColor),
        ),
        onTap: () {
          pushTo(context, const DictDatabase()).then((value) {
            setState(() {});
          });
        },
      ))));
      return Padding(
        padding: padding,
        child: Column(
          children: children,
        ),
      );
    }

    */
    if (searchResult.isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(Expanded(child: buildSearchResult));
    }
    Column column = Column(children: children);

    return Padding(
      padding: padding,
      child: column,
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final body = buildBody();
    return body;
  }

  @override
  bool get wantKeepAlive => true;
}
