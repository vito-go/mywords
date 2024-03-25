import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mywords/common/prefs/prefs.dart';
import 'package:mywords/libso/handler_for_native.dart'
    if (dart.library.html) 'package:mywords/libso/handler_for_web.dart';

import 'package:mywords/libso/resp_data.dart';
import 'package:mywords/pages/article_page.dart';
import 'package:mywords/libso/types.dart';
import 'package:mywords/util/navigator.dart';
import 'package:mywords/util/util.dart';

import 'package:mywords/common/global_event.dart';

enum ToEndSlide { archive, unarchive }

class ArticleListView extends StatefulWidget {
  const ArticleListView({
    super.key,
    required this.getFileInfos,
    required this.toEndSlide,
    required this.leftLabel,
    required this.leftIconData,
    required this.pageNo,
  });

  final String leftLabel;
  final IconData leftIconData;
  final ToEndSlide toEndSlide;
  final int pageNo; // 页码，用来做监听事件区分，1, 2, 3

  final FutureOr<RespData<List<FileInfo>>> Function() getFileInfos;

  @override
  State<ArticleListView> createState() => _State();
}

class _State extends State<ArticleListView> {
  List<FileInfo> fileInfos = [];

  @override
  void dispose() {
    super.dispose();
    globalEventSubscription?.cancel();
    controller.dispose();
  }

  StreamSubscription<GlobalEvent>? globalEventSubscription;

  void slideToUnArchive(FileInfo item) {
    final fileName = item.fileName;
    final t = Timer(const Duration(milliseconds: 4000), () async {
      final respData = await handler.unArchiveGobFile(fileName);
      if (respData.code != 0) {
        myToast(context, respData.message);
        return;
      }
      addToGlobalEvent(
          GlobalEvent(eventType: GlobalEventType.updateArticleList));
    });
    // Then show a snackbar.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('文章已取消归档: ${item.title}',
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
    final fileName = item.fileName;
    final t = Timer(const Duration(milliseconds: 4000), () async {
      final RespData respData = await handler.archiveGobFile(fileName);
      if (respData.code != 0) {
        if (!context.mounted) {
          return;
        }
        myToast(context, respData.message);
        return;
      }
      addToGlobalEvent(
          GlobalEvent(eventType: GlobalEventType.updateArticleList));
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
    final fileName = item.fileName;
    final t = Timer(const Duration(milliseconds: 4000), () async {
      final RespData respData = await handler.deleteGobFile(fileName);
      if (respData.code != 0) {
        if (!context.mounted) return;
        myToast(context, respData.message);
        return;
      }
      addToGlobalEvent(
          GlobalEvent(eventType: GlobalEventType.updateArticleList));
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

  Widget buildFileInfo() {
    final listView = ListView.separated(
        controller: controller,
        itemBuilder: (BuildContext context, int index) {
          final item = fileInfos[index];
          final listTile = ListTile(
              title: Text(
                "${item.title} ${item.sourceUrl}",
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () {
                pushTo(context, ArticlePage(fileName: item.fileName))
                    .then((value) {});
              },
              minLeadingWidth: 0,
              leading:
                  Text("[${index + 1}]", style: const TextStyle(fontSize: 14)),
              subtitle: Text(
                "${formatTime(DateTime.fromMillisecondsSinceEpoch(item.lastModified))} total:${item.totalCount} net:${item.netCount}",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ));
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
        itemCount: fileInfos.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider();
        });
    return RefreshIndicator(
        child: listView,
        // triggerMode : RefreshIndicatorTriggerMode.anywhere,
        onRefresh: () async {
          addToGlobalEvent(GlobalEvent(eventType: GlobalEventType.updateLineChart));
          await initFileInfos();
          if (!context.mounted) return;
          myToast(context, "Successfully!");
        });
  }

  Future<void> initFileInfos() async {
    final respData = await widget.getFileInfos();
    if (respData.code != 0) {
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
              title: const Text("提示"),
              content: const Text("向左滑动删除文章, 向右滑动归档文章"),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text("确认")),
                ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      prefs.toastSlideToDelete = true;
                    },
                    child: const Text("不再提示")),
              ]);
        });
  }

  void globalEventHandler(GlobalEvent event) {
    switch (event.eventType) {
      case GlobalEventType.updateArticleList:
        initFileInfos();
        break;
      case GlobalEventType.syncData:
        initFileInfos();
        break;
      case GlobalEventType.updateKnownWord:
        break;
      case GlobalEventType.articleListScrollToTop:
        if (widget.pageNo == event.param && fileInfos.isNotEmpty) {
          controller.animateTo(0,
              duration: const Duration(milliseconds: 150),
              curve: Curves.linear);
        }
      case GlobalEventType.updateLineChart:
      // TODO: Handle this case.
    }
  }

  @override
  void initState() {
    super.initState();
    initFileInfos().then((value) {
      ifShowDialogGuide();
      globalEventSubscription = subscriptGlobalEvent(globalEventHandler);
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

  @override
  Widget build(BuildContext context) {
    return buildFileInfo();
  }
}
