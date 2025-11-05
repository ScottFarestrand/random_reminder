import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:random_reminder/models/person.dart';
import 'package:random_reminder/services/firestore_service.dart';
import 'package:random_reminder/utilities/date_helpers.dart';
import 'package:random_reminder/utilities/message_box.dart';
import 'package:random_reminder/screens/settings_screen.dart'; // NEW: Import SettingsScreen
import 'package:random_reminder/screens/people_screen.dart'; // NEW: Import PeopleListScreen
import 'package:random_reminder/models/reminder.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({super.key, required this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
      showMessageBox(context, 'Signed out successfully.', MessageType.info);
    } catch (e) {
      showMessageBox(context, 'Sign out failed: ${e.toString()}', MessageType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Reminders'),
        backgroundColor: const Color(0xFF2196F3), // blue-600
        foregroundColor: Colors.white,
        actions: [
          // Icon to navigate to PeopleListScreen
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => PeopleListScreen(userId: widget.userId)));
            },
            tooltip: 'View All People',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    userId: widget.userId,
                    showMessage: (text, type) => showMessageBox(context, text, type), // Pass showMessageBox
                  ),
                ),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(icon: const Icon(Icons.logout), onPressed: _signOut, tooltip: 'Sign Out'),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE3F2FD), Color(0xFFE1BEE7)], // from-blue-100 to-purple-100
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
                  final allReminders = DateHelpers.calculateReminders(people); // Get all reminders

                  // Filter to get only the actual event dates (reminders with offset 'On Day')
                  final allEvents = allReminders.where((r) => r.offset == 'On Day').toList();

                  // Group events by person and find the next event for each
                  final Map<String, Reminder> nextEventPerPerson = {};
                  final DateTime normalizedToday = DateHelpers.normalizeDate(DateTime.now());

                  for (var event in allEvents) {
                    final DateTime eventDateOnly = DateHelpers.normalizeDate(event.originalDate);
                    final Reminder? existingEvent = nextEventPerPerson[event.personName];

                    if (existingEvent == null) {
                      // If no event for this person yet, add it
                      nextEventPerPerson[event.personName] = event;
                    } else {
                      final DateTime existingEventDateOnly = DateHelpers.normalizeDate(existingEvent.originalDate);

                      // Logic to pick the "next" event:
                      // 1. If the new event is in the future and the existing is in the past, pick new.
                      // 2. If both are in the future, pick the earlier one.
                      // 3. If new is today and existing is past, pick new.
                      if (eventDateOnly.isAfter(normalizedToday) && existingEventDateOnly.isBefore(normalizedToday)) {
                        nextEventPerPerson[event.personName] = event;
                      } else if (eventDateOnly.isAfter(normalizedToday) && existingEventDateOnly.isAfter(normalizedToday)) {
                        if (eventDateOnly.isBefore(existingEventDateOnly)) {
                          nextEventPerPerson[event.personName] = event;
                        }
                      } else if (eventDateOnly.isAtSameMomentAs(normalizedToday) && existingEventDateOnly.isBefore(normalizedToday)) {
                        nextEventPerPerson[event.personName] = event;
                      }
                    }
                  }

                  // Convert map values to a list and sort by date
                  final upcomingEvents = nextEventPerPerson.values.toList();
                  upcomingEvents.sort((a, b) => a.originalDate.compareTo(b.originalDate));

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          elevation: 4.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Your User ID: ${widget.userId}', style: const TextStyle(fontSize: 12, color: Colors.blueGrey)),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),

                        // Upcoming Events List
                        Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                          elevation: 4.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Upcoming Events',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF37474F)),
                                ),
                                const Divider(height: 20, thickness: 1),
                                if (upcomingEvents.isEmpty)
                                  const Text('No upcoming events.', style: TextStyle(color: Colors.grey))
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: upcomingEvents.length,
                                    itemBuilder: (context, index) {
                                      final event = upcomingEvents[index];
                                      // Determine event display name
                                      final String eventDisplayName = event.eventType == 'custom' ? event.eventCustomName ?? 'Custom Event' : (event.eventType).capitalize();

                                      return Card(
                                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                                        elevation: 1.0,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                        color: Colors.blue.shade50,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${event.personName} - ${(event.personType).capitalize()}',
                                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1976D2)),
                                              ),
                                              Text('Event: $eventDisplayName', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                              Text('Date: ${DateFormat.yMd().format(event.originalDate)}', style: const TextStyle(fontSize: 14, color: Colors.grey)),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
