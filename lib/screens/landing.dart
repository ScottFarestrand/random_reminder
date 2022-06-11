import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../widgets/Login.dart';
import '../widgets/verify_email.dart';
import '../widgets/register.dart';
enum pageWidgets {
  landing,
  login,
  register,
  validate,
}

class Landing extends StatefulWidget {
  static const id = "Landing";

  const Landing({Key? key}) : super(key: key);

  @override
  State<Landing> createState() => _LandingState();
}

class _LandingState extends State<Landing> {
  var pageWidget = pageWidgets.landing;

  void setStateLoggedIn(){
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You have logged in!'),
        )
    );
    setState((){
      pageWidget = pageWidgets.validate;
    });
  }
  void setStateValidated(){
    setState((){
      // pageWidget = appState.validated;
    });
  }
  void setStateRegister(){
    print("Register");
    setState((){
      pageWidget = pageWidgets.landing;
    });
  }
  @override
  Widget build(BuildContext context) {
    bool isVerified = false;
    if (pageWidget == pageWidgets.landing) {
      return Scaffold(
          backgroundColor: Theme
              .of(context)
              .colorScheme
              .primary,
          appBar: AppBar(
            title: Text("Random Reminder"),
          ),
          // body: Login(),
          body: StreamBuilder<User?>(
            stream: FirebaseAuth.instance.authStateChanges(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                print("Yes");
                final user = FirebaseAuth.instance.currentUser!;
                isVerified = user.emailVerified;
                if (!isVerified) {
                  print("Verify");
                  // return VerifyEmail();
                  return Text("Timee to Verify Email");
                }
                // return Text('Time to Login');
                return Login(loginCallBack: setStateLoggedIn,
                    registerCallBack: setStateRegister);
              } else {
                return Login(loginCallBack: setStateLoggedIn,
                    registerCallBack: setStateRegister);
                // return Login();
              }
            },
          )
      );
    }
    else {
      return Register(callback: setStateRegister);
    }

    // if (pageWidget == pageWidgets.landing) {
    //   return Login(loginCallBack: setStateLoggedIn,
    //       registerCallBack: setStateRegister);
    // }
    //
    // if (pageWidget == pageWidgets.validate) {
    //   return validateEmail(callback: setStateValidated,);
    // }
    // if (pageWidget == pageWidgets.register) {
    //   return Register(callback:setStateValidated );
    // }
    // // if (userState == appState.validated) {}
    // return Login(loginCallBack: setStateLoggedIn,
    //     registerCallBack: setStateRegister);

  }


}