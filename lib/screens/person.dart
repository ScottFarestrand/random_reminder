import 'package:flutter/material.dart';

class Person extends StatefulWidget {
  static const id = "Person";
  final String? LastName;
  const Person({Key? key, this.LastName}) : super(key: key);

  @override
  State<Person> createState() => _PersonState();
}

class _PersonState extends State<Person> {
  @override
  Widget build(BuildContext context) {
    if (widget.LastName != "") {
      return Scaffold(body: Container(child: Text(widget.LastName!),),);

    }
    return Scaffold(body: Container(child: Text("New Person"),),);
  }
}
