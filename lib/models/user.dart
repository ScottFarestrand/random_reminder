import 'package:cloud_firestore/cloud_firestore.dart';

class RRUser{
  final String firstName;
  final String lastName;
  final DateTime birthDate;

  RRUser({
    required this.firstName,
    required this.lastName,
    required this.birthDate,
});
  Map<String, dynamic> toJson() => {
    'FirstName': firstName,
    'LastName': lastName,
    'BirthDate': birthDate,
  };

  static RRUser fromJson(Map<String, dynamic> json) => RRUser(
    firstName: json['FirstName'],
    lastName: json['LastName'],
    birthDate: (json['BirthDate'] as Timestamp).toDate(),
  );
}