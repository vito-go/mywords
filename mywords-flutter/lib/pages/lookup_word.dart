import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
            child: Text(word, style: const TextStyle(fontSize: 20)),
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

    respData = await handler.searchByKeyWord(v);

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
        style: Theme.of(context).textTheme.bodyLarge,
      ),
    ];
    if (searchResult.isNotEmpty) {
      children.add(const SizedBox(height: 10));
      children.add(Expanded(child: buildSearchResult));
    }
    Column column = Column(children: children);
    return Padding(padding: padding, child: column);
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
