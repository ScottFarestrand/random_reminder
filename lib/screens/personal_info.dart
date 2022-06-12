import 'package:flutter/material.dart';
class PersonalInfo extends StatelessWidget {
  static const id = "personal_info";
  const PersonalInfo({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Column(children: [Text("personal info")],),);
  }
}
