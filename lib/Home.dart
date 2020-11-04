import 'dart:js_util';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:nextshift/Request.dart';
import 'package:nextshift/models/RequestType.dart';
import 'models/Item.dart';
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
  bool initialized = false;
  RequestType typeFilter;

  @override
  void initState() {
    setState(() {
      initialized = true;
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return _buildMobile();
  }

  Widget _buildMobile() {
    return Scaffold(
      backgroundColor: Color.fromRGBO(240, 240, 240, 1),
      appBar: AppBar(
        centerTitle: true,
        leading: Container(
          padding: EdgeInsets.all(5),
          child: Image(
            height: 40,
            image: AssetImage(
              'assets/images/logos/hth_logo_red.png',
            ),
          ),
        ),
        title: Heading(
          text: "Next Shift",
          size: 30,
        ),
        actions: [
          Container(
            padding: EdgeInsets.all(10),
            child: Image(
              height: 30,
              image: AssetImage(
                'assets/images/logos/thepond_white_rgb.png',
              ),
            ),
          ),
        ],
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            margin: EdgeInsets.only(top: 10),
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(maxWidth: 700),
            child: Column(
              children: [
                typeFilter != null
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text("${typeFilter.descriptor}"),
                              Container(
                                margin: EdgeInsets.only(left: 15),
                                child: Icon(
                                  Icons.filter_list,
                                  color: Colors.black45,
                                ),
                              ),
                            ],
                          ),
                          ClipOval(
                            child: Container(
                              color: Colors.transparent,
                              child: IconButton(
                                tooltip: "Remove filter",
                                hoverColor: Colors.transparent,
                                focusColor: Colors.transparent,
                                onPressed: () {
                                  setState(() {
                                    typeFilter = null;
                                  });
                                },
                                icon: Icon(
                                  Icons.close,
                                  color: typeFilter.color,
                                  size: 15,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Container(),
                _buildItems(context)
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: initialized ? _buildSpeedDial() : null,
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
    List<ListItem> items = snapshot
        .map((data) => ListItem(
              item: Item.fromSnapshot(data),
              filterBy: filterType,
            ))
        .toList();
    if (typeFilter != null) {
      items = items.where((element) => element.item.type.name == typeFilter.name).toList();
    }

    return Expanded(
      child: ListView(
        padding: EdgeInsets.only(top: 20.0),
        children: items,
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

  void newRequest(String type) {
    if (user == null) {
      Future.delayed(Duration.zero, () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (BuildContext context) {
              return Login();
            },
          ),
        );
      });
    } else {
      RequestType requestType = RequestType(name: type);

      if (type == "Bug") {
        requestType.color = Theme.of(context).accentColor;
        requestType.descriptor = "Report a bug";
        requestType.icon = Icons.bug_report;
      } else if (type == "Idea") {
        requestType.color = Colors.orange;
        requestType.descriptor = "I have an idea";
        requestType.icon = Icons.lightbulb;
      } else if (type == "Content Request") {
        requestType.color = Colors.green;
        requestType.descriptor = "I would like to learn about..";
        requestType.icon = Icons.movie;
      } else if (type == "Feature Request") {
        requestType.color = Colors.blue;
        requestType.descriptor = "I would like to be able to..";
        requestType.icon = Icons.list_alt;
      }

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return Request(type: requestType);
          },
        ),
      );
    }
  }

  void filterType(RequestType type) {
    setState(() {
      typeFilter = type;
    });
  }

  bool includeType(RequestType type) {
    return (type == null || type.name == typeFilter.name);
  }
}
