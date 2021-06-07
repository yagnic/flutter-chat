import 'package:flutter/foundation.dart';

class User {
  String get id => _id;
  String username;
  String photourl;
  String _id;
  bool active;
  DateTime lastseen;

  User(
      {@required this.username,
      @required this.photourl,
      @required this.active,
      @required this.lastseen});

  toJson() => {
        'username': username,
        'photo_url': photourl,
        'active': active,
        'last_seen': lastseen
      };

  factory User.fromJson(Map<String, dynamic> json) {
    final user = User(
        username: json['username'],
        photourl: json['photo_url'],
        active: json['active'],
        lastseen: json['last_seen']);

    user._id = json['id'];
    return user;
  }
}
