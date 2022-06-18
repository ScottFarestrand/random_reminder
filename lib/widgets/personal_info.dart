import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_navigation/screens/screen1.dart';
class PersonalInfo extends StatefulWidget {

  const PersonalInfo({Key? key}) : super(key: key);

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  final dateFormat = new DateFormat('MMM d, y');
  DateTime birthDate = DateTime.now();

  Future<void> _selectDate(BuildContext context, TextEditingController selectedDate) async {
    final dateFormat = new DateFormat('MMM d, y');
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: birthDate,
        firstDate: DateTime(DateTime.now().year - 125),
        lastDate: DateTime(DateTime.now().year + 1),);
    if (pickedDate != null && pickedDate != birthDate)
      setState(() {
        birthDate = pickedDate;
        selectedDate.text = dateFormat.format(birthDate);
      });
  }
  @override

  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    final dateController = TextEditingController();
    firstNameController.text = "Scott";
    lastNameController.text = "Farestrand";
    dateController.text = dateFormat.format(birthDate);
    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
        child: Column(
          children: <Widget>[
            SizedBox(height: 20),

            TextFormField(
                controller: firstNameController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  labelText: "First Name",
                  labelStyle: TextStyle(fontStyle: FontStyle.italic),
                ),
                style: TextStyle(fontSize: 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter First Name";
                  }
                  return null;
                }
            ),
            TextFormField(
              controller: lastNameController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: "Last Name",
                labelStyle: TextStyle(fontStyle: FontStyle.italic),
              ),
              style: TextStyle(fontSize: 20),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter Last Name";
                  }
                  return null;
                }
            ),
            Text(dateController.text),
            ElevatedButton(
                onPressed: () => _selectDate(context, dateController),
                child: Text("Select Date")),
            // ElevatedButton(
            //   onPressed: () {
            //     print("pressed");
            //
            //     ScaffoldMessenger.of(context).showSnackBar(
            //       const SnackBar(content: Text("Creating User")),
            //     );
            //   },
            //   child: const Text('Login'),
            // ),
            // ElevatedButton(onPressed: () {
            // }, child: Text("Register")),
            ElevatedButton(onPressed: (){
              FirebaseAuth.instance.signOut();
            }, child: Text("Log out")),
            ElevatedButton(onPressed: (){
            addRecord(firstNameController.text, lastNameController.text, birthDate);
            }, child: Text("Write a dang record")),
          ],
        ),
      ),
    );
  }
  Future addRecord (String firstName, String lastName, DateTime birthDate  ) async {
    print("Writing");
    final myID = FirebaseAuth.instance.currentUser!.uid;
      final docUser = FirebaseFirestore.instance.collection('Users').doc(
          myID);
    final json = {
      'FirstName': firstName,
      'LastName': lastName,
      'BirthDate': birthDate,
    };
    await docUser.set(json);
  }
}