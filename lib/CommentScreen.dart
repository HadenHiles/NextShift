import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/globals/Roles.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'models/Comment.dart';

final bool admin = Roles.admins.contains(FirebaseAuth.instance.currentUser?.uid);

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
  CommentItem editComment;

  final _formKey = GlobalKey<FormState>();
  TextEditingController _commentController = TextEditingController();

  _CommentScreenState({this.requestId, this.requestOwner});

  @override
  Widget build(BuildContext context) {
    // Set the edit comment text if the user is editing a comment
    if (editComment != null) {
      _commentController.text = editComment.comment.comment;
    }

    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          buildComments(),
          Divider(),
          currentUser == null
              ? Container()
              : Form(
                  key: _formKey,
                  child: editComment != null
                      ? ListTile(
                          title: TextFormField(
                            controller: _commentController,
                            decoration: InputDecoration(labelText: 'Update comment...'),
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Please write a comment";
                              }

                              return null;
                            },
                          ),
                          trailing: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              OutlineButton(
                                onPressed: () {
                                  updateComment(editComment, _commentController.text);
                                },
                                borderSide: BorderSide.none,
                                child: Icon(
                                  Icons.check,
                                  color: Colors.green,
                                ),
                              ),
                              OutlineButton(
                                onPressed: () {
                                  deleteComment(editComment.comment);
                                },
                                borderSide: BorderSide.none,
                                child: Icon(
                                  Icons.delete,
                                  color: Theme.of(context).accentColor,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListTile(
                          title: TextFormField(
                            controller: _commentController,
                            decoration: InputDecoration(labelText: 'Write a comment...'),
                            onFieldSubmitted: addComment,
                            validator: (value) {
                              if (value.isEmpty) {
                                return "Please write a comment";
                              }

                              return null;
                            },
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
                ),
        ],
      ),
    );
  }

  Widget buildComments() {
    if (this.didFetchComments == false) {
      return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('comments').doc(requestId).collection("comments").orderBy('timestamp', descending: false).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container(alignment: FractionalOffset.center, child: CircularProgressIndicator());

            this.didFetchComments = true;
            this.fetchedComments = snapshot.data.docs
                .map((data) => CommentItem(
                      comment: Comment.fromSnapshot(data),
                      editCb: triggerEditComment,
                    ))
                .toList();

            return _buildCommentList(context, snapshot.data.docs);
          });
    } else {
      // for optimistic updating
      return Expanded(
        child: ListView(children: this.fetchedComments),
      );
    }
  }

  Widget _buildCommentList(BuildContext context, List<DocumentSnapshot> snapshot) {
    List<CommentItem> comments = snapshot
        .map((data) => CommentItem(
              comment: Comment.fromSnapshot(data),
              editCb: triggerEditComment,
            ))
        .toList();

    return Expanded(
      child: ListView(
        children: comments,
      ),
    );
  }

  addComment(String comment) {
    if (_formKey.currentState.validate()) {
      _commentController.clear();
      FirebaseFirestore.instance.collection("comments").doc(requestId).collection("comments").add({"displayName": currentUser.displayName, "comment": comment, "timestamp": Timestamp.now(), "avatarUrl": currentUser.photoURL, "userId": currentUser.uid});

      // add comment to the current listview for an optimistic update
      setState(() {
        fetchedComments = List.from(fetchedComments)
          ..add(
            CommentItem(
              comment: Comment(displayName: currentUser.displayName, comment: comment, timestamp: Timestamp.now(), avatarUrl: currentUser.photoURL, userId: currentUser.uid),
              editCb: triggerEditComment,
            ),
          );

        didFetchComments = false;
      });
    }
  }

  triggerEditComment(CommentItem comment) {
    setState(() {
      editComment = comment;
      didFetchComments = false;
    });
  }

  updateComment(CommentItem commentItem, String newComment) {
    if (_formKey.currentState.validate()) {
      _commentController.clear();
      FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(commentItem.comment.reference, {'comment': newComment.trim()});
      });

      triggerEditComment(null);
    }
  }

  deleteComment(Comment comment) {
    _commentController.clear();
    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.delete(comment.reference);
    });

    triggerEditComment(null);
  }
}

class CommentItem extends StatelessWidget {
  const CommentItem({Key key, this.comment, this.editCb}) : super(key: key);

  final Comment comment;
  final Function editCb;

  @override
  Widget build(BuildContext context) {
    bool isOwner = comment.userId == FirebaseAuth.instance.currentUser?.uid;
    if (!isOwner && admin) {
      isOwner = admin;
    }

    return Column(
      children: <Widget>[
        ListTile(
          title: Text(comment.comment),
          leading: CircleAvatar(
            backgroundImage: NetworkImage(comment.avatarUrl),
          ),
          trailing: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                timeago.format(
                  comment.timestamp.toDate(),
                  locale: 'en_short',
                ),
              ),
              isOwner
                  ? Container(
                      margin: EdgeInsets.only(left: 15),
                      child: InkWell(
                        child: Icon(Icons.edit),
                        onTap: () {
                          editCb(this);
                        },
                      ),
                    )
                  : Container(),
            ],
          ),
        ),
        Divider(),
      ],
    );
  }
}
