import 'dart:async';

StreamController<GlobalEvent> _globalEventBroadcast =
    StreamController.broadcast();

enum GlobalEventType {
  parseAndSaveArticle,
  syncData,
  updateKnownWord,
  archiveArticle,
}

void addToGlobalEvent(GlobalEvent event) {
  _globalEventBroadcast.add(event);
}

StreamSubscription<GlobalEvent> subscriptGlobalEvent(
    Function(GlobalEvent event) onData) {
  return _globalEventBroadcast.stream.listen(onData);
}

class GlobalEvent<T> {
  GlobalEventType eventType;
  dynamic param;

  GlobalEvent({required this.eventType, this.param});
}
