import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // <-- Required import
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
  // We force the region to 'us-central1' to prevent auth issues
  final _functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  late TextEditingController _phoneController;

  late Future<UserProfile> _userProfileFuture;
  UserProfile? _userProfile;
  final String? _currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  bool _isVerifying = false;
  // Loading state for our new test button
  bool _isTestingSms = false;

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

  /// Fetches the UserProfile from Firestore.
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

  /// Saves only phone data
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

  /// Function to show the code-entry dialog
  Future<void> _showOtpDialog(String phoneNumber) async {
    final codeController = TextEditingController();
    final BuildContext dialogContext = context;

    await showDialog(
      context: dialogContext,
      barrierDismissible: false,
      builder: (context) {
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
                  onPressed: isCheckingCode
                      ? null
                      : () async {
                          setDialogState(() {
                            isCheckingCode = true;
                          });
                          try {
                            final callable = _functions.httpsCallable('checkVerificationCode');
                            final result = await callable.call<Map<String, dynamic>>({'phoneNumber': phoneNumber, 'code': codeController.text});
                            if (!mounted) return;
                            if (result.data['success'] == true) {
                              Navigator.of(context).pop();
                              widget.showMessage('Phone verified!', MessageType.success);
                              setState(() {
                                _userProfileFuture = _fetchUserProfile();
                              });
                            } else {
                              widget.showMessage('Invalid code. Please try again.', MessageType.error);
                            }
                          } on FirebaseFunctionsException catch (e) {
                            if (!mounted) return;
                            widget.showMessage('Error: ${e.message}', MessageType.error);
                          } finally {
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

  /// Phone Verification Logic
  void _onVerifyPhonePressed() async {
    if (_userProfile?.isPhoneVerified == true) {
      widget.showMessage('Phone is already verified.', MessageType.info);
      return;
    }
    await _saveProfile();
    final phoneNumber = _phoneController.text.trim();
    if (phoneNumber.isEmpty) {
      widget.showMessage('Please enter a phone number.', MessageType.error);
      return;
    }
    if (!phoneNumber.startsWith('+')) {
      widget.showMessage('Please use E.164 format (e.g., +15551234567).', MessageType.error);
      return;
    }
    if (mounted)
      setState(() {
        _isVerifying = true;
      });
    try {
      final callable = _functions.httpsCallable('sendVerificationCode');
      await callable.call<Map<String, dynamic>>({'phoneNumber': phoneNumber});
      if (!mounted) return;
      widget.showMessage('Verification code sent!', MessageType.info);
      await _showOtpDialog(phoneNumber);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      widget.showMessage('Error: ${e.message}', MessageType.error);
    } finally {
      if (mounted)
        setState(() {
          _isVerifying = false;
        });
    }
  }

  /// --- NEW: Function to call our testSms cloud function ---
  void _onTestSmsPressed() async {
    if (_userProfile?.isPhoneVerified != true) {
      widget.showMessage('You must verify your phone number before sending a test.', MessageType.error);
      return;
    }
    if (mounted)
      setState(() {
        _isTestingSms = true;
      });
    try {
      final callable = _functions.httpsCallable('testSms');
      final result = await callable.call(); // No parameters needed
      if (!mounted) return;
      widget.showMessage(result.data['message'] ?? 'Test SMS sent!', MessageType.success);
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      widget.showMessage('Error: ${e.message}', MessageType.error);
    } finally {
      if (mounted)
        setState(() {
          _isTestingSms = false;
        });
    }
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

                // --- Email Address section ---
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

                // --- Phone Number section ---
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

                const SizedBox(height: 40),

                // --- NEW: Test Button Section ---
                Center(
                  child: _isTestingSms
                      ? const CircularProgressIndicator()
                      : ElevatedButton.icon(
                          icon: const Icon(Icons.sms),
                          label: const Text('Send Test SMS'),
                          onPressed: _userProfile?.isPhoneVerified == true ? _onTestSmsPressed : null,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                        ),
                ),

                const SizedBox(height: 20),

                // --- Save Changes Button ---
                Center(
                  child: ElevatedButton(onPressed: _saveProfile, child: const Text('Save Changes')),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
