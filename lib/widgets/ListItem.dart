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
    final votesTitle = item.votes > 1 ? "Votes" : "Vote";
    Color categoryColor = Theme.of(context).primaryColor;

    if (item.category == "Feature Request") {
      categoryColor = Colors.blue;
    } else if (item.category == "Content Request") {
      categoryColor = Colors.green;
    } else if (item.category == "Idea") {
      categoryColor = Colors.orange;
    } else if (item.category == "Bug") {
      categoryColor = Theme.of(context).accentColor;
    }

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      elevation: 3.0,
      child: ListTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name),
                Divider(
                  height: 5,
                ),
                FlatButton(
                  color: categoryColor,
                  padding: EdgeInsets.all(10),
                  onPressed: null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    item.category,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  item.votes.toString(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  votesTitle,
                  style: TextStyle(
                    color: Colors.black38,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                )
              ],
            ),
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
