import 'package:flutter/material.dart';
import 'Home.dart';

void main() {
  runApp(NextShift());
}

class NextShift extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: Color.fromRGBO(26, 26, 26, 1),
        accentColor: Color.fromRGBO(204, 51, 51, 1),
        backgroundColor: Colors.white,
      ),
      home: Home(),
    );
  }
}
