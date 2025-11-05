// file: fixed_reminder.dart

import 'delivery_channels.dart'; // Import the class from above

class FixedReminder {
  final String? id; // Document ID, helpful to have
  final String userId;
  final String eventName;

  // Event Details
  final int eventMonth; // 0-11 (Jan=0, Dec=11)
  final int eventDay; // 1-31
  final int? eventYear; // Optional

  // Timing
  final String notifyTime; // "HH:mm" (e.g., "09:15" or "14:30")
  final String userTimezone; // "America/New_York"

  // Delivery
  final DeliveryChannels deliveryChannels;

  // Contact Info (copied from user's profile at creation)
  final String? userDeviceToken;
  final String? userEmail;
  final String? userPhone; // E.164 format "+15551234567"

  FixedReminder({
    this.id,
    required this.userId,
    required this.eventName,
    required this.eventMonth,
    required this.eventDay,
    this.eventYear,
    required this.notifyTime,
    required this.userTimezone,
    required this.deliveryChannels,
    this.userDeviceToken,
    this.userEmail,
    this.userPhone,
  });

  // --- For Firestore ---

  /// Converts this object into a Map to save in Firestore.
  Map<String, dynamic> toMap() {
    return {
      // We don't save the 'id' field, Firestore provides it.
      'userId': userId,
      'eventName': eventName,
      'eventMonth': eventMonth,
      'eventDay': eventDay,
      'eventYear': eventYear,
      'notifyTime': notifyTime,
      'userTimezone': userTimezone,
      'deliveryChannels': deliveryChannels.toMap(), // Uses the helper class
      'userDeviceToken': userDeviceToken,
      'userEmail': userEmail,
      'userPhone': userPhone,
      // You might also want a 'createdAt' field:
      // 'createdAt': FieldValue.serverTimestamp(),
    };
  }

  /// Creates a FixedReminder object from a Firestore document.
  factory FixedReminder.fromMap(String id, Map<String, dynamic> map) {
    return FixedReminder(
      id: id, // Grab the document ID
      userId: map['userId'] ?? '',
      eventName: map['eventName'] ?? '',
      eventMonth: map['eventMonth'] ?? 0,
      eventDay: map['eventDay'] ?? 1,
      eventYear: map['eventYear'], // Can be null
      notifyTime: map['notifyTime'] ?? '09:00',
      userTimezone: map['userTimezone'] ?? 'Etc/UTC',
      deliveryChannels: DeliveryChannels.fromMap(map['deliveryChannels']),
      userDeviceToken: map['userDeviceToken'], // Can be null
      userEmail: map['userEmail'], // Can be null
      userPhone: map['userPhone'], // Can be null
    );
  }

  // --- For State Management (optional but HIGHLY recommended) ---

  FixedReminder copyWith({
    String? id,
    String? userId,
    String? eventName,
    int? eventMonth,
    int? eventDay,
    int? eventYear,
    String? notifyTime,
    String? userTimezone,
    DeliveryChannels? deliveryChannels,
    String? userDeviceToken,
    String? userEmail,
    String? userPhone,
  }) {
    return FixedReminder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      eventName: eventName ?? this.eventName,
      eventMonth: eventMonth ?? this.eventMonth,
      eventDay: eventDay ?? this.eventDay,
      eventYear: eventYear ?? this.eventYear,
      notifyTime: notifyTime ?? this.notifyTime,
      userTimezone: userTimezone ?? this.userTimezone,
      deliveryChannels: deliveryChannels ?? this.deliveryChannels,
      userDeviceToken: userDeviceToken ?? this.userDeviceToken,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
    );
  }
}
