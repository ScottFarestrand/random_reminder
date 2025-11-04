import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreferences {
  final String? contactEmail;
  final String? contactPhone;
  final String reminderPreference; // 'email', 'sms', 'both', 'none'

  UserPreferences({
    this.contactEmail,
    this.contactPhone,
    required this.reminderPreference,
  });

  Map<String, dynamic> toMap() {
    return {
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'reminderPreference': reminderPreference,
    };
  }

  factory UserPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    return UserPreferences(
      contactEmail: data?['contactEmail'],
      contactPhone: data?['contactPhone'],
      reminderPreference: data?['reminderPreference'] ?? 'none',
    );
  }
}
