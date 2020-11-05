import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'models/Comment.dart';

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
  List<CommentItem> fetchedComments = [];

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
      return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('comments').doc(requestId).collection("comments").snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container(alignment: FractionalOffset.center, child: CircularProgressIndicator());

            this.didFetchComments = true;

            return _buildCommentList(context, snapshot.data.docs);
          });
    } else {
      // for optimistic updating
      return ListView(children: this.fetchedComments);
    }
  }

  Widget _buildCommentList(BuildContext context, List<DocumentSnapshot> snapshot) {
    List<CommentItem> comments = snapshot
        .map((data) => CommentItem(
              comment: Comment.fromSnapshot(data),
            ))
        .toList();

    return ListView(
      children: comments,
    );
  }

  addComment(String comment) {
    _commentController.clear();
    FirebaseFirestore.instance.collection("comments").doc(requestId).collection("comments").add({"displayName": currentUser.displayName, "comment": comment, "timestamp": Timestamp.now(), "avatarUrl": currentUser.photoURL, "userId": currentUser.uid});

    // add comment to the current listview for an optimistic update
    setState(() {
      fetchedComments = List.from(fetchedComments)..add(CommentItem(comment: Comment(displayName: currentUser.displayName, comment: comment, timestamp: Timestamp.now(), avatarUrl: currentUser.photoURL, userId: currentUser.uid)));
    });
  }
}

class CommentItem extends StatelessWidget {
  const CommentItem({Key key, this.comment}) : super(key: key);

  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment.comment),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(comment.avatarUrl),
          ),
        ),
        Divider(),
      ],
    );
  }
}
