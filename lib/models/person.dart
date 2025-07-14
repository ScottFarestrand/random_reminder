import 'package:cloud_firestore/cloud_firestore.dart';

class FixedDate {
  final String type;
  final DateTime date;
  final String? customName;

  FixedDate({required this.type, required this.date, this.customName});

  factory FixedDate.fromMap(Map<String, dynamic> map) {
    return FixedDate(
      type: map['type'] as String,
      date: (map['date'] as Timestamp).toDate(),
      customName: map['customName'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'date': Timestamp.fromDate(date),
      'customName': customName,
    };
  }
}

class Person {
  String? id; // Firestore document ID
  final String name;
  final String type;
  final List<FixedDate> fixedDates;
  final int randomRemindersPerYear;
  final List<DateTime> randomDates; // Stored as DateTime objects
  final String reminderPreference; // 'none', 'email', 'sms'
  final String? contactEmail;
  final String? contactPhone;

  Person({
    this.id,
    required this.name,
    required this.type,
    required this.fixedDates,
    required this.randomRemindersPerYear,
    required this.randomDates,
    this.reminderPreference = 'none', // Default to none
    this.contactEmail,
    this.contactPhone,
  });

  factory Person.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Person(
      id: doc.id,
      name: data['name'] as String,
      type: data['type'] as String,
      fixedDates:
          (data['fixedDates'] as List<dynamic>?)
              ?.map((fd) => FixedDate.fromMap(fd as Map<String, dynamic>))
              .toList() ??
          [],
      randomRemindersPerYear: data['randomRemindersPerYear'] as int,
      randomDates:
          (data['randomDates'] as List<dynamic>?)
              ?.map((rd) => (rd as Timestamp).toDate())
              .toList() ??
          [],
      reminderPreference: data['reminderPreference'] as String? ?? 'none',
      contactEmail: data['contactEmail'] as String?,
      contactPhone: data['contactPhone'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'type': type,
      'fixedDates': fixedDates.map((fd) => fd.toMap()).toList(),
      'randomRemindersPerYear': randomRemindersPerYear,
      'randomDates': randomDates.map((rd) => Timestamp.fromDate(rd)).toList(),
      'reminderPreference': reminderPreference,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

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
