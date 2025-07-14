import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // For initial user doc creation if needed
import 'package:random_reminder/models/user_preferences.dart';
import 'package:random_reminder/services/firestore_service.dart';
import 'package:random_reminder/utilities/message_box.dart';

class SettingsScreen extends StatefulWidget {
  final String userId;
  final Function(String, MessageType) showMessage;

  const SettingsScreen({
    super.key,
    required this.userId,
    required this.showMessage,
  });

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final FirestoreService _firestoreService = FirestoreService();

  String _reminderPreference = 'none'; // 'none', 'email', 'sms'
  final TextEditingController _contactEmailController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchUserPreferences();
  }

  @override
  void dispose() {
    _contactEmailController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  /// Fetches the current user's preferences from Firestore.
  Future<void> _fetchUserPreferences() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userDoc = await _firestoreService
          .getUserStream(widget.userId)
          .first;
      if (userDoc.exists) {
        final preferences = UserPreferences.fromFirestore(userDoc);
        setState(() {
          _reminderPreference = preferences.reminderPreference;
          _contactEmailController.text = preferences.contactEmail ?? '';
          _contactPhoneController.text = preferences.contactPhone ?? '';
        });
      } else {
        // If user document doesn't exist, create a basic one (should ideally be done on registration)
        await FirebaseFirestore.instance
            .collection('artifacts')
            .doc('default-app-id') // Ensure this matches your Firebase rules
            .collection('users')
            .doc(widget.userId)
            .set({
              'createdAt': FieldValue.serverTimestamp(),
              'reminderPreference': 'none',
            }, SetOptions(merge: true));
        widget.showMessage('User preferences initialized.', MessageType.info);
      }
    } catch (e) {
      widget.showMessage('Failed to load preferences: $e', MessageType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Saves the updated user preferences to Firestore.
  Future<void> _savePreferences() async {
    // Validate contact info if preference is set
    if (_reminderPreference == 'email' &&
        _contactEmailController.text.trim().isEmpty) {
      widget.showMessage(
        'Please enter an email address for email reminders.',
        MessageType.error,
      );
      return;
    }
    if (_reminderPreference == 'sms' &&
        _contactPhoneController.text.trim().isEmpty) {
      widget.showMessage(
        'Please enter a phone number for SMS reminders.',
        MessageType.error,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final updatedPreferences = UserPreferences(
        userId: widget.userId,
        reminderPreference: _reminderPreference,
        contactEmail: _contactEmailController.text.trim().isNotEmpty
            ? _contactEmailController.text.trim()
            : null,
        contactPhone: _contactPhoneController.text.trim().isNotEmpty
            ? _contactPhoneController.text.trim()
            : null,
      );
      await _firestoreService.updateUserPreferences(
        widget.userId,
        updatedPreferences,
      );
      widget.showMessage(
        'Preferences saved successfully!',
        MessageType.success,
      );
    } catch (e) {
      widget.showMessage('Failed to save preferences: $e', MessageType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFE1BEE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 0.0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  elevation: 4.0,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Reminder Delivery Preferences',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF37474F),
                          ),
                        ),
                        const Divider(height: 20, thickness: 1),
                        DropdownButtonFormField<String>(
                          value: _reminderPreference,
                          decoration: InputDecoration(
                            labelText: 'Default Delivery Method',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'none',
                              child: Text('None'),
                            ),
                            DropdownMenuItem(
                              value: 'email',
                              child: Text('Email'),
                            ),
                            DropdownMenuItem(
                              value: 'sms',
                              child: Text('SMS Text'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _reminderPreference = value!;
                            });
                          },
                        ),
                        if (_reminderPreference == 'email') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _contactEmailController,
                            decoration: InputDecoration(
                              labelText: 'Recipient Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              hintText: 'e.g., example@domain.com',
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ],
                        if (_reminderPreference == 'sms') ...[
                          const SizedBox(height: 16),
                          TextField(
                            controller: _contactPhoneController,
                            decoration: InputDecoration(
                              labelText: 'Recipient Phone Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              hintText:
                                  'e.g., +15551234567 (include country code)',
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _savePreferences,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2196F3),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text(
                            'Save Preferences',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}
