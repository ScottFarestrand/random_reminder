import 'package:flutter/foundation.dart';

/// A simple model class to hold the calculated reminder details
/// This is what your home screen list is built from.
class Reminder {
  final String personName;
  final String personType;
  final String eventType;
  final String? eventCustomName;
  final DateTime originalDate;
  final DateTime reminderDate;
  final String offset; // e.g., "On Day", "1 Week Before"

  Reminder({
    required this.personName,
    required this.personType,
    required this.eventType,
    this.eventCustomName,
    required this.originalDate,
    required this.reminderDate,
    required this.offset,
  });

  // You might want these for debugging, so I'll add them
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Reminder &&
        other.personName == personName &&
        other.personType == personType &&
        other.eventType == eventType &&
        other.eventCustomName == eventCustomName &&
        other.originalDate == originalDate &&
        other.reminderDate == reminderDate &&
        other.offset == offset;
  }

  @override
  int get hashCode {
    return personName.hashCode ^ personType.hashCode ^ eventType.hashCode ^ eventCustomName.hashCode ^ originalDate.hashCode ^ reminderDate.hashCode ^ offset.hashCode;
  }
}
