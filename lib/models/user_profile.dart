import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String? email;
  final bool isEmailVerified;
  final String? phone; // Store in E.164 format, e.g., "+15551234567"
  final bool isPhoneVerified;

  UserProfile({required this.uid, this.email, this.isEmailVerified = false, this.phone, this.isPhoneVerified = false});

  // A factory for creating a default, empty profile for a new user
  factory UserProfile.empty(String uid) {
    return UserProfile(uid: uid, isEmailVerified: false, isPhoneVerified: false);
  }

  // Convert from a Firestore Map
  factory UserProfile.fromMap(String uid, Map<String, dynamic>? map) {
    if (map == null) {
      return UserProfile.empty(uid);
    }
    return UserProfile(uid: uid, email: map['email'], isEmailVerified: map['isEmailVerified'] ?? false, phone: map['phone'], isPhoneVerified: map['isPhoneVerified'] ?? false);
  }

  // Convert to a Map to save to Firestore
  Map<String, dynamic> toMap() {
    return {'email': email, 'isEmailVerified': isEmailVerified, 'phone': phone, 'isPhoneVerified': isPhoneVerified};
  }
}
