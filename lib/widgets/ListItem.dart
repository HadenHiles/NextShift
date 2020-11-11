import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/RequestDetail.dart';
import 'package:nextshift/globals/Roles.dart';
import 'package:nextshift/models/Item.dart';
import 'package:nextshift/models/RequestType.dart';
import '../Login.dart';

final bool admin = Roles.admins.contains(FirebaseAuth.instance.currentUser?.uid);

class ListItem extends StatefulWidget {
  ListItem({Key key, this.item, this.filterBy, this.filterType, this.includeType}) : super(key: key);

  final Item item;
  final Function filterBy;
  final RequestType filterType;
  final Function includeType;

  @override
  _ListItemState createState() => _ListItemState();
}

class _ListItemState extends State<ListItem> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    final hasVoted = user != null ? widget.item.voters.contains(user.uid) : false;
    final votesTitle = widget.item.votes > 1 ? "Votes" : "Vote";

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      color: Colors.white,
      shape: widget.item.upNext
          ? RoundedRectangleBorder(
              side: BorderSide(
                color: Theme.of(context).accentColor,
                width: 1.5,
              ),
              borderRadius: BorderRadius.circular(5),
            )
          : RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
      elevation: 3.0,
      child: Padding(
        padding: EdgeInsets.only(top: 2, bottom: 2, right: 2, left: 0),
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.max,
            children: [
              Container(
                margin: EdgeInsets.only(right: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Transform.scale(
                      scale: 0.7,
                      child: IconButton(
                        icon: Icon(
                          Icons.thumb_up,
                          color: hasVoted ? Theme.of(context).accentColor : Colors.grey,
                        ),
                        onPressed: hasVoted
                            ? () async {
                                await FirebaseFirestore.instance.runTransaction(
                                  (transaction) async {
                                    final freshSnapshot = await transaction.get(widget.item.reference);
                                    final fresh = Item.fromSnapshot(freshSnapshot);

                                    if (fresh.voters.contains(user.uid)) {
                                      fresh.voters.remove(user.uid);
                                    }

                                    transaction.update(widget.item.reference, {
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
                                      final freshSnapshot = await transaction.get(widget.item.reference);
                                      final fresh = Item.fromSnapshot(freshSnapshot);

                                      if (!fresh.voters.contains(user.uid)) {
                                        fresh.voters.add(user.uid);
                                      }

                                      transaction.update(widget.item.reference, {
                                        'votes': fresh.votes + 1,
                                        'voters': fresh.voters,
                                      });
                                    },
                                  );
                                }
                              },
                      ),
                    ),
                    Text(
                      widget.item.votes.toString(),
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
              ),
              Flexible(
                child: Container(
                  padding: new EdgeInsets.only(right: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        widget.item.name,
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
            ],
          ),
          trailing: Container(
            child: ClipOval(
              child: Container(
                color: widget.item.type.color,
                child: IconButton(
                  iconSize: 30,
                  tooltip: widget.item.type.descriptor,
                  hoverColor: Colors.transparent,
                  focusColor: Colors.transparent,
                  onPressed: () {
                    widget.filterBy(widget.item.type);
                  },
                  icon: Icon(
                    widget.item.type.icon,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          onTap: () {
            Navigator.of(context).push(MaterialPageRoute(builder: (context) {
              return RequestDetail(item: widget.item, reference: widget.item.reference);
            }));
          },
          onLongPress: !admin
              ? () {
                  Navigator.of(context).push(MaterialPageRoute(builder: (context) {
                    return Login();
                  }));
                }
              : () => FirebaseFirestore.instance.runTransaction(
                    (transaction) async {
                      final freshSnapshot = await transaction.get(widget.item.reference);
                      final fresh = Item.fromSnapshot(freshSnapshot);

                      transaction.update(widget.item.reference, {'up_next': !fresh.upNext});
                    },
                  ),
        ),
      ),
    );
  }
}
