import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'models/Item.dart';

class Home extends StatefulWidget {
  Home({Key key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildBody(context),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: _newItem,
      ),
    );
  }

  // Build the list of items
  Widget _buildBody(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('item').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return LinearProgressIndicator();

          return _buildList(context, snapshot.data.docs);
        });
  }

  Widget _buildList(BuildContext context, List<DocumentSnapshot> snapshot) {
    return ListView(
      padding: EdgeInsets.only(top: 20.0),
      children: snapshot.map((data) => _buildListItem(context, data)).toList(),
    );
  }

  Widget _buildListItem(BuildContext context, DocumentSnapshot data) {
    final item = Item.fromSnapshot(data);

    return Padding(
      key: ValueKey(item.name),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(5.0),
        ),
        child: ListTile(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(item.name),
              Text(item.votes.toString()),
            ],
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.arrow_upward,
              color: Colors.grey,
            ),
            onPressed: () => FirebaseFirestore.instance.runTransaction(
              (transaction) async {
                final freshSnapshot = await transaction.get(item.reference);
                final fresh = Item.fromSnapshot(freshSnapshot);

                transaction.update(item.reference, {'votes': fresh.votes + 1});
              },
            ),
          ),
        ),
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
    String category = null;

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
                          FirebaseFirestore.instance.collection('item').add({
                            'name': nameFieldController.text.toString(),
                            'votes': 0,
                            'description': descriptionFieldController.text.toString(),
                            'category': category,
                            'user_id': FirebaseAuth.instance.currentUser.uid,
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
