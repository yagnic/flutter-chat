import 'dart:async';

import 'package:chat/src/models/user.dart';
import 'package:chat/src/models/message.dart';
import 'package:chat/src/services/message/message_service_contract.dart';
import 'package:rethinkdb_dart/rethinkdb_dart.dart';

class MessageService implements IMessageService {
  final Connection connection;
  final Rethinkdb r;

  final _controller = StreamController<Message>.broadcast();
  StreamSubscription _changefeed;

  MessageService(this.connection, this.r);
  @override
  dispose() {
    // TODO: implement dispose
    _changefeed?.cancel();
    _controller?.close();
  }

  @override
  Stream<Message> messages({User activeUser}) {
    _startReceivingMessages(activeUser);
    return _controller.stream;
  }

  @override
  Future<bool> send(Message message) async {
    // TODO: implement send
    Map record =
        await r.table('messages').insert(message.toJson()).run(connection);
    return record['inserted'] == 1;
  }

  _startReceivingMessages(User user) {
    _changefeed = r
        .table('messages')
        .filter({'to': user.id})
        .changes({'include_initial': true})
        .run(connection)
        .asStream()
        .cast<Feed>()
        .listen((event) {
          event.forEach((feedData) {
            if (feedData['new_val'] == null) return;
            final message = _messageFromFeed(feedData);
            _controller.sink.add(message);
            _removeDeliveredMessage(message);
          }).catchError((err, stackTrace) => print(err));
        });
  }

  Message _messageFromFeed(feedData) {
    return Message.fromJson(feedData['new_val']);
  }

  _removeDeliveredMessage(Message message) {
    r
        .table('messages')
        .get(message.id)
        .delete({'return_changes': false}).run(connection);
  }
}
