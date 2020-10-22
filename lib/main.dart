import 'package:flutter/material.dart';
import 'Login.dart';

void main() {
  runApp(NextShift());
}

class NextShift extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Login(),
    );
  }
}
