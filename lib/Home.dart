import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:nextshift/NewItem.dart';
import 'widgets/ListItem.dart';
import 'widgets/Heading.dart';
import 'Login.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  // Static variables
  final user = FirebaseAuth.instance.currentUser;

  // State variables
  bool needsAuthenticated = false;

  @override
  Widget build(BuildContext context) {
    if (needsAuthenticated) {
      return Login();
    } else {
      return Scaffold(
        body: Column(
          children: [
            Heading(
              text: "Next Shift",
              size: 40,
            ),
            _buildBody(context),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          child: Icon(Icons.add),
          onPressed: _newItem,
        ),
      );
    }
  }

  // Build the list of items
  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').orderBy('votes', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();

          return _buildList(context, snapshot.data.docs);
        });
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.only(top: 20.0),
        children: snapshot.map((data) => ListItem(data: data)).toList(),
      ),
    );
  }

  void _newItem() {
    if (user == null) {
      setState(() {
        needsAuthenticated = true;
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return NewItem();
          },
        ),
      );
    }
  }
}
