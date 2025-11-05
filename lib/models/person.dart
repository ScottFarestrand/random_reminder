import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_reminder/utilities/fixed_date.dart'; // Make sure this path is right

class Person {
  final String? id; // The document ID
  final String name;

  // 'type' is GONE.

  final int randomRemindersPerYear; // We now just rely on this value
  final List<FixedDate> fixedDates;
  final DateTime createdAt;
  final DateTime? nextRandomReminderDate;

  Person({this.id, required this.name, required this.randomRemindersPerYear, required this.fixedDates, required this.createdAt, this.nextRandomReminderDate});

  // --- UPDATED fromDocument ---
  factory Person.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<FixedDate> fixedDatesList = (data['fixedDates'] as List<dynamic>?)?.map((item) => FixedDate.fromMap(item as Map<String, dynamic>)).toList() ?? [];

    Timestamp? nextDateTimestamp = data['nextRandomReminderDate'] as Timestamp?;

    return Person(
      id: doc.id,
      name: data['name'] ?? '',
      // 'type' is GONE.
      randomRemindersPerYear: data['randomRemindersPerYear'] ?? 0,
      fixedDates: fixedDatesList,
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
      nextRandomReminderDate: nextDateTimestamp?.toDate(),
    );
  }

  // --- UPDATED toMap ---
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      // 'type' is GONE.
      'randomRemindersPerYear': randomRemindersPerYear,
      'fixedDates': fixedDates.map((date) => date.toMap()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'nextRandomReminderDate': nextRandomReminderDate == null ? null : Timestamp.fromDate(nextRandomReminderDate!),
    };
  }
}
