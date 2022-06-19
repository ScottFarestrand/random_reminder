import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/Login.dart';
import '../widgets/verify_email.dart';
import '../widgets/personal_info.dart';
import '../widgets/register.dart';

enum PageWidgets {
  login,
  register,
}

class Landing extends StatefulWidget {
  static const id = "Landing";

  const Landing({Key? key}) : super(key: key);

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  var pageWidget = PageWidgets.login;

  void setStateRegister(){
    setState((){
      pageWidget = PageWidgets.register;
    });
  }
  void setStateLogin(){
    setState((){
      pageWidget = PageWidgets.login;
    }
    );
  }
  @override
  Widget build(BuildContext context) {
    bool isVerified = false;
    if (pageWidget == PageWidgets.login) {
      return Scaffold(
          // backgroundColor: Theme
          //     .of(context)
          //     .colorScheme
          //     .primary,
          appBar: AppBar(
            title: Text("Random Reminder"),
          ),
          // body: Login(),
          body: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                print("has Data");
                final user = FirebaseAuth.instance.currentUser!;
                isVerified = user.emailVerified;
                if (!isVerified) {
                  print("not Verified");
                  return ValidateEmail(loginCallback: setStateLogin);
                }
                print("Go to Persoanl");
                return PersonalInfo();
              } else {
                print("Login Page");
                return Login(loginCallBack: setStateLogin,
                    registerCallBack: setStateRegister);
              }
            },
          )
      );
    }
    else {
      return Register(loginCallback: setStateLogin);

    }
  }
}