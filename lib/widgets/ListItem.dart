import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/RequestDetail.dart';
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

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      elevation: 3.0,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 0, vertical: 10),
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            mainAxisSize: MainAxisSize.max,
            children: [
              Flexible(
                child: Container(
                  padding: new EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        item.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    margin: EdgeInsets.only(right: 25),
                    child: FlatButton(
                      color: item.type.color,
                      padding: EdgeInsets.symmetric(horizontal: 15, vertical: -2),
                      hoverColor: item.type.color,
                      onPressed: () {},
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        item.type.name,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
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
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return RequestDetail(item: item, reference: item.reference);
            }));
          },
        ),
      ),
    );
  }
}
