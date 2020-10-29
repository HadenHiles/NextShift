import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:nextshift/NewRequest.dart';
import 'widgets/ListItem.dart';
import 'widgets/Heading.dart';
import 'Login.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  // Static variables
  final user = FirebaseAuth.instance.currentUser;

  // State variables
  bool speedDialOpen = false;

  @override
  Widget build(BuildContext context) {
    return _buildMobile();
  }

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: Color.fromRGBO(240, 240, 240, 1),
      appBar: AppBar(
        centerTitle: true,
        title: Heading(
          text: "Next Shift",
          size: 30,
        ),
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                _buildItems(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildSpeedDial(),
    );
  }

  // Build the list of items
  Widget _buildItems(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('items').orderBy('votes', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();

          return _buildItemList(context, snapshot.data.docs);
        });
  }

  Widget _buildItemList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return Expanded(
      child: ListView(
        padding: EdgeInsets.only(top: 20.0),
        children: snapshot.map((data) => ListItem(data: data)).toList(),
      ),
    );
  }

  SpeedDial _buildSpeedDial() {
    return SpeedDial(
      backgroundColor: !speedDialOpen ? Theme.of(context).accentColor : Theme.of(context).primaryColor,
      child: !speedDialOpen
          ? Icon(Icons.add)
          : Icon(
              Icons.arrow_drop_down,
              size: 34,
            ),
      onOpen: () {
        setState(() {
          speedDialOpen = !speedDialOpen;
        });
      },
      onClose: () {
        setState(() {
          speedDialOpen = !speedDialOpen;
        });
      },
      visible: true,
      curve: Curves.easeInOut,
      children: [
        SpeedDialChild(
          child: Icon(Icons.bug_report, color: Colors.white),
          backgroundColor: Theme.of(context).accentColor,
          foregroundColor: Theme.of(context).accentColor,
          onTap: () {
            newRequest("Bug");
          },
          label: 'Report a bug',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            fontSize: 18,
          ),
          labelBackgroundColor: Colors.white,
        ),
        SpeedDialChild(
          child: Icon(Icons.lightbulb, color: Colors.white),
          backgroundColor: Colors.orange,
          foregroundColor: Colors.orange,
          onTap: () {
            newRequest("Idea");
          },
          label: 'I have an idea',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            fontSize: 18,
          ),
          labelBackgroundColor: Colors.white,
        ),
        SpeedDialChild(
          child: Icon(Icons.movie, color: Colors.white),
          backgroundColor: Colors.green,
          foregroundColor: Colors.green,
          onTap: () {
            newRequest("Content Request");
          },
          label: 'I would like to learn more about..',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            fontSize: 18,
          ),
          labelBackgroundColor: Colors.white,
        ),
        SpeedDialChild(
          child: Icon(Icons.list_alt, color: Colors.white),
          backgroundColor: Colors.blue,
          foregroundColor: Colors.blue,
          onTap: () {
            newRequest("Feature Request");
          },
          label: 'I would like to be able to..',
          labelStyle: TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.black54,
            fontSize: 18,
          ),
          labelBackgroundColor: Colors.white,
        ),
      ],
    );
  }

  void newRequest(String category) {
    if (user == null) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return Login();
          },
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return NewRequest(
              category: category,
            );
          },
        ),
      );
    }
  }
}
