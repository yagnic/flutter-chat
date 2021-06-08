import 'dart:async';

import 'package:chat/src/models/user.dart';
import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/services/typing/typing_service_contract.dart';
import 'package:flutter/foundation.dart';
import 'package:rethinkdb_dart/rethinkdb_dart.dart';

class TypingService extends ITypingNotification {
  final Rethinkdb r;
  final Connection connection;

  final _controller = StreamController<TypingEvent>();

  StreamSubscription _changefeed;

  TypingService(this.r, this.connection);

  @override
  Future<bool> send({TypingEvent event, @required User to}) async {
    if (!to.active) {
      return false;
    }
    Map record = await r
        .table('typing_events')
        .insert(event.toJson(), {'conflict': 'update'}).run(connection);

    return record['inserted'] == 1;
  }

  @override
  Stream<TypingEvent> subscribe(User user, List<String> userIds) {
    _startReceivingTypingEvents(user, userIds);
    return _controller.stream;
  }

  @override
  dispose() {
    _changefeed?.cancel();
    _controller?.close();
  }

  _startReceivingTypingEvents(User user, List<String> userIds) {
    _changefeed = r
        .table('typing_events')
        .filter((event) {
          return event('to')
              .eq(user.id)
              .and(r.expr(userIds).contains(event('from')));
        })
        .changes({'include_initial': true})
        .run(connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event.forEach((feedData) {
            if (feedData['new_val'] == null) return;

            final typing = _eventFromFeed(feedData);
            _controller.sink.add(typing);
            _removeEvent(typing);
          }).catchError((err) {
            print(err);
          }).onError((error, stackTrace) => print(error));
        });
  }

  TypingEvent _eventFromFeed(feedData) {
    return TypingEvent.fromJson(feedData['new_val']);
  }

  _removeEvent(TypingEvent event) {
    r
        .table('typing_events')
        .get(event.id)
        .delete({'return_changes': false}).run(connection);
  }
}
