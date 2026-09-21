import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/RequestDetail.dart';
import 'Login.dart';
import 'models/Item.dart';
import 'models/RequestType.dart';

class Request extends StatefulWidget {
  const Request({super.key, required this.type, this.editItem});

  final RequestType type;
  final Item? editItem;

  @override
  _RequestState createState() => _RequestState();
}

class _RequestState extends State<Request> {
  final user = FirebaseAuth.instance.currentUser;

  final _formKey = GlobalKey<FormState>();
  // Create a text controller and use it to retrieve the current value of the TextField.
  final nameFieldController = TextEditingController();
  final descriptionFieldController = TextEditingController();

  late RequestType requestType;
  late String platform;
  List<RequestType> types = [
    RequestType(name: "Feature Request"),
    RequestType(name: "Content Request"),
    RequestType(name: "Idea"),
    RequestType(name: "Bug"),
  ];

  List<dynamic> platforms = [
    {
      "display": "The Pond",
      "value": "The Pond",
    },
    {
      "display": "How To Hockey",
      "value": "How To Hockey",
    },
    {
      "display": "10,000 Shots App",
      "value": "10,000 Shots App",
    },
  ];

  @override
  void initState() {
    super.initState();
    requestType = widget.editItem?.type ?? widget.type;
    platform = widget.editItem?.platform ?? "The Pond";

    if (widget.editItem != null) {
      nameFieldController.text = widget.editItem!.name;
      descriptionFieldController.text = widget.editItem!.description;
    }

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (context) => Login()),
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${requestType.descriptor}"),
        backgroundColor: requestType.color,
        actions: [
          PopupMenuButton(
            elevation: 3.2,
            initialValue: requestType,
            tooltip: 'Change the type',
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 2),
              child: Icon(requestType.icon),
            ),
            onSelected: (type) {
              setState(() {
                requestType = type;
              });
            },
            itemBuilder: (BuildContext context) {
              return types.map((RequestType choice) {
                return PopupMenuItem(
                  value: choice,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(choice.descriptor),
                      Icon(
                        choice.icon,
                        color: choice.color,
                      ),
                    ],
                  ),
                );
              }).toList();
            },
          )
        ],
      ),
      body: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: MediaQuery.of(context).size.width,
            constraints: BoxConstraints(maxWidth: 700),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  padding: EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Form(
                        key: _formKey,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        child: Column(
                          children: [
                            TextFormField(
                              validator: (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a title';
                                }
                                return null;
                              },
                              controller: nameFieldController,
                              decoration: InputDecoration(labelText: "Title"),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 25),
                              child: DropdownButtonFormField<String>(
                                initialValue: platform,
                                decoration: InputDecoration(labelText: 'Platform'),
                                items: platforms
                                    .map((entry) => DropdownMenuItem<String>(
                                          value: entry['value'] as String,
                                          child: Text(entry['display'] as String),
                                        ))
                                    .toList(),
                                onSaved: (value) {
                                  if (value != null) platform = value;
                                },
                                onChanged: (value) {
                                  if (value != null) setState(() => platform = value);
                                },
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.only(top: 25),
                              child: TextFormField(
                                validator: (String? value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter a description';
                                  }
                                  return null;
                                },
                                controller: descriptionFieldController,
                                minLines: 3,
                                maxLines: 20,
                                decoration: InputDecoration(labelText: "Description"),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: widget.editItem == null
            ? () {
                final currentUser = user;
                if (currentUser != null && (_formKey.currentState?.validate() ?? false)) {
                  FirebaseFirestore.instance.collection('items').add({
                    'name': nameFieldController.text.trim(),
                    'votes': 1,
                    'voters': [currentUser.uid],
                    'description': descriptionFieldController.text.trim(),
                    'platform': platform,
                    'type': requestType.name,
                    'created_by': currentUser.uid,
                    'up_next': false,
                    'complete': false,
                  });
                  Navigator.of(context).pop();
                }
              }
            : () {
                final editItem = widget.editItem!;
                if (_formKey.currentState?.validate() ?? false) {
                  FirebaseFirestore.instance.runTransaction((transaction) async {
                    transaction.update(editItem.reference, {
                      'name': nameFieldController.text.trim(),
                      'description': descriptionFieldController.text.trim(),
                      'platform': platform,
                      'type': requestType.name,
                    });

                    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) {
                      return RequestDetail(item: editItem);
                    }));
                  });
                }
              },
      ),
    );
  }

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameFieldController.dispose();
    descriptionFieldController.dispose();
    super.dispose();
  }
}
