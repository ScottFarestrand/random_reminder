import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
class Register extends StatelessWidget {
  final Function loginCallback;
  const Register({Key? key, required this.loginCallback()}) : super(key: key);

  @override
  // CollectionReference users = FirebaseFirestore.instance.collection('/Users');

  Widget build(BuildContext context) {

    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final confirmpasswordController = TextEditingController();
    const emailInUse = "Email address is already in use";
    emailController.text = "ScottFarestrand@gmail.com";
    passwordController.text = "Jlj#980507";
    confirmpasswordController.text = passwordController.text;
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      // drawer: NavDrawer(),
      appBar: AppBar(
        title: Text("Random Reminder/Register "),
      ),
      body: Form(
        key: formKey,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(15, 8, 15, 8),
          child: Column(
            children: <Widget>[
              SizedBox(height: 20),

              TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: "Email Address",
                    labelStyle: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  style: TextStyle(fontSize: 20),
                  validator: (value) {
                    if (RegExp(
                        r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
                        .hasMatch(value.toString())) {
                      return null;
                    }
                    return 'Please enter a valid email address';
                  }
              ),
              TextFormField(
                  controller: passwordController,
                  keyboardType: TextInputType.text,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  style: TextStyle(fontSize: 20),
                  validator: (value) {
                    bool numFound = RegExp(r".*[0-9].*").hasMatch(
                        value.toString());
                    bool letterFound = RegExp(r".*[A-Za-z].*").hasMatch(
                        value.toString());
                    bool spaceFound = RegExp(r".*[ ].*").hasMatch(
                        value.toString());
                    bool specCharFound = RegExp(
                        r".*[\!\~\`\@\#\$\%\^\&\*\(\-\_\+\=\:\;\,\<\.\>\/\?].*")
                        .hasMatch(value.toString());
                    if (numFound == false || letterFound == false ||
                        specCharFound == false) {
                      return "Password must contain at least one number, one letter, and one special character";
                    }
                    if (spaceFound) {
                      return "Password cannot have a space";
                    }
                    int v = value!.length;
                    if (v < 10) {
                      return "password should be at least 10 characters";
                    }
                    return null;
                  }
              ),
              TextFormField(
                  controller: passwordController,
                  keyboardType: TextInputType.text,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Password",
                    labelStyle: TextStyle(fontStyle: FontStyle.italic),
                  ),
                  style: TextStyle(fontSize: 20),
                  validator: (value) {

                    if (value != passwordController.text) {
                      return "Passwords do not match";
                    }
                    return null;
                  }
              ),
              ElevatedButton(
                onPressed: () {
                  // Validate returns true if the form is valid, or false otherwise.
                  if (formKey.currentState!.validate()) {
                  } else {
                  }

                  if (formKey.currentState!.validate()) {
                    // If the form is valid, display a snackbar. In the real world,
                    // you'd often call a server or save the information in a database.
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text("Creating User")),
                    // );
                    try{
                      FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim()).
                      then((value) {
                        addUser(value.user!.uid);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Created")),
                        );
                        loginCallback();
                      }).catchError((err){;
                        if (err.code == "email-already-in-use") {
                          ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text(emailInUse)),
                          );
                        }
                      });
                    }
                    catch(err){
                      // sendVerificationEmail();
                      print(err);
                    }
                  }
                },
                child: const Text('Register'),
              ),
              ElevatedButton(onPressed: () {
                print("register Pressed");
                loginCallback();
              }, child: Text("Cancel")),
            ],
          ),
        ),

      ),

    );
  }
  Future<void> addUser(String UserID) {
    CollectionReference users = FirebaseFirestore.instance.collection('/Users');
    return users
          .add({
        'userId': UserID,
        'full_name': 'Scott', // John Doe
        'company': "XXX", // Stokes and Sons
        'age': 42 // 42
      }).then((value) => print("User Added"))
          .catchError((error) => print("Failed to add user: $error"));
  }
}