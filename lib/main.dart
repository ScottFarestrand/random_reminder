import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_reminder/screens/auth_screen.dart';
import 'package:random_reminder/screens/home_screen.dart';

// You will need to generate this file based on your Firebase project
// using `flutterfire configure` command.
// import 'firebase_options.dart'; // Uncomment and configure this in your project

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase. Replace with your actual Firebase options.
  // For example: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // For demonstration purposes without firebase_options.dart:
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // This catch block is for local testing without proper firebase_options.dart
    // In a real app, you'd handle this more robustly.
    print(
      "Firebase not initialized. Make sure 'firebase_options.dart' is set up correctly.",
    );
    print("Error: $e");
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Random Reminders',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        fontFamily: 'Inter', // Assuming Inter font is available or linked
      ),
      // Use a StreamBuilder to listen to authentication state changes
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            // User is signed in, show HomeScreen
            return HomeScreen(userId: snapshot.data!.uid);
          }
          // User is not signed in, show AuthScreen
          return const AuthScreen();
        },
      ),
    );
  }
}
