import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:random_reminder/models/person.dart';
import 'package:random_reminder/models/user_preferences.dart'; // NEW

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // IMPORTANT: Ensure this APP_ID matches the one used in your Firebase Security Rules
  // and the one used in your Cloud Functions (functions/index.js)
  final String _appId =
      'default-app-id'; // Replace with your actual appId if different in rules

  // Get stream of user's document (for general user data, including preferences)
  Stream<DocumentSnapshot> getUserStream(String userId) {
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(userId)
        .snapshots();
  }

  // NEW: Get stream of user preferences
  Stream<UserPreferences> getUserPreferencesStream(String userId) {
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => UserPreferences.fromFirestore(snapshot));
  }

  // NEW: Update user preferences
  Future<void> updateUserPreferences(
    String userId,
    UserPreferences preferences,
  ) async {
    await _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(userId)
        .set(
          preferences.toFirestore(),
          SetOptions(
            merge: true,
          ), // Use merge: true to only update specified fields
        );
  }

  // Get stream of people for a specific user
  Stream<List<Person>> getPeopleStream(String userId) {
    return _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(userId)
        .collection('people')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((doc) => Person.fromFirestore(doc)).toList(),
        );
  }

  // Add a new person
  Future<void> addPerson(String userId, Person person) async {
    await _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(userId)
        .collection('people')
        .add(person.toFirestore());
  }

  // Update an existing person
  Future<void> updatePerson(String userId, Person person) async {
    if (person.id == null) {
      throw Exception("Cannot update person: ID is null.");
    }
    await _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(userId)
        .collection('people')
        .doc(person.id)
        .update(person.toFirestore()); // Use update for existing document
  }

  // Delete a person
  Future<void> deletePerson(String userId, String personId) async {
    await _db
        .collection('artifacts')
        .doc(_appId)
        .collection('users')
        .doc(userId)
        .collection('people')
        .doc(personId)
        .delete();
  }
}
