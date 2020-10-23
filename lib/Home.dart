import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
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

  final _formKey = GlobalKey<FormState>();
  // Create a text controller and use it to retrieve the current value of the TextField.
  final nameFieldController = TextEditingController();
  final descriptionFieldController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    nameFieldController.dispose();
    super.dispose();
  }

  void _newItem() {
    String category;

    if (user == null) {
      setState(() {
        needsAuthenticated = true;
      });
    } else {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return Scaffold(
              appBar: AppBar(title: Text('Submit your request')),
              body: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.max,
                children: [
                  SizedBox(
                    width: 400,
                    child: Column(
                      children: [
                        FormBuilder(
                          key: _formKey,
                          initialValue: {
                            'name': '',
                            'accept_terms': false,
                          },
                          child: Column(
                            children: <Widget>[
                              TextFormField(
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Please enter a title';
                                  }
                                  return null;
                                },
                                controller: nameFieldController,
                                decoration: InputDecoration(labelText: "Title"),
                              ),
                              TextFormField(
                                validator: (value) {
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
                              FormBuilderDropdown(
                                attribute: "category",
                                decoration: InputDecoration(labelText: "Category"),
                                // initialValue: 'Other',
                                hint: Text('Select Category'),
                                validators: [
                                  FormBuilderValidators.required(),
                                ],
                                items: ['Feature Request', 'Content Request', 'Bug Fix', 'Other']
                                    .map((category) => DropdownMenuItem(
                                          value: category,
                                          child: Text("$category"),
                                        ))
                                    .toList(),
                                onChanged: (value) {
                                  category = value;
                                },
                              ),
                            ],
                          ),
                        ),
                        RaisedButton(
                          child: Text("Add"),
                          onPressed: () {
                            if (user == null) {
                              setState(() {
                                needsAuthenticated = true;
                              });
                            }
                            FirebaseFirestore.instance.collection('items').add({
                              'name': nameFieldController.text.toString(),
                              'votes': 1,
                              'voters': [user.uid],
                              'description': descriptionFieldController.text.toString(),
                              'category': category,
                              'created_by': user.uid ?? null,
                            }).catchError((e) {
                              setState(() {
                                needsAuthenticated = true;
                              });
                            });

                            nameFieldController.value = TextEditingValue(text: '');

                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
  }
}
