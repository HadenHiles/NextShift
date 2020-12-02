import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nextshift/models/RequestType.dart';

class Item {
  final String name;
  final int votes;
  final List<dynamic> voters;
  final String description;
  final String platform;
  final RequestType type;
  final String createdBy;
  final bool upNext;
  final bool complete;
  final DocumentReference reference;

  Item.fromMap(Map<String, dynamic> map, {this.reference})
      : assert(map['name'] != null),
        assert(map['votes'] != null),
        assert(map['voters'] != null),
        assert(map['description'] != null),
        assert(map['platform'] != null),
        assert(map['type'] != null),
        assert(map['created_by'] != null),
        assert(map['complete'] != null),
        name = map['name'],
        votes = map['votes'],
        voters = map['voters'],
        description = map['description'],
        platform = map['platform'],
        type = RequestType(name: map['type']),
        createdBy = map['created_by'],
        upNext = map['up_next'] != null ? map['up_next'] : false,
        complete = map['complete'] != null ? map['complete'] : false;

  Item.fromSnapshot(DocumentSnapshot snapshot) : this.fromMap(snapshot.data(), reference: snapshot.reference);
}
