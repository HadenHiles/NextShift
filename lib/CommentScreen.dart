import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import "dart:async";

class CommentScreen extends StatefulWidget {
  CommentScreen({this.requestId, this.requestOwner});

  final String requestId;
  final String requestOwner;

  @override
  _CommentScreenState createState() => _CommentScreenState(requestId: this.requestId, requestOwner: this.requestOwner);
}

class _CommentScreenState extends State<CommentScreen> {
  final String requestId;
  final String requestOwner;
  final User currentUser = FirebaseAuth.instance.currentUser;

  bool didFetchComments = false;
  List<Comment> fetchedComments = [];

  final TextEditingController _commentController = TextEditingController();

  _CommentScreenState({this.requestId, this.requestOwner});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Expanded(
            child: buildComments(),
          ),
          Divider(),
          currentUser == null
              ? Container()
              : ListTile(
                  title: TextFormField(
                    controller: _commentController,
                    decoration: InputDecoration(labelText: 'Write a comment...'),
                    onFieldSubmitted: addComment,
                  ),
                  trailing: OutlineButton(
                    onPressed: () {
                      addComment(_commentController.text);
                    },
                    borderSide: BorderSide.none,
                    child: Icon(
                      Icons.send,
                      color: Theme.of(context).accentColor,
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget buildComments() {
    if (this.didFetchComments == false) {
      return FutureBuilder<List<Comment>>(
          future: getComments(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container(alignment: FractionalOffset.center, child: CircularProgressIndicator());

            this.didFetchComments = true;
            this.fetchedComments = snapshot.data;
            return ListView(
              children: snapshot.data,
            );
          });
    } else {
      // for optimistic updating
      return ListView(children: this.fetchedComments);
    }
  }

  Future<List<Comment>> getComments() async {
    List<Comment> comments = [];

    QuerySnapshot data = await FirebaseFirestore.instance.collection("comments").doc(requestId).collection("comments").get();
    data.docs.forEach((DocumentSnapshot doc) {
      comments.add(Comment.fromDocument(doc));
    });
    return comments;
  }

  addComment(String comment) {
    _commentController.clear();
    FirebaseFirestore.instance.collection("comments").doc(requestId).collection("comments").add({"display_name": currentUser.displayName, "comment": comment, "timestamp": Timestamp.now(), "avatarUrl": currentUser.photoURL, "userId": currentUser.uid});

    // add comment to the current listview for an optimistic update
    setState(() {
      fetchedComments = List.from(fetchedComments)..add(Comment(displayName: currentUser.displayName, comment: comment, timestamp: Timestamp.now(), avatarUrl: currentUser.photoURL, userId: currentUser.uid));
    });
  }
}

class Comment extends StatelessWidget {
  final String displayName;
  final String userId;
  final String avatarUrl;
  final String comment;
  final Timestamp timestamp;

  Comment({this.displayName, this.userId, this.avatarUrl, this.comment, this.timestamp});

  factory Comment.fromDocument(DocumentSnapshot document) {
    return Comment(
      displayName: document['username'],
      userId: document['userId'],
      comment: document["comment"],
      timestamp: document["timestamp"],
      avatarUrl: document["avatarUrl"],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(avatarUrl),
          ),
        ),
        Divider(),
      ],
    );
  }
}
