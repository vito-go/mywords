
import 'dart:async';
import 'package:flutter/material.dart';

Future<void> blockShowDialog(BuildContext context, Future<void> future) {
  return showDialog(
      context: context,
      builder: (BuildContext context) {
        const waiting = UnconstrainedBox(
          child: SizedBox(
            width: 50,
            height: 50,
            child: CircularProgressIndicator(),
          ),
        );
        return FutureBuilder(
            future: future,
            builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
              //snapshot就是_calculation在时间轴上执行过程的状态快照
              switch (snapshot.connectionState) {
                case ConnectionState.none:
                  return waiting;
                case ConnectionState.waiting:
                  return waiting;
                case ConnectionState.active:
                  return waiting;
                case ConnectionState.done:
                  Future.delayed(const Duration(milliseconds: 0), () {
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  });
                  return const Text("");
              }
            });
      });
}