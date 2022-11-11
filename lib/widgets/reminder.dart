import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../methods/text_form_Field.dart';
// import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:random_reminder/constants/globals.dart';
// class PersonalInfo extends StatelessWidget {
  class ReminderDetails extends StatefulWidget {
    static const id = "Reminder";
  const ReminderDetails({Key? key}) : super(key: key);

  @override
  State<ReminderDetails> createState() => _ReminderDetailsState();
}

class _ReminderDetailsState extends State<ReminderDetails> {

  final dateFormat = new DateFormat('MMM d, y');
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final birthDateController = TextEditingController();
  final randomRemindersController = TextEditingController();
  final relationshipTypeController = TextEditingController();
  final anniversaryTypeController = TextEditingController();
  final anniversaryDateController = TextEditingController();


  // MaskTextInputFormatter formatter();

  DateTime birthDate = DateTime.now();
  DateTime anniversaryDate = DateTime.now();
  String firstName = "";
  String lastName = "";
  String randomeReminders = "0";
  String relationshipType = "";
  String anniversaryType = "";
  bool celebrateBirthday = true;
  bool celebrateAnniversary = true;
  bool mydata = true;
  bool _saved = true;
  // List<String> anniversaryTypes = ["Wedding", "Employement", "Adoption", "First Date"];
  String selectedAnniversaryType = "";
  // List<String> relationshipTypes = ['Wife', 'Husband', 'Daughter', 'Son'];
  String selectedRelationshipType = "";





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
        // _cellValidated = cellPhoneValidated,
        _saved = true,
      });
    }


    birthDateController.text = dateFormat.format(birthDate);
    

    return Form(
      key: formKey,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),

              buildTextFormField(firstNameController, "First Name"),
              buildTextFormField(lastNameController, "Last Name"),
              buildDropdownButtonRow("Type of Relationship", selectedRelationshipType, gRelationshipTypes),
              // buildSwitchRow("Celebate Birthday", celebrateBirthday),
              Row(children: [
                Text("Celebrate Birthday", style: TextStyle(fontSize: 20),),
                Switch(
                    value: celebrateBirthday,
                    onChanged: (bool? value) { // This is where we update the state when the checkbox is tapped
                      print(value);

                      setState(() {
                        print("Switched");
                        print(value);
                        celebrateBirthday = value!;
                      });
                    })
              ],),
              buildDate_Text_Form_Field(context, celebrateBirthday, birthDateController, "Birth Date"),
              buildSwitchRow("Celebrate Anniversary test", mydata),
              Row(children: [
                Text("Celebrate Anniversary", style: TextStyle(fontSize: 20),),
                Switch(
                    value: celebrateAnniversary,
                    onChanged: (bool? value) { // This is where we update the state when the checkbox is tapped
                      print(value);

                      setState(() {
                        celebrateAnniversary = value!;
                      });
                    })
              ],),
              buildDate_Text_Form_Field(context, celebrateAnniversary, anniversaryDateController, "Anniversary Date"),
              Visibility(
                visible: celebrateAnniversary,
                child: Row(
                  children: [
                    Text("Type of Anniversary   "),
                    DropdownButton<String>(
                      value: selectedAnniversaryType.isEmpty ? null : selectedAnniversaryType,
                      onChanged: (_value) {  // update the selectedItem value
                        setState(() {
                          selectedAnniversaryType = _value!;
                        });
                      },
                      items: gAnniversaryTypes
                          .map<DropdownMenuItem<String>>((String _value) => DropdownMenuItem<String>(
                          value: _value, // add this property an pass the _value to it
                          child: Text(_value,)
                      )).toList(),
                    ),
                  ],
                ),
                //
                // child:  DropdownButton<String>(
                //   value: selectedAnniversaryType,
                //   items: ["X", "Y"].
                //     map((item) => DropdownMenuItem<String>(
                //       child: Text(item), value: item,)).toList(),
                //   onChanged: (item)  => setState(() {
                //     selectedAnniversaryType = item;
                //   }),
                // ),
              ),

              ElevatedButton(onPressed: (){
                FirebaseAuth.instance.signOut();
              }, child: Text("Log out")),
              ElevatedButton(onPressed: (){
              addRecord(firstNameController.text, lastNameController.text, birthDate);
              }, child: Text("Save")),

            ],
          ),
        ),
      ),
    );
  }

  Visibility buildDate_Text_Form_Field(BuildContext context, bool ib_visible, TextEditingController itec, String is_Lbl) {
    return Visibility(
              visible: ib_visible,
              child: TextFormField(
                onTap: () {_selectDate(context, itec);},
                decoration: InputDecoration(
                  labelText: is_Lbl ,
                  labelStyle: TextStyle(fontStyle: FontStyle.italic),
                ),
                style: TextStyle(fontSize: 20),
                controller: itec,
                keyboardType: TextInputType.none,
              ),
            );
  }

  Row buildDropdownButtonRow(String is_lbl, String is_selectedValue, List<String> is_List ) {
    return Row(
              children: [
                Text(is_lbl),
                DropdownButton<String>(
                  value: (is_selectedValue == "" )? null : is_selectedValue,
                  onChanged: (_value) {  // update the selectedItem value
                    setState(() {
                      is_selectedValue = _value!;
                    });
                  },
                  items: is_List
                      .map<DropdownMenuItem<String>>((String _value) => DropdownMenuItem<String>(
                      value: _value, // add this property an pass the _value to it
                      child: Text(_value,)
                  )).toList(),
                ),
              ],
            );
  }
  Row buildSwitchRow(String lbl,  i_Value) {
    print("Switch Row");
    print(i_Value);
    return Row(children: [
      Text(lbl , style: TextStyle(fontSize: 20),),
      Switch(
          value: i_Value,
          onChanged: (bool? value) { // This is where we update the state when the checkbox is tapped

            setState(() {
              print("Switched");
              print(value);
              print(mydata);
              i_Value = value!;
              print(mydata);
            });
          })
    ],);
  }
  // TextFormField buildTextFormField(TextEditingController tec, String lbl) {
  //   return TextFormField(
  //               controller: tec,
  //               keyboardType: TextInputType.text,
  //               decoration: InputDecoration(
  //                 labelText: lbl,
  //                 labelStyle: TextStyle(fontStyle: FontStyle.italic),
  //               ),
  //               style: TextStyle(fontSize: 20),
  //               validator: (value) {
  //                 if (value == null || value.isEmpty) {
  //                   return "Please enter /$lbl";
  //                 }
  //                 return null;
  //               }
  //           );
  // }
  //
  addRecord (String firstName, String lastName, DateTime birthDate  )  {
    final myID = FirebaseAuth.instance.currentUser!.uid;
    final docUser = FirebaseFirestore.instance.collection('Users').doc(
        myID);
    print("Saving");
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Saving User")),
    );


    // FirebaseAuth.instance.signOut();
    final json = {
      'FirstName': firstNameController.text,
      'LastName': lastNameController.text,
      'BirthDate': birthDate,
    };
    try {
      print("Trying");
       docUser.set(json)
          .then((stuff) {
        print("saved");
      })
      .catchError((e) {
        print("Error Caught");
        print(e.code);
        print(e.message);

        // print(Err.toString());
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