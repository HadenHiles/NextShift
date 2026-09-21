import 'package:flutter/material.dart';

class RequestType {
  final String name;
  late String descriptor;
  late Color color;
  late IconData icon;

  String get userLabel {
    switch (name) {
      case 'Content Request':
        return 'A video or hockey lesson';
      case 'Feature Request':
        return 'An app or website improvement';
      case 'Bug':
        return 'Something is broken';
      default:
        return 'Another suggestion';
    }
  }

  String get helpText {
    switch (name) {
      case 'Content Request':
        return 'A skill, drill, coaching topic, or video you want to see.';
      case 'Feature Request':
        return 'A new tool or a change to how a product works.';
      case 'Bug':
        return 'A button, page, video, or feature that does not work correctly.';
      default:
        return 'Anything that does not fit the choices above.';
    }
  }

  RequestType({required this.name}) {
    if (name == "Bug") {
      color = const Color.fromRGBO(204, 51, 51, 1);
      descriptor = "Something is broken";
      icon = Icons.build_circle_outlined;
    } else if (name == "Idea") {
      color = Colors.orange;
      descriptor = "Another suggestion";
      icon = Icons.lightbulb;
    } else if (name == "Content Request") {
      color = Colors.green;
      descriptor = "Video or hockey lesson";
      icon = Icons.movie;
    } else if (name == "Feature Request") {
      color = Colors.blue;
      descriptor = "App or website improvement";
      icon = Icons.devices;
    }
  }
}
