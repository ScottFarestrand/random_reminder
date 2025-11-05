import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_reminder/utilities/fixed_date.dart'; // Make sure this path is right

class Person {
  final String? id; // The document ID
  final String name;
  final String type; // 'random' or 'fixed'
  final int randomRemindersPerYear;
  final List<FixedDate> fixedDates;
  final List<DateTime> randomDates; // You had this in your model
  final DateTime createdAt; // You had this in your model

  Person({this.id, required this.name, required this.type, required this.randomRemindersPerYear, required this.fixedDates, required this.randomDates, required this.createdAt});

  // --- THE FIX IS HERE ---
  /// Creates a Person object from a Firestore document snapshot.
  factory Person.fromDocument(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Convert List<dynamic> from Firestore to List<FixedDate>
    List<FixedDate> fixedDatesList = (data['fixedDates'] as List<dynamic>?)?.map((item) => FixedDate.fromMap(item as Map<String, dynamic>)).toList() ?? [];

    // Convert List<dynamic> from Firestore to List<DateTime>
    List<DateTime> randomDatesList = (data['randomDates'] as List<dynamic>?)?.map((item) => (item as Timestamp).toDate()).toList() ?? [];

    return Person(
      id: doc.id, // <-- THIS IS THE KEY. We get the ID from the doc itself.
      name: data['name'] ?? '',
      type: data['type'] ?? 'random',
      randomRemindersPerYear: data['randomRemindersPerYear'] ?? 0,
      fixedDates: fixedDatesList,
      randomDates: randomDatesList,
      createdAt: (data['createdAt'] as Timestamp? ?? Timestamp.now()).toDate(),
    );
  }

  /// Converts this Person object into a Map to save in Firestore.
  Map<String, dynamic> toMap() {
    return {
      // We NEVER save the 'id' field back into the document data.
      'name': name,
      'type': type,
      'randomRemindersPerYear': randomRemindersPerYear,
      // Convert list of objects to list of maps
      'fixedDates': fixedDates.map((date) => date.toMap()).toList(),
      'randomDates': randomDates.map((date) => Timestamp.fromDate(date)).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
