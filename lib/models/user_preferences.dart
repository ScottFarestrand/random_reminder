import 'package:cloud_firestore/cloud_firestore.dart';

class UserPreferences {
  final String userId;
  final String reminderPreference; // 'none', 'email', 'sms'
  final String? contactEmail;
  final String? contactPhone;

  UserPreferences({
    required this.userId,
    this.reminderPreference = 'none',
    this.contactEmail,
    this.contactPhone,
  });

  factory UserPreferences.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?; // Use nullable map
    return UserPreferences(
      userId: doc.id,
      reminderPreference: data?['reminderPreference'] as String? ?? 'none',
      contactEmail: data?['contactEmail'] as String?,
      contactPhone: data?['contactPhone'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reminderPreference': reminderPreference,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'lastUpdatedPreferences': FieldValue.serverTimestamp(),
    };
  }
}
