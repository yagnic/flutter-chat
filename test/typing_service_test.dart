import 'package:chat/src/models/typing_event.dart';
import 'package:chat/src/models/user.dart';
import 'package:chat/src/services/typing/typing_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rethinkdb_dart/rethinkdb_dart.dart';

import 'helper.dart';

void main() {
  Rethinkdb r = Rethinkdb();
  Connection connection;
  TypingService sut;

  setUp(() async {
    connection = await r.connect(host: '127.0.0.1', port: 28015);

    await createDb(r, connection);
    sut = TypingService(r, connection);
  });

  tearDown(() async {
    sut.dispose();
    await cleanDb(r, connection);
  });

  final user = User.fromJson({
    'id': '1234',
    'active': true,
    'lastSeen': DateTime.now(),
  });

  final user2 = User.fromJson({
    'id': '1111',
    'active': true,
    'lastSeen': DateTime.now(),
  });

  test('sent typing notification success', () async {
    TypingEvent typingEvent =
        TypingEvent(from: user.id, to: user2.id, event: Typing.start);

    final res = await sut.send(event: typingEvent, to: user);
    expect(res, true);
  });

  test('successfully subscribe and receive typing events', () async {
    sut.subscribe(user2, [user.id]).listen(expectAsync1((event) {
      expect(event.from, user.id);
    }, count: 2));

    TypingEvent typing = TypingEvent(
      to: user2.id,
      from: user.id,
      event: Typing.start,
    );

    TypingEvent stopTyping = TypingEvent(
      to: user2.id,
      from: user.id,
      event: Typing.stop,
    );

    await sut.send(event: typing, to: user2);
    await sut.send(event: stopTyping, to: user2);
  });
}
