import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_reminder/models/person.dart';
import 'package:random_reminder/models/user_preferences.dart'; // NEW

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _appId = const String.fromEnvironment(
    'APP_ID',
    defaultValue: 'default-app-id',
  );

  // Helper to get user-specific collection reference
  CollectionReference _getPeopleCollectionRef(String userId) {
    return _db.collection('artifacts/$_appId/users/$userId/people');
  }

  // Helper to get user preferences document reference
  DocumentReference _getUserPreferencesDocRef(String userId) {
    return _db.collection('artifacts/$_appId/users').doc(userId);
  }

  // Get stream of people for a user
  Stream<List<Person>> getPeopleStream(String userId) {
    return _getPeopleCollectionRef(userId).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Person.fromDocument(doc)).toList();
    });
  }

  // Add a new person
  Future<void> addPerson(String userId, Person person) async {
    await _getPeopleCollectionRef(userId).add(person.toMap());
  }

  // Update an existing person
  Future<void> updatePerson(String userId, Person person) async {
    if (person.id == null) {
      throw Exception("Cannot update person without an ID.");
    }
    await _getPeopleCollectionRef(userId).doc(person.id).update(person.toMap());
  }

  // Delete a person
  Future<void> deletePerson(String userId, String personId) async {
    await _getPeopleCollectionRef(userId).doc(personId).delete();
  }

  // Get stream of user preferences
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _getUserPreferencesDocRef(userId).snapshots();
  }

  // Save/Update user preferences
  Future<void> saveUserPreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    await _getUserPreferencesDocRef(
      userId,
    ).set(preferences.toMap(), SetOptions(merge: true));
  }
}
