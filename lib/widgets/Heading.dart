import 'package:flutter/material.dart';

class Heading extends StatelessWidget {
  Heading({
    Key key,
    this.text,
    this.size,
  }) : super(key: key);

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(top: 25),
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          color: Color.fromRGBO(75, 75, 75, 1),
          fontFamily: 'Teko',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
