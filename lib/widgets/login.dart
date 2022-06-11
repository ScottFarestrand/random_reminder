import 'package:flutter/material.dart';
// import 'package:flutter_navigation/screens/screen1.dart';
class Login extends StatelessWidget {
  final Function loginCallBack;
  final Function registerCallBack;

  const Login({Key? key, required this.loginCallBack(), required this.registerCallBack()}) : super(key: key);

  @override

  Widget build(BuildContext context) {
    final _formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    emailController.text = "ScottFarestrand@gmail.com";
    passwordController.text = "Jlj#980507";
    return Form(
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
                }
              },
              child: const Text('Login'),
            ),
            ElevatedButton(onPressed: () {
              print("register Pressed");
              registerCallBack();
            }, child: Text("Register")),
          ],
        ),
      ),

    );
  }
}