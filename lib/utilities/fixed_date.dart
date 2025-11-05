import 'package:cloud_firestore/cloud_firestore.dart';

// --- NEW: The expanded enum for all event types ---
enum FixedDateType {
  birthday,
  anniversary,
  employment,
  gotcha,
  memorial,
  sobriety,
  home,
  graduation,
  custom, // "Others" is now our catch-all
}

/// Helper to get a clean display name from the enum
extension FixedDateTypeExtension on FixedDateType {
  String get displayName {
    switch (this) {
      case FixedDateType.birthday:
        return 'Birthday';
      case FixedDateType.anniversary:
        return 'Anniversary';
      case FixedDateType.employment:
        return 'Employment';
      case FixedDateType.gotcha:
        return 'Gotcha Day';
      case FixedDateType.memorial:
        return 'In Memory Of';
      case FixedDateType.sobriety:
        return 'Sobriety Date';
      case FixedDateType.home:
        return 'Home Anniversary';
      case FixedDateType.graduation:
        return 'Graduation';
      case FixedDateType.custom:
        return 'Custom Event';
      default:
        return 'Event';
    }
  }
}

class FixedDate {
  // --- UPDATED: Use the enum ---
  final FixedDateType type;
  final String? customName;
  final DateTime date;
  final bool isRecurring;

  FixedDate({required this.type, this.customName, required this.date, required this.isRecurring});

  // --- For Firestore ---

  Map<String, dynamic> toMap() {
    return {
      // --- UPDATED: Save the enum's name (e.g., 'birthday') ---
      'type': type.name,
      'customName': customName,
      'date': Timestamp.fromDate(date),
      'isRecurring': isRecurring,
    };
  }

  factory FixedDate.fromMap(Map<String, dynamic>? map) {
    if (map == null) {
      throw ArgumentError("Cannot create FixedDate from null map");
    }
    return FixedDate(
      // --- UPDATED: Read the string and convert it back to an enum ---
      type: FixedDateType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => FixedDateType.custom, // Default to custom if not found
      ),
      customName: map['customName'],
      date: (map['date'] as Timestamp).toDate(),
      isRecurring: map['isRecurring'] ?? true,
    );
  }

  // --- Helper for copying ---
  FixedDate copyWith({FixedDateType? type, String? customName, DateTime? date, bool? isRecurring}) {
    return FixedDate(type: type ?? this.type, customName: customName ?? this.customName, date: date ?? this.date, isRecurring: isRecurring ?? this.isRecurring);
  }
}
