import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
// class PersonalInfo extends StatelessWidget {
  class PersonalInfo extends StatefulWidget {
  const PersonalInfo({Key? key}) : super(key: key);
  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  final dateFormat = new DateFormat('MMM d, y');
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final cellPhoneNumberController = TextEditingController();
  final dateController = TextEditingController();
  final birthDateController = TextEditingController();
  // MaskTextInputFormatter formatter();
  var maskFormatter = new MaskTextInputFormatter(mask: '###.###.####', filter: { "#": RegExp(r'[0-9]') });
  DateTime birthDate = DateTime.now();
  String firstName = "";
  String lastName = "";
  String cellPhoneNumber = "";
  bool textReminders = false;
  bool emailReminders = false;
  bool cellPhoneValidated = false;
  bool _saved = true;
  String origCellPhone = "";
  // bool _cellValidated = false;



  Future<void> _selectDate(BuildContext context, TextEditingController selectedDate) async {
    final dateFormat = new DateFormat.yMd();

    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: birthDate,
        firstDate: DateTime(DateTime.now().year - 125),
        lastDate: DateTime(DateTime.now().year + 1),);
    if (pickedDate != null && pickedDate != birthDate)
      setState(() {
        birthDate = pickedDate;
        _saved = false;
        print(birthDate);
        birthDateController.text = dateFormat.format(birthDate);
      });
  }

  @override

  Widget build(BuildContext context) {
    print("Building PErsonal");
    final formKey = GlobalKey<FormState>();


    String tempDate;
    int _seconds;
    int _nanoseconds;
    // DateTime _birthDate;

    if (_saved ) {
      FirebaseFirestore.instance.collection('Users').
      doc(FirebaseAuth.instance.currentUser!.uid).
      get().then((snapshot) =>
      {
        // print(snapshot["SendEmailReminders"]).
        tempDate = snapshot['BirthDate'].toString(),
        _seconds = int.parse(tempDate.substring(18, 28)),
        _nanoseconds =
            int.parse(tempDate.substring(42, tempDate.lastIndexOf(')'))),
        birthDate = Timestamp(_seconds, _nanoseconds).toDate(),
        firstNameController.text = snapshot['FirstName'],
        lastNameController.text = snapshot['LastName'],
        emailReminders = snapshot["SendEmailReminders"],
        textReminders = snapshot["SendTextReminders"],
        cellPhoneNumberController.text = snapshot["CellPhone"],
        origCellPhone = snapshot["CellPhone"],
        cellPhoneValidated = snapshot["CellPhoneValidated"],
        // _cellValidated = cellPhoneValidated,
        _saved = true,
      });
    }
    birthDateController.text = dateFormat.format(birthDate);
    

    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
        child: Column(
          children: <Widget>[
            SizedBox(height: 20),

            buildTextFormField(firstNameController, "First Name"),
            buildTextFormField(lastNameController, "Last Name"),
            buildDateTextFormField(context, birthDateController, "Birth Date"),
            buildPhoneTextFormField(cellPhoneNumberController, "Cell Phone Number"),
            buildSelectionRow(textReminders, "Send Text Reminders"),
            Row(children: [
              Text('Send Email Reminders', style: TextStyle(fontSize: 20), ),
              Switch(
                  value: emailReminders,
                  onChanged: (bool? value) { // This is where we update the state when the checkbox is tapped
                    setState(() {
                      _saved = false;  
                      emailReminders = value!;
                    });
                  })
            ],),
            ElevatedButton(onPressed: (){
              FirebaseAuth.instance.signOut();
            }, child: Text("Log out")),
            ElevatedButton(onPressed: (){



             // DateTime zz = DateFormat('y, MMMM, d', 'en_US').parse(birthDateController.text);
             //  print(zz);
            addRecord(firstNameController.text, lastNameController.text, birthDate);
            }, child: Text("Save")),
            Visibility(
              visible: ( !cellPhoneValidated && _saved),
              child: ElevatedButton(
                onPressed: (){},
                child: Text("Validate Cell Number"),),
            ),
          ],
        ),
      ),
    );
  }

  Row buildSelectionRow( bool myValue,String promptText) {
    return Row(children: [
            Text(promptText, style: TextStyle(fontSize: 20),),
            Switch(
                value: myValue,
                onChanged: (bool? value) { // This is where we update the state when the checkbox is tappe

                  setState(() {
                    _saved = false;
                    myValue = value!;
                  });
                })
          ],);
  }

  TextFormField buildPhoneTextFormField(TextEditingController phoneTextEditingController, String promptText) {
    return TextFormField(
            onChanged: (text){
              setState(() {
                _saved = false;
              });

            },
            inputFormatters: [maskFormatter],
            controller: phoneTextEditingController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: promptText,
              labelStyle: TextStyle(fontStyle: FontStyle.italic),
            ),
            style: TextStyle(fontSize: 20),
          );
  }

  TextFormField buildDateTextFormField(BuildContext context, TextEditingController dateController, String promptText) {
    return TextFormField(
            onTap: () {_selectDate(context, dateController);},
            onChanged: (text){
              setState(() {

                _saved = false;
              });

            },
            decoration: InputDecoration(
              labelText: promptText,
              labelStyle: TextStyle(fontStyle: FontStyle.italic),
            ),
            style: TextStyle(fontSize: 20),
            controller: dateController,
            keyboardType: TextInputType.none,
          );
  }

  TextFormField buildTextFormField(TextEditingController textController, String inputtext) {
    return TextFormField(
            onChanged: (text){
              setState(() {
                _saved = false;
              });

            },
              controller: textController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(
                labelText: inputtext,
                labelStyle: TextStyle(fontStyle: FontStyle.italic),
              ),
              style: TextStyle(fontSize: 20),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return "Please enter $inputtext";
                }
                return null;
              }
          );
  }
  //
  addRecord (String firstName, String lastName, DateTime birthDate  )  {
    print(birthDate);
    print("ZZZ");
    print(dateController.text);





    // final testDate = DateFormat('MMMM d, y', 'en_US').parse(dateController.text);
    // print(testDate);
    final myID = FirebaseAuth.instance.currentUser!.uid;
    final docUser = FirebaseFirestore.instance.collection('Users').doc(
        myID);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saving User")),
    );
    if (cellPhoneNumberController.text != origCellPhone) {
      cellPhoneValidated  = false;
    }
    if (cellPhoneNumberController.text != origCellPhone) {
      cellPhoneValidated = false;
    }
    // FirebaseAuth.instance.signOut();
    final json = {
      'FirstName': firstNameController.text,
      'LastName': lastNameController.text,
      'BirthDate': birthDate,
      'SendTextReminders': textReminders,
      'SendEmailReminders': emailReminders,
      'CellPhone': cellPhoneNumberController.text,
      'CellPhoneValidated': cellPhoneValidated,
    };
    print(json);
    try {

       docUser.set(json)
          .then((stuff) {

      })
      .catchError((e) {
        print("Error Caught");
        print(e.code);
        print(e.message);

         if (e.code == "permission-denied") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text("You Do not have necessary permission",
                style: TextStyle(backgroundColor: Colors.red),),
          ),
        );}
      });
    } on FirebaseException catch (err){
      print(err.toString());
    } on IOException catch(err) {
      print(err.toString());
    }



    setState((){
      _saved = true;
    });

  }
  // Future addRecord (String firstName, String lastName, DateTime birthDate  ) async {
  //   final myID = FirebaseAuth.instance.currentUser!.uid;
  //   final docUser = FirebaseFirestore.instance.collection('Users').doc(
  //         myID);
  //   print("Saving");
  //   ScaffoldMessenger.of(context).showSnackBar(
  //     const SnackBar(content: Text("Saving User")),
  //   );
  //   if (cellPhoneNumberController.text != origCellPhone) {
  //     cellPhoneValidated  = false;
  //   }
  //   print(textReminders);
  //   if (cellPhoneNumberController.text != origCellPhone) {
  //     cellPhoneValidated = false;
  //   }
  //   // FirebaseAuth.instance.signOut();
  //   final json = {
  //     'FirstName': firstNameController.text,
  //     'LastName': lastNameController.text,
  //     'BirthDate': birthDate,
  //     'SendTextReminders': textReminders,
  //     'SendEmailReminders': emailReminders,
  //     'CellPhone': cellPhoneNumberController.text,
  //     'CellPhoneValidated': cellPhoneValidated,
  //    };
  //   try {
  //     await docUser.set(json)
  //         .then((stuff) {
  //       print("saved");
  //     }).catchError((Err) {
  //       print("Error Caught");
  //       print(Err.toString());
  //     });
  //   } on FirebaseException catch (err){
  //     print("firebase Error Caught");
  //   } on IOException catch(err) {
  //     print("IO Exception Caught");
  //   }
  //
  //
  //
  //   setState((){
  //     _saved = true;
  //   });
  //
  // }
}