import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_reminder/models/user_profile.dart'; // Import the model
import 'package:random_reminder/utilities/message_box.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final Function(String, MessageType) showMessage; // <-- ADD THIS

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.showMessage, // <-- ADD THIS
  });

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Firebase instances
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Controllers to manage the text fields
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  // This future will hold our user profile data
  late Future<UserProfile> _userProfileFuture;

  // This will hold the loaded profile
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();

    // Start fetching the user profile as soon as the widget is created
    _userProfileFuture = _fetchUserProfile();
  }

  @override
  void dispose() {
    // Clean up controllers
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  /// Fetches the UserProfile from Firestore.
  Future<UserProfile> _fetchUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) {
      // This shouldn't happen if they are on this screen, but good to check
      throw Exception("No authenticated user found.");
    }

    final docRef = _firestore.collection('users').doc(user.uid);
    final docSnap = await docRef.get();

    UserProfile profile;
    if (docSnap.exists) {
      // User has a profile, load it
      profile = UserProfile.fromMap(user.uid, docSnap.data());
    } else {
      // First time user, create a default profile for them
      profile = UserProfile.empty(user.uid);
      // We MUST save this back to Firestore to create the document
      await docRef.set(profile.toMap()); // <-- THIS IS THE FIX
    }

    // Set controller text and store the profile
    _emailController.text = profile.email ?? '';
    _phoneController.text = profile.phone ?? '';
    _userProfile = profile; // Store for later use in verify buttons

    return profile;
  }

  /// Saves the current text in the controllers to Firestore
  Future<void> _saveProfile() async {
    if (_userProfile == null) return; // Not loaded yet

    final newEmail = _emailController.text.trim();
    final newPhone = _phoneController.text.trim();

    // Only update if text actually changed
    final Map<String, dynamic> updates = {};
    if (newEmail != (_userProfile!.email ?? '')) {
      updates['email'] = newEmail;
      updates['isEmailVerified'] = false; // Require re-verification
    }
    if (newPhone != (_userProfile!.phone ?? '')) {
      updates['phone'] = newPhone;
      updates['isPhoneVerified'] = false; // Require re-verification
    }

    if (updates.isNotEmpty) {
      try {
        final docRef = _firestore.collection('users').doc(_userProfile!.uid);
        await docRef.set(updates, SetOptions(merge: true));

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile saved!'), backgroundColor: Colors.green));
        // Refresh the profile data
        setState(() {
          _userProfileFuture = _fetchUserProfile();
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving profile: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// TODO: Implement Email Verification Logic
  void _onVerifyEmailPressed() {
    if (_userProfile == null) return;
    _saveProfile(); // Save any changes first

    if (_userProfile!.isEmailVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email is already verified.')));
      return;
    }

    // 1. Get the current user
    // 2. Call user.sendEmailVerification()
    // 3. Show a snackbar telling them to check their email
    print('TODO: Send email verification');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TODO: Send email verification')));
  }

  /// TODO: Implement Phone Verification Logic
  void _onVerifyPhonePressed() {
    if (_userProfile == null) return;
    _saveProfile(); // Save any changes first

    if (_userProfile!.isPhoneVerified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone is already verified.')));
      return;
    }

    // This is the complex part
    // 1. Call your Twilio/Firebase Phone Auth function
    // 2. This will likely open a new dialog/screen to enter the 6-digit code
    // 3. On success, update 'isPhoneVerified' to true in Firestore
    print('TODO: Start phone verification');
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('TODO: Start phone verification')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder<UserProfile>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          // --- 1. Handle Loading State ---
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // --- 2. Handle Error State ---
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading profile: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          }

          // --- 3. Handle Success State ---
          if (!snapshot.hasData) {
            return const Center(child: Text('User profile not found.'));
          }

          // We have the data!
          final userProfile = snapshot.data!;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notification Methods', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Manage the email and phone number used for reminders.', style: TextStyle(fontSize: 16)),
                const Divider(height: 32),

                // --- Email Field ---
                Text('Email Address', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'user@example.com', border: OutlineInputBorder()),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _onVerifyEmailPressed,
                    icon: Icon(userProfile.isEmailVerified ? Icons.check_circle : Icons.warning, color: userProfile.isEmailVerified ? Colors.green : Colors.orange),
                    label: Text(userProfile.isEmailVerified ? 'Verified' : 'Verify Email'),
                  ),
                ),
                const SizedBox(height: 24),

                // --- Phone Field ---
                Text('Phone Number', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(hintText: '+15551234567', border: OutlineInputBorder()),

                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: _onVerifyPhonePressed,
                    icon: Icon(userProfile.isPhoneVerified ? Icons.check_circle : Icons.warning, color: userProfile.isPhoneVerified ? Colors.green : Colors.orange),
                    label: Text(userProfile.isPhoneVerified ? 'Verified' : 'Verify Phone'),
                  ),
                ),

                const SizedBox(height: 40),
                Center(
                  child: ElevatedButton(
                    onPressed: _saveProfile,
                    child: const Text('Save Changes'),
                    style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15), textStyle: const TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
