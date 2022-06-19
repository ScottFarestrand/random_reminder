import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
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
    final birthDateController = TextEditingController();
    String tempDate;
    int _seconds;
    int _nanoseconds;
    // DateTime _birthDate;
    FirebaseFirestore.instance.collection('Users').
    doc(FirebaseAuth.instance.currentUser!.uid).
    get().then((snapshot) => {
      tempDate = snapshot['BirthDate'].toString(),
      _seconds = int.parse(tempDate.substring(18, 28)),
      _nanoseconds = int.parse(tempDate.substring(42, tempDate.lastIndexOf(')'))),
      birthDate = Timestamp(_seconds, _nanoseconds).toDate(),
      firstNameController.text = snapshot['FirstName'],
      lastNameController.text = snapshot['LastName'],
    });


    birthDateController.text = dateFormat.format(birthDate);
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
            TextFormField(
              decoration: InputDecoration(
                labelText: "Birth Date",
                labelStyle: TextStyle(fontStyle: FontStyle.italic),
              ),
              style: TextStyle(fontSize: 20),
              controller: birthDateController,
              keyboardType: TextInputType.none,
            ),

            ElevatedButton(
                onPressed: () => _selectDate(context, dateController),
                child: Text("Select Date")),
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
  // readUser(TextEditingController ) {
  //
  //   FirebaseFirestore.instance.collection('Users').
  //   doc(FirebaseAuth.instance.currentUser!.uid).
  //   get().then((snapshot) => {
  //   });
  // }
  // Stream<List<RRUser>> readUser() {
  //   return FirebaseFirestore.instance.
  //       .collection('Users')
  //       .where('Id', isEqualTo: FirebaseAuth.instance.currentUser!.uid)
  //       .snapshots()
  //       .map((qSnap) => qSnap.docs
  //       .map((doc) => RRUser.fromJson(doc.data()))
  //       .toList());
  // }
  Future addRecord (String firstName, String lastName, DateTime birthDate  ) async {
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