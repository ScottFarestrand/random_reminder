import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_reminder/models/user_profile.dart';
import 'package:random_reminder/utilities/message_box.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final Function(String, MessageType) showMessage;

  const SettingsScreen({super.key, required this.userId, required this.showMessage});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  late TextEditingController _phoneController;

  late Future<UserProfile> _userProfileFuture;
  UserProfile? _userProfile;

  // --- NEW: We get the user's email directly ---
  final String? _currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _userProfileFuture = _fetchUserProfile();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  /// --- SIMPLIFIED: No more email logic ---
  Future<UserProfile> _fetchUserProfile() async {
    final docRef = _firestore.collection('users').doc(widget.userId);
    final docSnap = await docRef.get();

    UserProfile profile;
    if (docSnap.exists) {
      profile = UserProfile.fromMap(widget.userId, docSnap.data());
    } else {
      // If they don't have a profile, create one
      profile = UserProfile.empty(widget.userId);
      // We no longer add email here, just create the doc
      await docRef.set(profile.toMap());
    }

    _phoneController.text = profile.phone ?? '';
    _userProfile = profile;

    return profile;
  }

  /// Saves only phone data
  Future<void> _saveProfile() async {
    if (_userProfile == null) return;

    final newPhone = _phoneController.text.trim();
    final Map<String, dynamic> updates = {};

    if (newPhone != (_userProfile!.phone ?? '')) {
      updates['phone'] = newPhone;
      updates['isPhoneVerified'] = false; // Require re-verification
    }

    if (updates.isNotEmpty) {
      try {
        final docRef = _firestore.collection('users').doc(_userProfile!.uid);
        await docRef.set(updates, SetOptions(merge: true));

        if (!mounted) return;
        widget.showMessage('Profile saved!', MessageType.success);

        setState(() {
          _userProfileFuture = _fetchUserProfile();
        });
      } catch (e) {
        if (!mounted) return;
        widget.showMessage('Error saving profile: $e', MessageType.error);
      }
    }
  }

  /// TODO: Implement Phone Verification Logic
  void _onVerifyPhonePressed() {
    if (_userProfile == null) return;
    _saveProfile();

    if (_userProfile!.isPhoneVerified) {
      widget.showMessage('Phone is already verified.', MessageType.info);
      return;
    }

    print('TODO: Start phone verification');
    widget.showMessage('TODO: Start phone verification', MessageType.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: FutureBuilder<UserProfile>(
        future: _userProfileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error loading profile: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
            );
          }
          // Note: snapshot.data is our UserProfile, which NO LONGER has email
          // final userProfile = snapshot.data!;
          // We can use _userProfile, which is set in the future

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notification Methods', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Manage the email and phone number used for reminders.', style: TextStyle(fontSize: 16)),
                const Divider(height: 32),

                // --- UPDATED: Email Field (Read-Only) ---
                Text('Email Address', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                // --- THE FIX: Display email from Auth ---
                Text(_currentUserEmail ?? 'No email found', style: const TextStyle(fontSize: 16, color: Colors.blueGrey)),
                const SizedBox(height: 8),
                Row(
                  children: const [
                    Icon(Icons.check_circle, color: Colors.green, size: 16),
                    SizedBox(width: 8),
                    Text('Verified'),
                  ],
                ),
                const SizedBox(height: 24),

                // --- UNCHANGED: Phone Field ---
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
                    icon: Icon(
                      _userProfile?.isPhoneVerified == true ? Icons.check_circle : Icons.warning,
                      color: _userProfile?.isPhoneVerified == true ? Colors.green : Colors.orange,
                    ),
                    label: Text(_userProfile?.isPhoneVerified == true ? 'Verified' : 'Verify Phone'),
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
