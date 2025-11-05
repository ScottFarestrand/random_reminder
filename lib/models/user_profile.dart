import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;

  // email and isEmailVerified are GONE.

  final String? phone; // Store in E.164 format, e.g., "+15551234567"
  final bool isPhoneVerified;

  UserProfile({required this.uid, this.phone, this.isPhoneVerified = false});

  // A factory for creating a default, empty profile for a new user
  factory UserProfile.empty(String uid) {
    return UserProfile(uid: uid, isPhoneVerified: false);
  }

  // Convert from a Firestore Map
  factory UserProfile.fromMap(String uid, Map<String, dynamic>? map) {
    if (map == null) {
      return UserProfile.empty(uid);
    }
    return UserProfile(uid: uid, phone: map['phone'], isPhoneVerified: map['isPhoneVerified'] ?? false);
  }

  // Convert to a Map to save to Firestore
  Map<String, dynamic> toMap() {
    return {'phone': phone, 'isPhoneVerified': isPhoneVerified};
  }

  // copyWith is GONE. We don't need it for this simple model anymore.
}
