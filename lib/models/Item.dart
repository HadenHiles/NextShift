import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String name;
  final int votes;
  final String description;
  final String category;
  final String userId;
  final bool upNext;
  final DocumentReference reference;

  Item.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        assert(map['description'] != null),
        assert(map['category'] != null),
        assert(map['user_id'] != null),
        name = map['name'],
        votes = map['votes'],
        description = map['description'],
        category = map['category'],
        userId = map['user_id'],
        upNext = map['up_next'] != null ? map['up_next'] : false;

  Item.fromSnapshot(DocumentSnapshot snapshot) : this.fromMap(snapshot.data(), reference: snapshot.reference);

  @override
  String toString() => "Item<$name:$votes:$category>";
}
