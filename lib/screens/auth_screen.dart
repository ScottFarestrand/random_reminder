import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:random_reminder/utilities/message_box.dart';
import 'home_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isLoginMode = true; // State to toggle between login and register

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // @override
  // void init() {
  //   _emailController.text = 'scotfarestrand@gmail.com';
  //   _passwordController.text = 'LeeAnn96';
  // }

  /// Handles user registration with email and password.
  Future<void> _register() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());

      // -----------------------------------------------------------------
      // STEP 2: THIS IS THE NEW LINE!
      // -----------------------------------------------------------------
      // We found a user? Great. Send the email.
      // We don't 'await' this. We just fire and forget.
      userCredential.user?.sendEmailVerification();
      // -----------------------------------------------------------------

      // STEP 3: Tell the user what to do
      // (You'll need a 'context' to be available in this function)
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Success! A verification email has been sent. Please check your inbox.'), backgroundColor: Colors.green));

      // STEP 4: Send them back to the login screen
      // This is the key. We log them out, forcing them to log in *after*
      // they click the link in their email.
      // (If you are in a separate screen, you might just pop())
      await FirebaseAuth.instance.signOut();

      // (If you're using a single screen for login/register, just
      // switch the view back to "login")
    } catch (e) {
      showMessageBox(context, "An unexpected error occurred: $e", MessageType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Handles user login with email and password.
  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    try {
      // STEP 1: Try to sign in
      final userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(email: _emailController.text.trim(), password: _passwordController.text.trim());

      // STEP 2: We have a user! NOW, check if they're verified.
      if (userCredential.user != null) {
        if (userCredential.user!.emailVerified) {
          // --- THE "HAPPY PATH" ---
          // They are verified! Let them in.
          // (Hide loading spinner)
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => HomeScreen(userId: userCredential.user!.uid)));
        } else {
          // --- THE "BOUNCER" PATH ---
          // They exist, but they're not verified.
          // 1. Send another email, just in case.
          await userCredential.user!.sendEmailVerification();

          // 2. Sign them out immediately.
          await FirebaseAuth.instance.signOut();

          // 3. Show the "check your email" message.
          // (Hide loading spinner)
          if (mounted) {
            // Good practice: check if widget is still on screen
            showMessageBox(
              context,
              'Your email is not verified. We just sent another verification link. Please check your email (including Spam Folder)',
              MessageType.warning, // Or .error, your call
            );
          }
        }
      }
    } on FirebaseAuthException catch (e) {
      // Handle "wrong-password", "user-not-found", etc.
      // (Hide loading spinner)
      if (mounted) {
        showMessageBox(context, 'Login failed: ${e.message}', MessageType.error);
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _emailController.text = 'scottfarestrand@gmail.com';
    _passwordController.text = 'LeeAnn96';
    return Scaffold(
      appBar: AppBar(title: Text(_isLoginMode ? 'Login' : 'Register'), backgroundColor: Colors.blue[600], foregroundColor: Colors.white),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFE3F2FD), Color(0xFFE1BEE7)], // from-blue-100 to-purple-100
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              elevation: 8.0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isLoginMode ? 'Welcome Back!' : 'Create Your Account',
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.black87),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 30),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email',
                        hintText: 'your@example.com',
                        prefixIcon: const Icon(Icons.email),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: '••••••••',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        filled: true,
                        fillColor: Colors.grey[100],
                      ),
                    ),
                    const SizedBox(height: 30),
                    _isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoginMode ? _login : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue[600],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 15),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                elevation: 5,
                                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              child: Text(_isLoginMode ? 'Login' : 'Register'),
                            ),
                          ),
                    const SizedBox(height: 20),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _isLoginMode = !_isLoginMode;
                          _emailController.clear();
                          _passwordController.clear();
                        });
                      },
                      child: Text(_isLoginMode ? 'Don\'t have an account? Register here.' : 'Already have an account? Login here.', style: TextStyle(color: Colors.blue[800])),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
