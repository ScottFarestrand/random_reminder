// import 'dart:html';

// import 'dart:html';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_reminder/screens/person.dart';
import '../services/navigation.dart';
import '../widgets/Login.dart';
import '../widgets/verify_email.dart';
import '../widgets/personal_info.dart';
import '../screens/relationships_screen.dart';
import '../widgets/register.dart';
import '../widgets/drawer.dart';
// import '../screens/validate_email.dart';

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
  final NavigationService nav = NavigationService.instance;

  var pageWidget = PageWidgets.login;
  int _currentIndex = 0;

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
    print("Build Landing");
    Widget curWidget = PersonalInfo();
    bool isVerified = false;
    if (pageWidget == PageWidgets.login) {
      return Scaffold(
        drawer: NavDrawer(
        ),
          appBar: AppBar(
            title: Text("Random Reminder"),
            actions: [
              IconButton(onPressed: ()=>{
                print("Presssed"),
                // NavigationService
              }, icon: Icon(Icons.add))
            ],
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
                  // nav.push(ValidateEmail(loginCallback: loginCallback));s
                  return ValidateEmail(loginCallback: setStateLogin);
                }
                print("Go to Personal");
                print(_currentIndex);
                switch(_currentIndex) {
                  case 0:
                    print("Profile");
                    break;
                  case 1:
                    print("Pushing");
                    // Navigator.pushNamed(context, Relationships_Screen.id);
                    curWidget = Relationships_Screen();

                    // return PersonalInfo();
                    break;
                  case 2:
                    print("Logout");
                    // return PersonalInfo();
                    break;


                }
                return curWidget;
              } else {
                print("Login Page");
                return Login(loginCallBack: setStateLogin,
                    registerCallBack: setStateRegister);
              }
            },
          ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedFontSize: 15,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          unselectedFontSize: 10,
          backgroundColor: Colors.blue,
          items: [
        BottomNavigationBarItem(
        icon: Icon(Icons.person),
          label: "Profile",
          backgroundColor: Colors.blue),
            BottomNavigationBarItem(
              icon: Icon(Icons.people),
              label: "Relationships",
            backgroundColor: Colors.blue),
            BottomNavigationBarItem(
                icon: Icon(Icons.logout),
                label: "Logout",
                backgroundColor: Colors.blue),
            BottomNavigationBarItem(
                icon: Icon(Icons.close),
                label: "Close App",
                backgroundColor: Colors.blue)
          ],
        ),
      );
    }
    else {
      return Register(loginCallback: setStateLogin);

    }
  }
}