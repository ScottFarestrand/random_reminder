import 'package:flutter/material.dart';
import './screens/landing_screen.dart';
import './services/navigation.dart';
import './screens/relationships_screen.dart';
import 'package:firebase_core/firebase_core.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: NavigationService.instance.navigatorKey,
      title: 'Flutter Demo',

      home: Landing_Screen(),
      initialRoute: Landing_Screen.id,
      routes: {
        Landing_Screen.id: (context) => Landing_Screen(),
        Relationships_Screen.id: (context) => Relationships_Screen(),
      },
    );
  }

}

