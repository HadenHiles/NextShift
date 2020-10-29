import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'Login.dart';

class NewRequest extends StatefulWidget {
  NewRequest({Key key, this.category}) : super(key: key);

  final String category;

  @override
  _NewRequestState createState() => _NewRequestState();
}

class _NewRequestState extends State<NewRequest> {
  final user = FirebaseAuth.instance.currentUser;

  final _formKey = GlobalKey<FormState>();
  // Create a text controller and use it to retrieve the current value of the TextField.
  final nameFieldController = TextEditingController();
  final descriptionFieldController = TextEditingController();

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
    super.initState();
  }

  String category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Submit your ${widget.category}")),
      body: Column(
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
                  autovalidateMode: AutovalidateMode.always,
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
              'category': widget.category,
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
