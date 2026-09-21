import 'package:flutter/material.dart';

class Heading extends StatelessWidget {
  const Heading({
    super.key,
    required this.text,
    required this.size,
  });

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Text(
        text.toUpperCase(),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: size,
          color: Color.fromRGBO(170, 170, 170, 1),
          fontFamily: 'Teko',
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
