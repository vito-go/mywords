import 'dart:async';

StreamController<Event> _globalEventBroadcast = StreamController.broadcast();

enum EventType {
  syncData,
  updateKnownWord,
  updateArticleList,
  articleListScrollToTop,
  updateLineChart,
  updateTheme,
  updateDict,
}

// deprecated use produceEvent
void produce(Event event) {
  _globalEventBroadcast.add(event);
}

void produceEvent(EventType eventType, [dynamic param]) {
  final event = Event(eventType: eventType, param: param);
  _globalEventBroadcast.add(event);
}

StreamSubscription<Event> consume(Function(Event event) onData) {
  return _globalEventBroadcast.stream.listen(onData);
}

class Event<T> {
  EventType eventType;
  dynamic param;

  Event({required this.eventType, this.param});
}
