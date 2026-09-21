import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:nextshift/RequestDetail.dart';
import 'Login.dart';
import 'models/Item.dart';
import 'models/RequestType.dart';

class Request extends StatefulWidget {
  const Request({super.key, required this.type, this.initialPlatform, this.editItem});

  final RequestType type;
  final String? initialPlatform;
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
    platform = widget.editItem?.platform ?? widget.initialPlatform ?? "The Pond";

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
        title: Text(widget.editItem == null ? 'SUBMIT A NEXT SHIFT' : 'EDIT NEXT SHIFT'),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 700),
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('1  CHOOSE THE PRODUCT', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text('Which How To Hockey product is this for?'),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    initialValue: platform,
                    decoration: const InputDecoration(labelText: 'Product'),
                    items: platforms
                        .map((entry) => DropdownMenuItem<String>(
                              value: entry['value'] as String,
                              child: Text(entry['display'] as String),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => platform = value);
                    },
                  ),
                  const SizedBox(height: 30),
                  Text('2  TELL US WHAT YOU NEED', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 6),
                  const Text('Choose the description that fits best. You can change it later.'),
                  const SizedBox(height: 14),
                  ...types.map(
                    (type) => RadioListTile<String>(
                      value: type.name,
                      groupValue: requestType.name,
                      onChanged: (value) => setState(() => requestType = RequestType(name: value!)),
                      title: Text(type.userLabel),
                      subtitle: Text(type.helpText),
                      secondary: Icon(type.icon, color: type.color),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text('3  DESCRIBE YOUR NEXT SHIFT', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 14),
                  TextFormField(
                    validator: (String? value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a title';
                      }
                      return null;
                    },
                    controller: nameFieldController,
                    decoration: const InputDecoration(
                      labelText: 'Short title',
                      hintText: 'Example: Video on stopping with both feet',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
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
                      decoration: const InputDecoration(
                        labelText: 'More details',
                        hintText: 'What would help, and why?',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ),
                  const SizedBox(height: 90),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        tooltip: widget.editItem == null ? 'Submit next shift' : 'Save changes',
        icon: const Icon(Icons.check),
        label: Text(widget.editItem == null ? 'SUBMIT NEXT SHIFT' : 'SAVE CHANGES'),
        backgroundColor: Theme.of(context).colorScheme.secondary,
        onPressed: widget.editItem == null
            ? () {
                final currentUser = user;
                if (currentUser != null && (_formKey.currentState?.validate() ?? false)) {
                  FirebaseFirestore.instance.collection('items').add({
                    'name': nameFieldController.text.trim(),
                    'votes': 1,
                    'voters': [currentUser.uid],
                    'downvoters': [],
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
