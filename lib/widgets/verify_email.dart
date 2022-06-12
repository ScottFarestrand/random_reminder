import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import '../screens/screen2.dart';
class ValidateEmail extends StatefulWidget {
  final Function loginCallback;
  const ValidateEmail({Key? key, required this.loginCallback()}) : super(key: key);

  @override
  State<ValidateEmail> createState() => _ValidateEmailState();
}

class _ValidateEmailState extends State<ValidateEmail> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final emailAdd = user.email.toString();
    return Center(
      child: Column(
        children: [
          Text("You registered with email Address", style: TextStyle(fontSize: 20),),
          Text(emailAdd, style: TextStyle(fontSize: 24)),
          Text("If the email address is correct, press verify email"),
          Text("and respond to the email to verify the email address is correct"),
          ElevatedButton(
              onPressed: () {
                // sendVerificationEmail();
                final user = FirebaseAuth.instance.currentUser;
                user!.sendEmailVerification()
                    .whenComplete(() => print("Success"))
                    .onError((error, stackTrace) {print(error);});
                
                // Navigator.pushNamed(context, Screen_2.id);
              },
              child: Text("Verify Email")),
          ElevatedButton(onPressed: (){
            FirebaseAuth.instance.signOut();
          }, child: Text('Log out')),
          ElevatedButton(
              onPressed: () {
                try {
                  user.delete().then((value) => null).then((value) => {
                    print("Delete Success")
                  }).catchError((err){
                    print("catch");
                    print(err.code.toString());
                  });
                  // Navigator.pushNamed(context, Screen_2.id);
                }catch(e){
                  print("last e");
                  print(e.toString());
                }
              },
              child: Text("Oops, that was the wrong Email address")),
        ],
      ),
    );

  }
  Future sendVerificationEmail() async{
    print("In Sending");
    try {
      final user = FirebaseAuth.instance.currentUser!;
      user.sendEmailVerification().then((value) {
        print(user.email);
        print("Success");
      } );
    } catch(err){
      print("Error");
      print(err);
    }

  }
}