import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/CommentScreen.dart';
import 'Home.dart';
import 'Login.dart';
import 'Request.dart';
import 'globals/Roles.dart';
import 'models/Item.dart';

final bool admin = Roles.admins.contains(FirebaseAuth.instance.currentUser?.uid);

class RequestDetail extends StatefulWidget {
  RequestDetail({Key key, this.item}) : super(key: key);

  final Item item;

  @override
  _RequestDetailState createState() => _RequestDetailState();
}

class _RequestDetailState extends State<RequestDetail> {
  // Static variables
  final user = FirebaseAuth.instance.currentUser;

  // State variables
  Item item;
  bool isOwner = false;
  bool isAdmin = false;

  @override
  void initState() {
    isAdmin = admin;
    item = widget.item;

    // Get a fresh version of the request (item)
    freshItem(widget.item).then((freshItem) {
      setState(() {
        item = freshItem;
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    isOwner = user?.uid == item.createdBy;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text("${item.type.descriptor}"),
            Container(
              padding: EdgeInsets.only(left: 10, top: 4),
              child: Icon(item.type.icon),
            ),
          ],
        ),
        backgroundColor: item.type.color,
        actions: [
          Row(
            children: [
              isAdmin
                  ? InkWell(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        child: Icon(Icons.edit),
                      ),
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return Request(
                                type: item.type,
                                editItem: item,
                              );
                            },
                          ),
                        );
                      },
                    )
                  : Container(),
              (isOwner && !widget.item.upNext) || isAdmin
                  ? InkWell(
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                        child: Icon(Icons.delete),
                      ),
                      onTap: () {
                        _confirmDialog("Are you sure you want to delete this request?", "This cannot be undone", () {
                          Navigator.of(context).pop();
                        }, () {
                          Navigator.of(context).pop();
                          deleteRequest(item);
                        });
                      },
                    )
                  : Container(),
            ],
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
    bool hasVoted = user != null ? item.voters.contains(user.uid) : false;
    String votesTitle = item.votes > 1 ? "Votes" : "Vote";

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
                    stream: FirebaseFirestore.instance.collection('items').doc(item.reference.id).snapshots(),
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
                            crossAxisAlignment: CrossAxisAlignment.center,
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
                              Expanded(
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
                              Container(
                                margin: EdgeInsets.only(left: 20),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    widget.item.platform == "The Pond"
                                        ? Transform.scale(
                                            scale: 0.75,
                                            child: Tooltip(
                                              message: "The Pond",
                                              child: ClipOval(
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 30,
                                                  ),
                                                  child: Image(
                                                    height: 30,
                                                    image: AssetImage(
                                                      'assets/images/logos/thepond_rgb.png',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Transform.scale(
                                            scale: 0.75,
                                            child: Tooltip(
                                              message: "How To Hockey",
                                              child: ClipOval(
                                                child: Container(
                                                  padding: EdgeInsets.symmetric(
                                                    vertical: 30,
                                                  ),
                                                  child: Image(
                                                    height: 35,
                                                    image: AssetImage(
                                                      'assets/images/logos/hth_logo.png',
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                  ],
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
      requestId: item.reference.id,
      requestOwner: item.createdBy,
    );
  }

  Future<void> _confirmDialog(String title, String message, Function cancel, Function proceed) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(message),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                cancel();
              },
            ),
            TextButton(
              child: Text('Continue'),
              onPressed: () {
                proceed();
              },
            ),
          ],
        );
      },
    );
  }

  Future<Item> freshItem(Item staleItem) async {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      var freshSnapshot = await transaction.get(staleItem.reference);
      var fresh = Item.fromSnapshot(freshSnapshot);

      return fresh;
    });
  }

  Future<void> deleteRequest(Item item) {
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.delete(item.reference);

      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
        return Home();
      }));
    });
  }
}
