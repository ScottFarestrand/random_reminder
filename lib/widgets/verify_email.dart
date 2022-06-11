import 'package:flutter/material.dart';
// import '../screens/screen2.dart';
class ValidateEmail extends StatefulWidget {
  final Function callback;
  const ValidateEmail({Key? key, required this.callback()}) : super(key: key);

  @override
  State<ValidateEmail> createState() => _ValidateEmailState();
}

class _ValidateEmailState extends State<ValidateEmail> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).backgroundColor,
      // drawer: NavDrawer(),
      appBar: AppBar(
        title: Text("menu"),
      ),
      body: Column(
        children: [


          Text("Validate", style: TextStyle(fontSize: 30),),
          ElevatedButton(
              onPressed: () {
                // Navigator.pushNamed(context, Screen_2.id);
              },
              child: Text("Verify Email"))
        ],
      ),

    );
  }
}