import 'package:flutter/material.dart';

class RequestType {
  String name;
  String descriptor;
  Color color;
  IconData icon;

  RequestType({this.name}) {
    if (name == "Bug") {
      this.color = Color.fromRGBO(204, 51, 51, 1);
      this.descriptor = "Report a bug";
      this.icon = Icons.bug_report;
    } else if (name == "Idea") {
      this.color = Colors.orange;
      this.descriptor = "I have an idea";
      this.icon = Icons.lightbulb;
    } else if (name == "Content Request") {
      this.color = Colors.green;
      this.descriptor = "I would like to learn about..";
      this.icon = Icons.movie;
    } else if (name == "Feature Request") {
      this.color = Colors.blue;
      this.descriptor = "I would like to be able to..";
      this.icon = Icons.list_alt;
    }
  }
}
