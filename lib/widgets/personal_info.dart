import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_navigation/screens/screen1.dart';
class PersonalInfo extends StatefulWidget {

  const PersonalInfo({Key? key}) : super(key: key);

  @override
  State<PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<PersonalInfo> {
  DateTime currentDate = DateTime.now();
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: currentDate,
        firstDate: DateTime(1900),
        lastDate: DateTime(DateTime.now().year));
    if (pickedDate != null && pickedDate != currentDate)
      setState(() {
        currentDate = pickedDate;
      });
  }
  @override

  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final firstNameController = TextEditingController();
    final lastNameController = TextEditingController();
    firstNameController.text = "Scott";
    lastNameController.text = "Farestrand";
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
            Text(currentDate.toString()),
            ElevatedButton(
                onPressed: () => _selectDate(context),
                child: Text("Select Date")),
            ElevatedButton(
              onPressed: () {
                print("pressed");

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Creating User")),
                );
                // try{
                //   FirebaseAuth.instance.createUserWithEmailAndPassword(
                //       email: emailController.text.trim(),
                //       password: passwordController.text.trim()).
                //   then((value) {
                //     ScaffoldMessenger.of(context).showSnackBar(
                //       const SnackBar(content: Text("Created")),
                //     );
                //     print(value);
                //     print(value.user);
                //     print(value.credential);
                //   });
                // }catch(err){
                //   sendVerificationEmail();
                //   print(err);
                //
                // }
                // }
              },
              child: const Text('Login'),
            ),
            ElevatedButton(onPressed: () {
            }, child: Text("Register")),
            ElevatedButton(onPressed: (){
              FirebaseAuth.instance.signOut();
            }, child: Text("Log out"))
          ],
        ),
      ),

    );
  }
}