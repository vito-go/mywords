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
import 'package:mywords/util/util_native.dart'
    if (dart.library.html) 'package:mywords/util/util_web.dart';

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
    final kwTrimLower = kw.trim().toLowerCase();
    final List<FileInfo> items = [];
    final selected = prefs.hostFilterByArchived(archived);
    for (final info in fileInfos) {
      final contained = selected.contains("-") || selected.contains(info.host);
      if ((kwTrimLower == "" ||
              info.title.toLowerCase().contains(kwTrimLower)) &&
          contained) {
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
      produceEvent(EventType.updateArticleList);
      if (respData.code != 0) {
        myToast(context, respData.message);
        return;
      }
    });
    // Then show a snackbar.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Article has been unarchived: ${item.title}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      action: SnackBarAction(
          label: "Revoke",
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
      produceEvent(EventType.updateArticleList);

      if (respData.code != 0) {
        if (!mounted) {
          return;
        }
        myToast(context, respData.message);
        return;
      }
    });
    // Then show a SnackBar.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Article has been archived: ${item.title}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      action: SnackBarAction(
          label: "Revoke",
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
      produceEvent(EventType.updateArticleList);
      if (respData.code != 0) {
        if (!mounted) return;
        myToast(context, respData.message);
        return;
      }
    });
    // Then show a snackbar.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Article has been deleted: ${item.title}',
          maxLines: 1, overflow: TextOverflow.ellipsis),
      action: SnackBarAction(
          label: "Revoke",
          onPressed: () {
            t.cancel();
            initFileInfos();
            return;
          }),
    ));
  }

  Widget buildListTileArticle(int index, FileInfo item) {
    Widget? trailing;
    final uri = Uri.tryParse(item.sourceUrl);
    if (uri != null) {
      final assetPath = assetPathByHost(uri.host);
      if (assetPath != "") {
        trailing =
            ClipOval(child: Image.asset(assetPath, width: 28, height: 28));
      }
    }
    return ListTile(
        title: Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: trailing,
        onTap: () {
          pushTo(context, ArticlePage(fileInfo: item));
        },
        minLeadingWidth: 0,
        leading: Text("[${index + 1}]",
            style: TextStyle(
                fontSize: 14, color: Theme.of(context).colorScheme.primary)),
        subtitle: Text(
            "${formatTime(DateTime.fromMillisecondsSinceEpoch(item.createAt))}  total:${item.totalCount} net:${item.netCount}",
            maxLines: 1,
            overflow: TextOverflow.ellipsis));
  }

  Widget buildFileInfo(List<FileInfo> fileInfosFilter) {
    final listView = ListView.separated(
        controller: controller,
        itemBuilder: (BuildContext context, int index) {
          final item = fileInfosFilter[index];
          final listTile = buildListTileArticle(index, item);
          return Dismissible(
            key: UniqueKey(),
            background: getBackgroundWidget(
              context,
              left: getBackgroundChild(widget.leftLabel, widget.leftIconData),
              right: getBackgroundChild("Delete", Icons.delete),
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
              title: const Text("Tips"),
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
  static const all = '-';

  Widget get hostFilterButton {
    final selected = prefs.hostFilterByArchived(archived);
    final desktopWeb = platFormIsDesktopWeb();

    return IconButton(
        onPressed: () async {
          final allSourceHosts = await handler.allSourceHosts(archived);
          final int total = allSourceHosts.fold(
              0, (previousValue, element) => previousValue + element.count);
          if (!context.mounted) return;
          showDialog(
              context: context,
              builder: (BuildContext context) {
                final statefulBuilder = StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState1) {
                  final hostFilterByArchived =
                      prefs.hostFilterByArchived(archived);

                  onChange(String host, bool v) {
                    if (v == true) {
                      hostFilterByArchived.remove(host);
                      hostFilterByArchived.add(host);
                      if (hostFilterByArchived.length >=
                          allSourceHosts.length) {
                        hostFilterByArchived.clear();
                        hostFilterByArchived.add(all);
                      }
                      prefs.setHostFilterByArchived(
                          archived, hostFilterByArchived);
                    } else if (v == false) {
                      if (hostFilterByArchived.contains(all)) {
                        hostFilterByArchived.clear();
                        for (var element in allSourceHosts) {
                          if (element.host == host) continue;
                          hostFilterByArchived.add(element.host);
                        }
                        prefs.setHostFilterByArchived(
                            archived, hostFilterByArchived);
                      } else {
                        hostFilterByArchived.remove(host);
                        prefs.setHostFilterByArchived(
                            archived, hostFilterByArchived);
                      }
                    }
                    myPrint(hostFilterByArchived.length);
                    setState1(() {});
                    setState(() {});
                  }

                  Widget buildHost(HostCount h) {
                    return ListTile(
                      title: Text(h.host),
                      minLeadingWidth: 0,
                      subtitle: !desktopWeb ? Text("count: ${h.count}") : null,
                      trailing: desktopWeb ? Text("count: ${h.count}") : null,
                      leading: Checkbox(
                          value: hostFilterByArchived.contains(h.host) ||
                              hostFilterByArchived.contains(all),
                          onChanged: (v) {
                            if (v == null) return;
                            onChange(h.host, v);
                          }),
                      onTap: () {
                        final v = hostFilterByArchived.contains(h.host) ||
                            hostFilterByArchived.contains(all);
                        onChange(h.host, !v);
                      },
                    );
                  }

                  final listView = ListView.builder(
                      itemCount: allSourceHosts.length,
                      itemBuilder: (BuildContext context, int index) {
                        return buildHost(allSourceHosts[index]);
                      });
                  selectAll(bool v) {
                    if (v == true) {
                      hostFilterByArchived.clear();
                      hostFilterByArchived.add(all);
                      prefs.setHostFilterByArchived(
                          archived, hostFilterByArchived);
                    } else if (v == false) {
                      hostFilterByArchived.clear();
                      prefs.setHostFilterByArchived(
                          archived, hostFilterByArchived);
                    }
                    setState1(() {});
                    setState(() {});
                  }

                  final col = Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Align(
                        alignment: AlignmentDirectional.centerEnd,
                        child: IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            icon: const Icon(Icons.close)),
                      ),
                      ListTile(
                          title: Text("All"),
                          subtitle:
                              !desktopWeb ? Text("total count: $total") : null,
                          trailing:
                              desktopWeb ? Text("total count: $total") : null,
                          leading: Checkbox(
                              value: hostFilterByArchived.contains(all),
                              onChanged: (v) {
                                if (v == null) return;
                                selectAll(v);
                              }),
                          onTap: () {
                            final v = hostFilterByArchived.contains(all);
                            selectAll(!v);
                          }),
                      Divider(),
                      Expanded(child: listView)
                    ],
                  );

                  return col;
                });

                if (platFormIsDesktopWeb()) {
                  final width = getPlatformWebWidth(context);
                  return UnconstrainedBox(
                    constrainedAxis: Axis.vertical,
                    child: SizedBox(
                        width: width, child: Dialog(child: statefulBuilder)),
                  );
                }
                return Dialog(child: statefulBuilder);
              });
        },
        icon: Icon(
            selected.contains(all) ? Icons.filter_alt_off : Icons.filter_alt));
  }

  Widget searchEditBuild(int length) {
    return ListTile(
      leading: Text("$length", style: const TextStyle(fontSize: 14)),
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
      trailing: hostFilterButton,
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
