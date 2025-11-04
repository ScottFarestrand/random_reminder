import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_reminder/models/person.dart';
import 'package:random_reminder/services/firestore_service.dart';
import 'package:random_reminder/utilities/message_box.dart';
import 'package:random_reminder/utilities/date_helpers.dart';
import 'package:random_reminder/screens/add_edit_person.dart'; // NEW: Import AddEditPersonScreen

class PeopleListScreen extends StatefulWidget {
  final String userId;

  const PeopleListScreen({super.key, required this.userId});

  @override
  State<PeopleListScreen> createState() => _PeopleListScreenState();
}

class _PeopleListScreenState extends State<PeopleListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void dispose() {
    super.dispose();
  }

  /// Deletes a person from Firestore.
  Future<void> _deletePerson(String personId, String personName) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Person'),
            content: Text(
              'Are you sure you want to delete $personName? This cannot be undone.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirmed) return;

    setState(() {
      _isLoading = true;
    });
    try {
      await _firestoreService.deletePerson(widget.userId, personId);
      showMessageBox(
        context,
        'Person deleted successfully!',
        MessageType.success,
      );
    } catch (e) {
      showMessageBox(
        context,
        'Failed to delete person: ${e.toString()}',
        MessageType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Navigates to AddEditPersonScreen to edit the selected person.
  void _editPerson(Person person) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPersonScreen(
          userId: widget.userId,
          personToEdit: person, // Pass the person object for editing
        ),
      ),
    );
  }

  /// Navigates to AddEditPersonScreen to add a new person.
  void _navigateToAddPerson() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPersonScreen(userId: widget.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your People'),
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFE1BEE7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: StreamBuilder<List<Person>>(
                stream: _firestoreService.getPeopleStream(widget.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }
                  final people = snapshot.data ?? [];

                  if (people.isEmpty) {
                    return const Center(
                      child: Text(
                        'No people added yet. Tap the + button to add someone!',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: people.length,
                    itemBuilder: (context, index) {
                      final person = people[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        elevation: 2.0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${person.name} (${(person.type).capitalize()})',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Random Reminders: ${person.randomRemindersPerYear}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    if (person.fixedDates.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      const Text(
                                        'Fixed Events:',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: person.fixedDates.map((fd) {
                                          return Text(
                                            '• ${fd.type == 'custom' ? fd.customName : (fd.type).capitalize()}: ${DateFormat.yMd().format(fd.date)}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Column(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.green,
                                    ),
                                    onPressed: () => _editPerson(person),
                                    tooltip: 'Edit Person',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _deletePerson(person.id!, person.name),
                                    tooltip: 'Delete Person',
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddPerson,
        backgroundColor: const Color(0xFF2196F3),
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}
