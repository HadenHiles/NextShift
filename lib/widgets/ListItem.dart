import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/models/Item.dart';

import '../Login.dart';

class ListItem extends StatefulWidget {
  ListItem({Key key, this.data}) : super(key: key);

  final DocumentSnapshot data;

  @override
  _ListItemState createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final item = Item.fromSnapshot(widget.data);
    final hasVoted = user != null ? item.voters.contains(user.uid) : false;

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      elevation: 3.0,
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item.name),
            Text(item.votes.toString()),
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.thumb_up,
            color: hasVoted ? Theme.of(context).accentColor : Colors.grey,
          ),
          onPressed: hasVoted
              ? () async {
                  await FirebaseFirestore.instance.runTransaction(
                    (transaction) async {
                      final freshSnapshot = await transaction.get(item.reference);
                      final fresh = Item.fromSnapshot(freshSnapshot);

                      if (fresh.voters.contains(user.uid)) {
                        fresh.voters.remove(user.uid);
                      }

                      transaction.update(item.reference, {
                        'votes': fresh.votes - 1,
                        'voters': fresh.voters,
                      });
                    },
                  );
                }
              : () async {
                  if (user == null) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                      return Login();
                    }));
                  } else {
                    await FirebaseFirestore.instance.runTransaction(
                      (transaction) async {
                        final freshSnapshot = await transaction.get(item.reference);
                        final fresh = Item.fromSnapshot(freshSnapshot);

                        if (!fresh.voters.contains(user.uid)) {
                          fresh.voters.add(user.uid);
                        }

                        transaction.update(item.reference, {
                          'votes': fresh.votes + 1,
                          'voters': fresh.voters,
                        });
                      },
                    );
                  }
                },
        ),
      ),
    );
  }
}
