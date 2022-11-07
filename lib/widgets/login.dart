import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_navigation/screens/screen1.dart';
class Login extends StatelessWidget {
  final Function loginCallBack;
  final Function registerCallBack;

  const Login({Key? key, required this.loginCallBack(), required this.registerCallBack()}) : super(key: key);

  @override

  Widget build(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    emailController.text = "ScottFarestrand@gmail.com";
    passwordController.text = "Jlj#980507";
    return Form(
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
            ),
            ElevatedButton(
              onPressed: () {
                print("Login Pressed");
                try {
                   FirebaseAuth.instance.signInWithEmailAndPassword(
                      email: emailController.text.trim(),
                      password: passwordController.text.trim()
                  ).then((value) {
                    print("I am HERE");
                  });
                } on FirebaseAuthException catch (e){
                  print("ERROR");
                  print(e.code.toString());
                }
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Logging In")),
                  );
              },
              child: const Text('Login'),
            ),
            ElevatedButton(onPressed: () {
              registerCallBack();
            }, child: Text("Register")),
            ElevatedButton(onPressed: (){
              FirebaseAuth.instance.signOut();
            }, child: Text("Log out")),
            ElevatedButton(onPressed: (){}, child: Text("Write a rec")),
          ],
        ),
      ),

    );
  }

}