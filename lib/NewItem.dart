import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';

class NewItem extends StatefulWidget {
  NewItem({Key key}) : super(key: key);

  @override
  _NewItemState createState() => _NewItemState();
}

class _NewItemState extends State<NewItem> {
  final user = FirebaseAuth.instance.currentUser;

  final _formKey = GlobalKey<FormState>();
  // Create a text controller and use it to retrieve the current value of the TextField.
  final nameFieldController = TextEditingController();
  final descriptionFieldController = TextEditingController();

  String category;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Submit your request')),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: EdgeInsets.all(20),
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
                      Padding(
                        padding: EdgeInsets.only(top: 25),
                        child: TextFormField(
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
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 25),
                        child: FormBuilderDropdown(
                          attribute: "category",
                          // decoration: InputDecoration(labelText: "Category"),
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
        backgroundColor: Colors.blue,
        onPressed: () {
          FirebaseFirestore.instance.collection('items').add({
            'name': nameFieldController.text.toString(),
            'votes': 1,
            'voters': [user.uid],
            'description': descriptionFieldController.text.toString(),
            'category': category,
            'created_by': user.uid ?? null,
          });

          Navigator.of(context).pop();
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
