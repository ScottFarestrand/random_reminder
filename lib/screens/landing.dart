import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'package:firebase_core/firebase_core.dart';
import '../widgets/Login.dart';
import '../widgets/verify_email.dart';
import '../widgets/personal_info.dart';
import '../widgets/register.dart';

// import '../widgets/register2.dart';
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

  // void setStateLoggedIn(){
  //   ScaffoldMessenger.of(context).showSnackBar(
  //       SnackBar(
  //         content: Text('You have logged in!'),
  //       )
  //   );
  //   setState((){
  //     pageWidget = pageWidgets.validate;
  //   });
  // }
  // void setStateValidated(){
  //   setState((){
  //     // pageWidget = appState.validated;
  //   });
  // }
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
                print("has Data");
                final user = FirebaseAuth.instance.currentUser!;
                isVerified = user.emailVerified;
                if (!isVerified) {
                  print("not Verified");
                  return ValidateEmail(loginCallback: setStateLogin);
                  // return VerifyEmail();
                  // return Text("Timee to Verify Email");
                }
                // return Text('Time to Login');
                print("Go to Persoanl");
                return PersonalInfo();
              } else {
                print("Login Page");
                return Login(loginCallBack: setStateLogin,
                    registerCallBack: setStateRegister);
                // return Login(loginCallBack: setStateLogin,
                //     registerCallBack: setStateRegister);
                // return Login();
              }
            },
          )
      );
    }
    else {
      return Register(loginCallback: setStateLogin);
      // return Register2(loginCallBack: setStateLogin);
      // return Register(callback: setStateRegister);
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