// file: delivery_channels.dart

class DeliveryChannels {
  final bool push;
  final bool email;
  final bool sms;

  DeliveryChannels({
    this.push = true, // Default to push being on
    this.email = false,
    this.sms = false,
  });

  // --- For State Management (optional but recommended) ---

  DeliveryChannels copyWith({bool? push, bool? email, bool? sms}) {
    return DeliveryChannels(push: push ?? this.push, email: email ?? this.email, sms: sms ?? this.sms);
  }

  // --- For Firestore ---

  /// Converts this object into a Map to save in Firestore.
  Map<String, dynamic> toMap() {
    return {'push': push, 'email': email, 'sms': sms};
  }

  /// Creates an object from a Firestore document Map.
  factory DeliveryChannels.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      // Return a default if something is wrong
      return DeliveryChannels();
    }
    return DeliveryChannels(push: map['push'] ?? true, email: map['email'] ?? false, sms: map['sms'] ?? false);
  }
}
