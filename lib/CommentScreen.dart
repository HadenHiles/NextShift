import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/globals/Roles.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'models/Comment.dart';

final bool admin = Roles.admins.contains(FirebaseAuth.instance.currentUser?.uid);

class CommentScreen extends StatefulWidget {
  const CommentScreen({super.key, required this.requestId, required this.requestOwner});

  final String requestId;
  final String requestOwner;

  @override
  _CommentScreenState createState() => _CommentScreenState();
}

class _CommentScreenState extends State<CommentScreen> {
  User? get currentUser => FirebaseAuth.instance.currentUser;

  bool didFetchComments = false;
  List<CommentItem> fetchedComments = [];
  CommentItem? editComment;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _commentController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // Set the edit comment text if the user is editing a comment
    if (editComment != null) {
      _commentController.text = editComment!.comment.comment;
    }

    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(maxWidth: 700),
            padding: EdgeInsets.all(15),
            child: Container(
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
                                    keyboardType: TextInputType.multiline,
                                    minLines: 2,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      labelText: 'Update comment...',
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
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
                                      IconButton(
                                        onPressed: () {
                                          updateComment(editComment!, _commentController.text);
                                        },
                                        icon: Icon(
                                          Icons.check,
                                          color: Colors.green,
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          deleteComment(editComment!.comment);
                                        },
                                        icon: Icon(
                                          Icons.delete,
                                          color: Theme.of(context).colorScheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListTile(
                                  title: TextFormField(
                                    controller: _commentController,
                                    keyboardType: TextInputType.multiline,
                                    minLines: 2,
                                    maxLines: 4,
                                    decoration: InputDecoration(
                                      labelText: 'Write a comment...',
                                    ),
                                    onFieldSubmitted: addComment,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return "Please write a comment";
                                      }

                                      return null;
                                    },
                                  ),
                                  trailing: IconButton(
                                    onPressed: () {
                                      addComment(_commentController.text);
                                    },
                                    icon: Icon(
                                      Icons.send,
                                      color: Theme.of(context).colorScheme.secondary,
                                    ),
                                  ),
                                ),
                        ),
                ],
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
          stream: FirebaseFirestore.instance.collection('comments').doc(widget.requestId).collection("comments").orderBy('timestamp', descending: false).snapshots(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return Container(alignment: FractionalOffset.center, child: CircularProgressIndicator());

            this.didFetchComments = true;
            this.fetchedComments = snapshot.data!.docs
                .map((data) => CommentItem(
                      comment: Comment.fromSnapshot(data),
                      editCb: triggerEditComment,
                    ))
                .toList();

            return _buildCommentList(context, snapshot.data!.docs);
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
    final user = currentUser;
    if (user != null && (_formKey.currentState?.validate() ?? false)) {
      _commentController.clear();
      FirebaseFirestore.instance.collection("comments").doc(widget.requestId).collection("comments").add({"displayName": user.displayName ?? 'Anonymous', "comment": comment, "timestamp": Timestamp.now(), "avatarUrl": user.photoURL, "userId": user.uid});

      // add comment to the current listview for an optimistic update
      setState(() {
        fetchedComments = List.from(fetchedComments)
          ..add(
            CommentItem(
              comment: Comment(displayName: user.displayName ?? 'Anonymous', comment: comment, timestamp: Timestamp.now(), avatarUrl: user.photoURL, userId: user.uid),
              editCb: triggerEditComment,
            ),
          );

        didFetchComments = false;
      });
    }
  }

  void triggerEditComment(CommentItem? comment) {
    setState(() {
      editComment = comment;
      didFetchComments = false;
    });
  }

  updateComment(CommentItem commentItem, String newComment) {
    if (_formKey.currentState?.validate() ?? false) {
      _commentController.clear();
      FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.update(commentItem.comment.reference!, {'comment': newComment.trim()});
      });

      triggerEditComment(null);
    }
  }

  deleteComment(Comment comment) {
    _commentController.clear();
    FirebaseFirestore.instance.runTransaction((transaction) async {
      transaction.delete(comment.reference!);
    });

    triggerEditComment(null);
  }
}

class CommentItem extends StatelessWidget {
  const CommentItem({super.key, required this.comment, required this.editCb});

  final Comment comment;
  final void Function(CommentItem?) editCb;

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
            backgroundImage: comment.avatarUrl == null ? null : NetworkImage(comment.avatarUrl!),
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
