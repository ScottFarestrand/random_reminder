// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

import '../constants/globals.dart';

class Relationship {
  final String firstName;
  final String lastName;
  // final DateTime anniversary;
  final String anniversaryType;
  // final DateTime birthDate;
  final int randomReminders;
  final String relationshipType;
  final String userId;
  final String docId;

  Relationship({
    required this.firstName,
    required this.lastName,
    // required this.anniversary,
    required this.anniversaryType,
    // required this.birthDate,
    required this.randomReminders,
    required this.relationshipType,
    required this.userId,
    required this.docId,
  });
  Map<String, dynamic> toJson() => {
    gFirstName: firstName,
    gLastName: lastName,
    // gAnniversary: anniversary,
    gAnniversaryType: anniversaryType,
    // gBirthDate: birthDate,
    gRandomReminders: randomReminders,
    gRelationshipType: relationshipType,
    gUserId: userId,
    // gDocId: docId,

  };

  static Relationship fromJson(docid, Map<String, dynamic> json) => Relationship(
    firstName: json[gFirstName],
    lastName: json[gLastName],
    // anniversary: json[gAnniversary],
    anniversaryType: json[gAnniversaryType],
    // birthDate: json[gBirthDate],
    randomReminders: json[gRandomReminders],
    relationshipType: json[gRelationshipType],
    userId: json[gUserId],
    docId: docid,
  );

}