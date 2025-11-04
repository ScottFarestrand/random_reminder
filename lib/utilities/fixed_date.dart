import 'package:cloud_firestore/cloud_firestore.dart';

// Model for a Fixed Date (e.g., Birthday, Anniversary, Custom)
class FixedDate {
  final String type; // e.g., 'birthday', 'anniversary', 'custom'
  final DateTime date;
  final String? customName; // For 'custom' type

  FixedDate({required this.type, required this.date, this.customName});

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'date': Timestamp.fromDate(date),
      'customName': customName,
    };
  }

  factory FixedDate.fromMap(Map<String, dynamic> map) {
    return FixedDate(
      type: map['type'] ?? 'custom',
      date: (map['date'] as Timestamp).toDate(),
      customName: map['customName'],
    );
  }
}
