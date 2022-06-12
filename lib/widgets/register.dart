import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter_navigation/screens/screen1.dart';
class Register extends StatelessWidget {
  final Function loginCallback;
  const Register({Key? key, required this.loginCallback()}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
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
        key: _formKey,
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
                  print("pressed");
                  // Validate returns true if the form is valid, or false otherwise.
                  if (_formKey.currentState!.validate()) {
                    print("valid");
                  } else {
                    print("Not Valid");
                  }

                  if (_formKey.currentState!.validate()) {
                    // If the form is valid, display a snackbar. In the real world,
                    // you'd often call a server or save the information in a database.
                    // ScaffoldMessenger.of(context).showSnackBar(
                    //   const SnackBar(content: Text("Creating User")),
                    // );
                    print("Creating usre");
                    try{
                      FirebaseAuth.instance.createUserWithEmailAndPassword(
                          email: emailController.text.trim(),
                          password: passwordController.text.trim()).
                      then((value) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Created")),
                        );
                        print("succcess");
                        print(value);
                        print(value.user);
                        print(value.credential);
                        loginCallback();
                      }).catchError((err){
                        print("here is ERR");
                        print(err.code);
                        if (err.code == "email-already-in-use") {

                        ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text(emailInUse)),
                        );
                        }
                      });
                    }
                    catch(err){
                      print("Here is the error");
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
}