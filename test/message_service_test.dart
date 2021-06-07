import 'package:chat/src/models/message.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/message/message_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethinkdb_dart/rethinkdb_dart.dart';

import 'helper.dart';

void main() {
  Rethinkdb r = Rethinkdb();
  Connection connection;
  MessageService sut;

  setUp(() async {
    connection = await r.connect(host: "127.0.0.1", port: 28015);
    await createDb(r, connection);
    sut = MessageService(connection, r);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDb(r, connection);
  });

  final user1 =
      User.fromJson({'id': '1234', 'active': true, 'lastseen': DateTime.now()});
  final user2 =
      User.fromJson({'id': '1235', 'active': true, 'lastseen': DateTime.now()});

  test("message subscribe and sent successfully", () async {
    Message message = Message(
        from: user1.id,
        to: '3456',
        timestamp: DateTime.now(),
        contents: 'this is a message');
    Message message2 = Message(
        from: user1.id,
        to: user2.id,
        timestamp: DateTime.now(),
        contents: 'this is a message');

    final res = await sut.send(message);
    expect(res, true);
  });

  test("successfully subscribed and received messages", () async {
    Message message = Message(
        from: user1.id,
        to: user2.id,
        timestamp: DateTime.now(),
        contents: 'this is a message');
    Message message2 = Message(
        from: user1.id,
        to: user2.id,
        timestamp: DateTime.now(),
        contents: 'this is a message');

    await sut.send(message);
    await sut.send(message2).whenComplete(
        () => sut.messages(activeUser: user2).listen(expectAsync1((message) {
              expect(message.to, user2.id);
            }, count: 2)));
  });
}
