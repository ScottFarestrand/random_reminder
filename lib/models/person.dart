import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_reminder/utilities/fixed_date.dart';

// Model for a Person
class Person {
  final String? id;
  final String name;
  final String type;
  final List<FixedDate> fixedDates;
  final int randomRemindersPerYear;
  final List<DateTime> randomDates;
  final DateTime createdAt;

  Person({
    this.id,
    required this.name,
    required this.type,
    required this.fixedDates,
    required this.randomRemindersPerYear,
    required this.randomDates,
    required this.createdAt,
  });

  // copyWith method for immutability and updating specific fields
  Person copyWith({
    String? id,
    String? name,
    String? type,
    List<FixedDate>? fixedDates,
    int? randomRemindersPerYear,
    List<DateTime>? randomDates,
    DateTime? createdAt,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      fixedDates: fixedDates ?? this.fixedDates,
      randomRemindersPerYear:
          randomRemindersPerYear ?? this.randomRemindersPerYear,
      randomDates: randomDates ?? this.randomDates,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  // Convert a Person object to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'fixedDates': fixedDates
          .map((fd) => fd.toMap())
          .toList(), // Convert FixedDate objects
      'randomRemindersPerYear': randomRemindersPerYear,
      'randomDates': randomDates
          .map((date) => Timestamp.fromDate(date))
          .toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create a Person object from a Firestore DocumentSnapshot
  factory Person.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Person(
      id: doc.id,
      name: data['name'] ?? '',
      type: data['type'] ?? 'employee',
      fixedDates:
          (data['fixedDates'] as List<dynamic>?)
              ?.map((map) => FixedDate.fromMap(map as Map<String, dynamic>))
              .toList() ??
          [],
      randomRemindersPerYear: data['randomRemindersPerYear'] ?? 0,
      randomDates:
          (data['randomDates'] as List<dynamic>?)
              ?.map((ts) => (ts as Timestamp).toDate())
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}

// Model for a Reminder
class Reminder {
  final String id;
  final String personName;
  final String personType;
  final DateTime originalDate;
  final DateTime reminderDate;
  final String eventType;
  final String? eventCustomName;
  final String offset;

  Reminder({
    required this.id,
    required this.personName,
    required this.personType,
    required this.originalDate,
    required this.reminderDate,
    required this.eventType,
    this.eventCustomName,
    required this.offset,
  });
}
