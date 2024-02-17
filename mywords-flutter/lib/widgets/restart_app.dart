import 'package:flutter/material.dart';

class RestartApp extends StatefulWidget {
  const RestartApp({super.key, required this.child});

  final StatelessWidget child;

  static void restart(BuildContext context) {
    context.findAncestorStateOfType<RestartAppState>()?.restart();
  }

  @override
  State<StatefulWidget> createState() {
    return RestartAppState();
  }
}

class RestartAppState extends State<RestartApp> {
  Key key = UniqueKey();

  void restart() {
    setState(() {
      key = UniqueKey();
    });
    // SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
    //   setState(() {
    //     key = UniqueKey();
    //   });
    // });
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(key: key, child: widget.child);
  }
}
