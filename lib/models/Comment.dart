import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String displayName;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;
  final DocumentReference reference;

  Comment({this.displayName, this.userId, this.avatarUrl, this.comment, this.timestamp, this.reference});

  Comment.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['displayName'] != null),
        assert(map['userId'] != null),
        assert(map['comment'] != null),
        assert(map['timestamp'] != null),
        assert(map['avatarUrl'] != null),
        displayName = map['displayName'],
        userId = map['userId'],
        comment = map['comment'],
        timestamp = map['timestamp'],
        avatarUrl = map['avatarUrl'];

  Comment.fromSnapshot(DocumentSnapshot snapshot) : this.fromMap(snapshot.data(), reference: snapshot.reference);
}
