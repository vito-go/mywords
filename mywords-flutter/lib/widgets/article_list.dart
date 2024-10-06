import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/config/config.dart';
import 'package:mywords/libso/handler.dart';

import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/pages/article_page.dart';
import 'package:mywords/libso/types.dart';
import 'package:mywords/util/navigator.dart';
import 'package:mywords/util/util.dart';

import 'package:mywords/common/queue.dart';

enum ToEndSlide { archive, unarchive }

class ArticleListView extends StatefulWidget {
  const ArticleListView({
    super.key,
    required this.archived,
    required this.toEndSlide,
    required this.leftLabel,
    required this.leftIconData,
    required this.pageNo,
  });

  final String leftLabel;
  final IconData leftIconData;
  final ToEndSlide toEndSlide;
  final bool archived;
  final int pageNo; // 页码，用来做监听事件区分，1, 2, 3

  @override
  State<ArticleListView> createState() => _State();
}

class _State extends State<ArticleListView> {
  List<FileInfo> fileInfos = [];
  late final archived = widget.archived;

  List<FileInfo> get fileInfosFilter {
    if (kw == "") return fileInfos;
    final kwTrimLower = kw.trim().toLowerCase();
    final List<FileInfo> items = [];
    for (final info in fileInfos) {
      if (info.title.toLowerCase().contains(kwTrimLower)) {
        items.add(info);
      }
    }
    return items;
  }

  @override
  void dispose() {
    super.dispose();
    eventConsumer?.cancel();
    controller.dispose();
    controllerSearch.dispose();
  }

  StreamSubscription<Event>? eventConsumer;

  void slideToUnArchive(FileInfo item) {
    final itemNew = item.copyWith(archived: false);
    final t = Timer(const Duration(milliseconds: 3500), () async {
      final respData = await handler.updateFileInfo(itemNew);
      if (respData.code != 0) {
        myToast(context, respData.message);
        return;
      }
      produceEvent(EventType.updateArticleList);
    });
    // Then show a snackbar.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      // content: Text('文章已取消归档: ${item.title}',
      content: Text('Article has been unarchived: ${item.title}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      action: SnackBarAction(
          label: "撤销",
          onPressed: () {
            t.cancel();
            initFileInfos();
            return;
          }),
    ));
  }

  void slideToArchive(FileInfo item) {
    final itemNew = item.copyWith(archived: true);
    final t = Timer(const Duration(milliseconds: 3500), () async {
      final RespData respData = await handler.updateFileInfo(itemNew);
      if (respData.code != 0) {
        if (!mounted) {
          return;
        }
        myToast(context, respData.message);
        return;
      }
      produceEvent(EventType.updateArticleList);
    });
    // Then show a snackbar.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('文章已归档: ${item.title}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      action: SnackBarAction(
          label: "撤销",
          onPressed: () {
            t.cancel();
            initFileInfos();
            return;
          }),
    ));
  }

  void slideToDelete(FileInfo item) {
    final id = item.id;
    final t = Timer(const Duration(milliseconds: 3500), () async {
      final RespData respData = await handler.deleteGobFile(id);
      if (respData.code != 0) {
        if (!mounted) return;
        myToast(context, respData.message);
        return;
      }
      produceEvent(EventType.updateArticleList);
    });
    // Then show a snackbar.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('文章已删除: ${item.title}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      action: SnackBarAction(
          label: "撤销",
          onPressed: () {
            t.cancel();
            initFileInfos();
            return;
          }),
    ));
  }

  Widget buildFileInfo(List<FileInfo> fileInfosFilter) {
    final listView = ListView.separated(
        controller: controller,
        itemBuilder: (BuildContext context, int index) {
          final item = fileInfosFilter[index];
          Widget? trailing;
          final uri = Uri.tryParse(item.sourceUrl);
          if (uri != null) {
            final assetPath = assetPathByHost(uri.host);
            if (assetPath != "") {
              trailing = ClipOval(
                  child: Image.asset(assetPath, width: 28, height: 28));
            }
          }
          final listTile = ListTile(
              title: Text(item.title,
                  maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: trailing,
              onTap: () {
                pushTo(context, ArticlePage(fileInfo: item));
              },
              minLeadingWidth: 0,
              leading: Text("[${index + 1}]",
                  style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary)),
              subtitle: Text(
                  "${formatTime(DateTime.fromMillisecondsSinceEpoch(item.createAt))}  total:${item.totalCount} net:${item.netCount}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis));
          return Dismissible(
            key: UniqueKey(),
            background: getBackgroundWidget(
              context,
              left: getBackgroundChild(widget.leftLabel, widget.leftIconData),
              right: getBackgroundChild("删除", Icons.delete),
            ),
            direction: DismissDirection.horizontal,
            onDismissed: (DismissDirection direction) {
              myPrint(direction);
              if (direction == DismissDirection.endToStart) {
                slideToDelete(item);
              } else if (direction == DismissDirection.startToEnd) {
                switch (widget.toEndSlide) {
                  case ToEndSlide.archive:
                    slideToArchive(item);
                  case ToEndSlide.unarchive:
                    slideToUnArchive(item);
                }
              }
            },
            child: listTile,
          );
        },
        itemCount: fileInfosFilter.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider();
        });
    return RefreshIndicator(
        child: listView,
        // triggerMode : RefreshIndicatorTriggerMode.anywhere,
        onRefresh: () async {
          produceEvent(EventType.updateLineChart);
          await initFileInfos();
          if (!mounted) return;
          myToast(context, "Successfully!");
        });
  }

  Future<void> initFileInfos() async {
    final respData = await handler.getFileInfoListByArchived(archived);
    if (respData.code != 0) {
      if (!mounted) return;
      myToast(context, respData.message);
      return;
    }
    fileInfos = respData.data ?? [];
    setState(() {});
  }

  void ifShowDialogGuide() {
    if (prefs.toastSlideToDelete == true) {
      return;
    }
    if (fileInfos.isEmpty) return;
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
              // title: const Text("提示"),
              title: const Text("Tips"),
              // content: const Text("向左滑动删除文章, 向右滑动归档文章"),
              content: const Text(
                  "Swipe left to delete the article, swipe right to archive the article"),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    // child: const Text("确认")),
                    child: const Text("OK")),
                TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      prefs.toastSlideToDelete = true;
                    },
                    // child: const Text("不再提示")),
                    child: const Text("Don't show again")),
              ]);
        });
  }

  void eventHandler(Event event) {
    switch (event.eventType) {
      case EventType.updateArticleList:
        initFileInfos();
        break;
      case EventType.syncData:
        initFileInfos();
        break;
      case EventType.updateKnownWord:
        break;
      case EventType.articleListScrollToTop:
        if (widget.pageNo == event.param && fileInfos.isNotEmpty) {
          controller.animateTo(0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.linear);
        }
      case EventType.updateLineChart:
      // TODO: Handle this case.
      case EventType.updateTheme:
      // TODO: Handle this case.
      case EventType.updateDict:
      // TODO: Handle this case.
    }
  }

  @override
  void initState() {
    super.initState();
    initFileInfos().then((value) {
      ifShowDialogGuide();
      eventConsumer = consume(eventHandler);
    });
  }

  Widget getBackgroundChild(String label, IconData iconData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(iconData, color: Colors.white),
        Text(label, style: const TextStyle(color: Colors.white))
      ],
    );
  }

  Widget getBackgroundWidget(BuildContext context,
      {required Widget left, required Widget right}) {
    List<Widget> children = [];
    children.add(left);
    children.add(const Expanded(child: Text("")));
    children.add(right);
    final backgroundWidget = Container(
        color: Theme.of(context).colorScheme.primary,
        child: Padding(
            padding: const EdgeInsets.only(right: 20, left: 20),
            child: Row(children: children)));
    return backgroundWidget;
  }

  ScrollController controller = ScrollController();
  TextEditingController controllerSearch = TextEditingController();
  String kw = "";

  Widget searchEditBuild(int length) {
    return ListTile(
      leading: Text(
        "$length",
        style: const TextStyle(fontSize: 14),
      ),
      title: CupertinoSearchTextField(
        // placeholder: "请输入文章标题关键词",
        placeholder: "keyword of the title",
        controller: controllerSearch,
        style: Theme.of(context).textTheme.bodyLarge,
        onChanged: (String v) {
          kw = v;
          setState(() {});
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final infos = fileInfosFilter;
    return Column(
      children: [
        // ListTile(title: CupertinoSearchTextField(),),
        searchEditBuild(infos.length),
        Expanded(child: buildFileInfo(infos))
      ],
    );
  }
}
