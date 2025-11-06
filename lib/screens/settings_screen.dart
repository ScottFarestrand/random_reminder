import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// --- NEW IMPORT ---
import 'package:cloud_functions/cloud_functions.dart';
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

  // --- NEW: Firebase Functions instance ---
  // final _functions = FirebaseFunctions.instance;
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  late TextEditingController _phoneController;

  late Future<UserProfile> _userProfileFuture;
  UserProfile? _userProfile;
  final String? _currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  // --- NEW: Loading state for verification button ---
  bool _isVerifying = false;

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

  // (This function is unchanged)
  Future<UserProfile> _fetchUserProfile() async {
    final docRef = _firestore.collection('users').doc(widget.userId);
    final docSnap = await docRef.get();
    UserProfile profile;
    if (docSnap.exists) {
      profile = UserProfile.fromMap(widget.userId, docSnap.data());
    } else {
      profile = UserProfile.empty(widget.userId);
      await docRef.set(profile.toMap());
    }
    _phoneController.text = profile.phone ?? '';
    _userProfile = profile;
    return profile;
  }

  // (This function is unchanged)
  Future<void> _saveProfile() async {
    if (_userProfile == null) return;
    final newPhone = _phoneController.text.trim();
    final Map<String, dynamic> updates = {};
    if (newPhone != (_userProfile!.phone ?? '')) {
      updates['phone'] = newPhone;
      updates['isPhoneVerified'] = false;
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

  /// --- NEW: Function to show the code-entry dialog ---
  Future<void> _showOtpDialog(String phoneNumber) async {
    final codeController = TextEditingController();

    // Grab context *before* the async gap (the 'await showDialog')
    final BuildContext dialogContext = context;

    await showDialog(
      context: dialogContext,
      barrierDismissible: false, // Don't allow closing by tapping outside
      builder: (context) {
        // Use a stateful builder so the dialog can show its own loading spinner
        bool isCheckingCode = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Enter 6-Digit Code'),
              content: TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(hintText: '123456'),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                ElevatedButton(
                  // Show loading spinner on button when checking
                  onPressed: isCheckingCode
                      ? null
                      : () async {
                          setDialogState(() {
                            isCheckingCode = true;
                          });
                          try {
                            // Call our 2nd cloud function
                            final callable = _functions.httpsCallable('checkVerificationCode');
                            final result = await callable.call<Map<String, dynamic>>({'phoneNumber': phoneNumber, 'code': codeController.text});

                            if (!mounted) return; // Check mounted *after* await

                            if (result.data['success'] == true) {
                              Navigator.of(context).pop(); // Close dialog
                              widget.showMessage('Phone verified!', MessageType.success);
                              // Refresh the screen
                              setState(() {
                                _userProfileFuture = _fetchUserProfile();
                              });
                            } else {
                              // Code was wrong
                              widget.showMessage('Invalid code. Please try again.', MessageType.error);
                            }
                          } on FirebaseFunctionsException catch (e) {
                            if (!mounted) return;
                            widget.showMessage('Error: ${e.message}', MessageType.error);
                          } finally {
                            // Only update dialog state if it's still mounted
                            if (Navigator.of(context).canPop()) {
                              setDialogState(() {
                                isCheckingCode = false;
                              });
                            }
                          }
                        },
                  child: isCheckingCode ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// --- UPDATED: Phone Verification Logic (replaces the TODO) ---
  void _onVerifyPhonePressed() async {
    // 0. Check if already verified
    if (_userProfile?.isPhoneVerified == true) {
      widget.showMessage('Phone is already verified.', MessageType.info);
      return;
    }

    // 1. Save any changes first
    await _saveProfile();

    // 2. Get the number from the controller
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      widget.showMessage('Please enter a phone number.', MessageType.error);
      return;
    }
    // Simple validation (Twilio requires E.164 format)
    if (!phoneNumber.startsWith('+')) {
      widget.showMessage('Please use E.164 format (e.g., +15551234567).', MessageType.error);
      return;
    }

    if (mounted) {
      setState(() {
        _isVerifying = true;
      });
    }

    try {
      // 3. Call our 1st cloud function
      final callable = _functions.httpsCallable('sendVerificationCode');
      await callable.call<Map<String, dynamic>>({'phoneNumber': phoneNumber});

      // 4. If successful, show the dialog to enter the code
      if (!mounted) return;
      widget.showMessage('Verification code sent!', MessageType.info);
      // Wait for the dialog to close
      await _showOtpDialog(phoneNumber);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      widget.showMessage('Error: ${e.message}', MessageType.error);
    } finally {
      if (mounted) {
        setState(() {
          _isVerifying = false;
        });
      }
    }
  }

  /// --- UPDSATED: The Build Method ---
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
            return Center(child: Text('Error loading profile: ${snapshot.error}'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Notification Methods', style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                const Text('Manage the email and phone number used for reminders.', style: TextStyle(fontSize: 16)),
                const Divider(height: 32),

                // --- Email Address section (Unchanged) ---
                Text('Email Address', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
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

                // --- Phone Field (Unchanged) ---
                Text('Phone Number', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneController,
                  decoration: const InputDecoration(hintText: '+15551234567', border: OutlineInputBorder(), helperText: 'Must be in E.164 format with country code.'),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  // --- UPDATED: Show loading indicator ---
                  child: _isVerifying
                      ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator())
                      : TextButton.icon(
                          onPressed: _onVerifyPhonePressed,
                          icon: Icon(
                            _userProfile?.isPhoneVerified == true ? Icons.check_circle : Icons.warning,
                            color: _userProfile?.isPhoneVerified == true ? Colors.green : Colors.orange,
                          ),
                          label: Text(_userProfile?.isPhoneVerified == true ? 'Verified' : 'Verify Phone'),
                        ),
                ),

                // --- Save Button (Unchanged) ---
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
