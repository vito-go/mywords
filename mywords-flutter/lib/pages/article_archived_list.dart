import 'package:flutter/material.dart';
import 'package:mywords/common/queue.dart';
import 'package:mywords/libso/handler.dart';

import 'package:mywords/widgets/article_list.dart';

import 'package:mywords/util/get_scaffold.dart';

class ArticleArchivedPage extends StatefulWidget {
  const ArticleArchivedPage({super.key});

  @override
  State<StatefulWidget> createState() {
    return _State();
  }
}

class _State extends State<ArticleArchivedPage> {
  @override
  Widget build(BuildContext context) {
    return getScaffold(context,
        appBar: AppBar(
          title: const Text("Archived Articles"),
          actions: [
            IconButton(
                onPressed: () {
                  // 归档置顶
                  produceEvent(EventType.articleListScrollToTop, 2);
                },
                icon: const Icon(Icons.vertical_align_top_outlined))
          ],
        ),
        body: const ArticleListView(
          archived: true,
          toEndSlide: ToEndSlide.unarchive,
          // leftLabel: '恢复',
          leftLabel: 'Restore',
          leftIconData: Icons.restore,
          pageNo: 2,
        ));
  }
}
