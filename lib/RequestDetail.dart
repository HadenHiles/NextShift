import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/CommentScreen.dart';
import 'package:nextshift/widgets/PlatformBadge.dart';
import 'package:nextshift/services/voting.dart';
import 'Home.dart';
import 'Login.dart';
import 'Request.dart';
import 'globals/Roles.dart';
import 'models/Item.dart';

final bool admin = Roles.admins.contains(FirebaseAuth.instance.currentUser?.uid);

class RequestDetail extends StatefulWidget {
  const RequestDetail({super.key, required this.item});

  final Item item;

  @override
  _RequestDetailState createState() => _RequestDetailState();
}

class _RequestDetailState extends State<RequestDetail> {
  // Static variables
  final user = FirebaseAuth.instance.currentUser;

  // State variables
  late Item item;
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
    bool hasVoted = user != null ? item.voters.contains(user!.uid) : false;
    bool hasDownvoted = user != null ? item.downvoters.contains(user!.uid) : false;

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
                      Item item = Item.fromSnapshot(snapshot.data!);
                      hasVoted = user != null ? item.voters.contains(user!.uid) : false;
                      hasDownvoted = user != null ? item.downvoters.contains(user!.uid) : false;

                      return Card(
                        margin: EdgeInsets.all(10),
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                          side: const BorderSide(color: Color(0xFF292E35)),
                        ),
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
                                      tooltip: hasVoted ? 'Remove upvote' : 'Upvote',
                                      icon: const Icon(Icons.keyboard_arrow_up, size: 32),
                                      color: hasVoted ? const Color(0xFF63D69A) : const Color(0xFFC7CED8),
                                      onPressed: () => _vote(item, VoteDirection.up),
                                    ),
                                    Text(
                                      item.votes.toString(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'SCORE',
                                      style: TextStyle(
                                        color: Color(0xFFB4BDC9),
                                        fontWeight: FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: hasDownvoted ? 'Remove downvote' : 'Downvote',
                                      icon: const Icon(Icons.keyboard_arrow_down, size: 32),
                                      color: hasDownvoted ? const Color(0xFFFF7373) : const Color(0xFFC7CED8),
                                      onPressed: () => _vote(item, VoteDirection.down),
                                    ),
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
                                            color: Colors.white,
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
                                margin: EdgeInsets.only(left: 12),
                                child: PlatformBadge(platform: item.platform),
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

  Future<void> _vote(Item item, VoteDirection direction) async {
    if (user == null) {
      await Navigator.of(context).push(MaterialPageRoute(builder: (_) => const Login()));
      return;
    }
    await setVote(item.reference, user!.uid, direction);
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
