import 'package:flutter/material.dart';
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
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  String _reminderPreference = 'none';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserPreferences() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final userDoc = await _firestoreService
          .getUserStream(widget.userId)
          .first;
      if (userDoc.exists) {
        final preferences = UserPreferences.fromFirestore(userDoc);
        _emailController.text = preferences.contactEmail ?? '';
        _phoneController.text = preferences.contactPhone ?? '';
        _reminderPreference = preferences.reminderPreference;
      }
    } catch (e) {
      widget.showMessage(
        'Failed to load settings: ${e.toString()}',
        MessageType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreferences() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final preferences = UserPreferences(
        contactEmail: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        contactPhone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        reminderPreference: _reminderPreference,
      );
      await _firestoreService.saveUserPreferences(widget.userId, preferences);
      widget.showMessage('Settings saved successfully!', MessageType.success);
    } catch (e) {
      widget.showMessage(
        'Failed to save settings: ${e.toString()}',
        MessageType.error,
      );
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
                  elevation: 4.0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Contact Information',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF37474F),
                          ),
                        ),
                        const Divider(height: 20, thickness: 1),
                        TextField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'Contact Email',
                            hintText: 'e.g., your@example.com',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _phoneController,
                          decoration: InputDecoration(
                            labelText: 'Contact Phone (for SMS)',
                            hintText: 'e.g., +15551234567',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          keyboardType: TextInputType.phone,
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Reminder Preference',
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
                            labelText:
                                'How would you like to receive reminders?',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'none',
                              child: Text('None'),
                            ),
                            // Removed 'email' and 'both' options based on previous request
                            // DropdownMenuItem(value: 'email', child: Text('Email')),
                            DropdownMenuItem(value: 'sms', child: Text('SMS')),
                            // DropdownMenuItem(value: 'both', child: Text('Both Email & SMS')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _reminderPreference = value;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _savePreferences,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Save Settings',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
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
