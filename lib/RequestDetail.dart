import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/CommentScreen.dart';

import 'Login.dart';
import 'models/Item.dart';

class RequestDetail extends StatefulWidget {
  RequestDetail({Key key, this.item, this.reference}) : super(key: key);

  final Item item;
  final DocumentReference reference;

  @override
  _RequestDetailState createState() => _RequestDetailState();
}

class _RequestDetailState extends State<RequestDetail> {
  // Static variables
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.item.type.descriptor}"),
        backgroundColor: widget.item.type.color,
        actions: [
          InkWell(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Icon(widget.item.type.icon),
            ),
          ),
        ],
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          _buildDetails(),
          _buildComments(),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    bool hasVoted = user != null ? widget.item.voters.contains(user.uid) : false;
    String votesTitle = widget.item.votes > 1 ? "Votes" : "Vote";

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.max,
      children: [
        Container(
          width: MediaQuery.of(context).size.width,
          constraints: BoxConstraints(maxWidth: 700),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                child: StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance.collection('items').doc(widget.reference.id).snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return LinearProgressIndicator();
                      Item item = Item.fromSnapshot(snapshot.data);
                      hasVoted = user != null ? item.voters.contains(user.uid) : false;
                      votesTitle = item.votes > 1 ? "Votes" : "Vote";

                      return Card(
                        margin: EdgeInsets.all(10),
                        color: Colors.white,
                        elevation: 3,
                        child: Container(
                          padding: EdgeInsets.all(15),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(right: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    IconButton(
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

                                              setState(() {
                                                hasVoted = false;
                                              });
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

                                                setState(() {
                                                  hasVoted = true;
                                                });
                                              }
                                            },
                                    ),
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
                              ),
                              Flexible(
                                child: Container(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        margin: EdgeInsets.only(bottom: 25),
                                        child: Text(
                                          item.name,
                                          textAlign: TextAlign.left,
                                          style: TextStyle(
                                            fontSize: 20,
                                            color: Colors.black87,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        item.description,
                                        textAlign: TextAlign.left,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildComments() {
    return CommentScreen(
      requestId: widget.item.reference.id,
      requestOwner: widget.item.createdBy,
    );
  }
}
