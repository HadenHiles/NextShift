import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Login.dart';
import 'models/RequestType.dart';

class Request extends StatefulWidget {
  Request({Key key, this.type}) : super(key: key);

  final RequestType type;

  @override
  _RequestState createState() => _RequestState();
}

class _RequestState extends State<Request> {
  final user = FirebaseAuth.instance.currentUser;

  final _formKey = GlobalKey<FormState>();
  // Create a text controller and use it to retrieve the current value of the TextField.
  final nameFieldController = TextEditingController();
  final descriptionFieldController = TextEditingController();

  RequestType requestType;
  List<RequestType> types = [
    RequestType(name: "Feature Request"),
    RequestType(name: "Content Request"),
    RequestType(name: "Idea"),
    RequestType(name: "Bug"),
  ];

  @override
  void initState() {
    if (user == null) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) {
            return Login();
          },
        ),
      );
    }

    if (requestType == null) {
      setState(() {
        requestType = widget.type;
      });
    }

    super.initState();
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
      body: Container(
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
                      children: <Widget>[
                        // Padding(
                        //   padding: EdgeInsets.only(bottom: 25),
                        //   child: FormBuilderDropdown(
                        //     initialValue: widget.category,
                        //     readOnly: true,
                        //     attribute: "category",
                        //     // decoration: InputDecoration(labelText: "Category"),
                        //     // initialValue: 'Other',
                        //     hint: Text('Select Category'),
                        //     validators: [
                        //       FormBuilderValidators.required(),
                        //     ],
                        //     items: ['Feature Request', 'Content Request', 'Idea', 'Bug']
                        //         .map((category) => DropdownMenuItem(
                        //               value: category,
                        //               child: Text("$category"),
                        //             ))
                        //         .toList(),
                        //     onChanged: (value) {
                        //       category = value;
                        //     },
                        //   ),
                        // ),
                        TextFormField(
                          validator: (String value) {
                            if (value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                          controller: nameFieldController,
                          decoration: InputDecoration(labelText: "Title"),
                        ),
                        Padding(
                          padding: EdgeInsets.only(top: 25),
                          child: TextFormField(
                            validator: (String value) {
                              if (value.isEmpty) {
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
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.check),
        backgroundColor: Theme.of(context).accentColor,
        onPressed: () {
          if (_formKey.currentState.validate()) {
            FirebaseFirestore.instance.collection('items').add({
              'name': nameFieldController.text.toString(),
              'votes': 1,
              'voters': [user.uid],
              'description': descriptionFieldController.text.toString(),
              'type': requestType.name,
              'created_by': user.uid ?? null,
              'up_next': false
            });

            Navigator.of(context).pop();
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