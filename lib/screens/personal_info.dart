import 'package:flutter/material.dart';
import '../widgets/personal_info.dart';
class PersonalInfoScreen extends StatelessWidget {
  static const id = "personal_info";
  const PersonalInfoScreen({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return PersonalInfo();
  }
}
