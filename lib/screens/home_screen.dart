import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart'; // For date formatting
import 'package:random_reminder/models/person.dart';
import 'package:random_reminder/models/user_preferences.dart';
import 'package:random_reminder/services/firestore_service.dart';
import 'package:random_reminder/utilities/date_helpers.dart';
import 'package:random_reminder/utilities/message_box.dart';
import 'package:random_reminder/services/twilio_service.dart';
import 'package:random_reminder/screens/settings_screen.dart'; // NEW: Import SettingsScreen

// Extension for String capitalization (kept here for home_screen's direct use)
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}'.replaceAll(
      '_',
      ' ',
    );
  }
}

class HomeScreen extends StatefulWidget {
  final String userId;
  final String? userEmail;
  final Function(String, MessageType) showMessage;

  const HomeScreen({
    super.key,
    required this.userId,
    this.userEmail,
    required this.showMessage,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TwilioService _twilioService = TwilioService();

  // Controllers for the form fields
  final TextEditingController _nameController = TextEditingController();
  String _personType = 'employee';
  int _randomRemindersPerYear = 1;
  List<FixedDate> _fixedDates =
      []; // List of fixed dates for the current person being added/edited

  String _fixedDateType = 'birthday';
  final TextEditingController _customFixedDateNameController =
      TextEditingController();
  DateTime? _selectedFixedDate;

  // Removed these from here, now they are in UserPreferences
  // String _reminderPreference = 'none';
  // final TextEditingController _contactEmailController = TextEditingController();
  // final TextEditingController _contactPhoneController = TextEditingController();

  // IMPORTANT: Replace with your Twilio numbers/emails. These are examples.
  final String _myTwilioSmsNumber = "+15017122661"; // Your Twilio phone number
  final String _myTwilioEmail =
      "verified_sender@example.com"; // Your verified Twilio SendGrid sender email

  bool _isLoading = false; // For general loading indicator

  // State for editing a person
  Person? _editingPerson; // Holds the person object if we are in edit mode

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customFixedDateNameController.dispose();
    // Removed disposal of contact controllers
    // _contactEmailController.dispose();
    // _contactPhoneController.dispose();
    super.dispose();
  }

  /// Adds a new fixed date event for the person being added/edited.
  void _addFixedDate() {
    if (_selectedFixedDate == null) {
      widget.showMessage(
        'Please select a date for the fixed event.',
        MessageType.error,
      );
      return;
    }
    if (_fixedDateType == 'custom' &&
        _customFixedDateNameController.text.trim().isEmpty) {
      widget.showMessage(
        'Please enter a name for your custom event.',
        MessageType.error,
      );
      return;
    }

    // Prevent duplicate birthday entries
    if (_fixedDateType == 'birthday' &&
        _fixedDates.any((fd) => fd.type == 'birthday')) {
      widget.showMessage(
        'A birthday has already been added for this person.',
        MessageType.error,
      );
      return;
    }

    setState(() {
      _fixedDates.add(
        FixedDate(
          type: _fixedDateType,
          date: _selectedFixedDate!,
          customName: _fixedDateType == 'custom'
              ? _customFixedDateNameController.text.trim()
              : null,
        ),
      );
    });
    widget.showMessage('Fixed event added to person!', MessageType.info);

    // Clear form fields after adding
    _fixedDateType = 'birthday';
    _customFixedDateNameController.clear();
    _selectedFixedDate = null;
  }

  /// Removes a fixed date event from the list.
  void _removeFixedDate(int index) {
    setState(() {
      _fixedDates.removeAt(index);
    });
  }

  /// Saves a person (either adds new or updates existing) to Firestore.
  Future<void> _savePerson() async {
    if (_nameController.text.trim().isEmpty ||
        _randomRemindersPerYear < 0 ||
        _fixedDates.isEmpty) {
      widget.showMessage(
        'Please fill in name, add at least one fixed event, and set random reminders.',
        MessageType.error,
      );
      return;
    }
    if (!_fixedDates.any((fd) => fd.type == 'birthday')) {
      widget.showMessage(
        'It is recommended to add a birthday for the person, but you can proceed with other fixed dates.',
        MessageType.info,
      );
    }

    // No longer validate contact info here, it's done in SettingsScreen

    setState(() {
      _isLoading = true;
    });

    try {
      // Regenerate random dates ONLY if randomRemindersPerYear or fixedDates have changed
      List<DateTime> newRandomDates;
      if (_editingPerson != null &&
          _editingPerson!.randomRemindersPerYear == _randomRemindersPerYear &&
          _fixedDates.length == _editingPerson!.fixedDates.length &&
          _fixedDates.every(
            (fd) => _editingPerson!.fixedDates.any(
              (efd) =>
                  efd.type == fd.type && efd.date.isAtSameMomentAs(fd.date),
            ),
          )) {
        // If fixed dates and random reminder count haven't changed, reuse existing random dates
        newRandomDates = _editingPerson!.randomDates;
      } else {
        // Otherwise, generate new random dates
        newRandomDates = DateHelpers.generateRandomDates(
          _fixedDates.map((fd) => fd.date).toList(),
          _randomRemindersPerYear,
        );
      }

      final personToSave = Person(
        id: _editingPerson
            ?.id, // Will be null for new person, existing ID for update
        name: _nameController.text.trim(),
        type: _personType,
        fixedDates: _fixedDates,
        randomRemindersPerYear: _randomRemindersPerYear,
        randomDates: newRandomDates,
        // Removed reminderPreference, contactEmail, contactPhone from Person object
      );

      if (_editingPerson == null) {
        // Add new person
        await _firestoreService.addPerson(widget.userId, personToSave);
        widget.showMessage('Person added successfully!', MessageType.success);
      } else {
        // Update existing person
        await _firestoreService.updatePerson(widget.userId, personToSave);
        widget.showMessage('Person updated successfully!', MessageType.success);
      }

      _clearForm(); // Clear form after saving
    } catch (e) {
      widget.showMessage(
        'Failed to save person: ${e.toString()}',
        MessageType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Deletes a person from Firestore.
  Future<void> _deletePerson(String personId) async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _firestoreService.deletePerson(widget.userId, personId);
      widget.showMessage('Person deleted successfully!', MessageType.success);
      _clearForm(); // Clear form if the deleted person was being edited
    } catch (e) {
      widget.showMessage(
        'Failed to delete person: ${e.toString()}',
        MessageType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Signs out the current user from Firebase.
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await FirebaseAuth.instance.signOut();
      widget.showMessage('Signed out successfully.', MessageType.info);
    } catch (e) {
      widget.showMessage('Sign out failed: ${e.toString()}', MessageType.error);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Sends a test reminder via Twilio.
  Future<void> _sendTestReminder(Person person) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch user's global preferences
      final userPreferencesSnapshot = await _firestoreService
          .getUserStream(widget.userId)
          .first;
      final UserPreferences userPreferences = UserPreferences.fromFirestore(
        userPreferencesSnapshot,
      );

      if (userPreferences.reminderPreference == 'none') {
        widget.showMessage(
          'No reminder preference set in Settings.',
          MessageType.info,
        );
        return;
      }

      String message =
          "This is a test reminder for ${person.name} from Random Reminders App!";

      if (userPreferences.reminderPreference == 'email' &&
          userPreferences.contactEmail != null &&
          userPreferences.contactEmail!.isNotEmpty) {
        await _twilioService.sendEmailReminder(
          userPreferences.contactEmail!,
          message,
          _myTwilioEmail,
        );
        widget.showMessage(
          'Test email sent to ${userPreferences.contactEmail}!',
          MessageType.success,
        );
      } else if (userPreferences.reminderPreference == 'sms' &&
          userPreferences.contactPhone != null &&
          userPreferences.contactPhone!.isNotEmpty) {
        await _twilioService.sendSmsReminder(
          userPreferences.contactPhone!,
          message,
          _myTwilioSmsNumber,
        );
        widget.showMessage(
          'Test SMS sent to ${userPreferences.contactPhone}!',
          MessageType.success,
        );
      } else {
        widget.showMessage(
          'Contact information missing for selected preference in Settings.',
          MessageType.error,
        );
      }
    } catch (e) {
      widget.showMessage(
        'Failed to send test reminder: ${e.toString()}',
        MessageType.error,
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Populates the form with data of the person to be edited.
  void _editPerson(Person person) {
    setState(() {
      _editingPerson = person;
      _nameController.text = person.name;
      _personType = person.type;
      _randomRemindersPerYear = person.randomRemindersPerYear;
      _fixedDates = List.from(person.fixedDates); // Create a mutable copy
      // Removed setting contact info, as it's now global
      // _reminderPreference = person.reminderPreference;
      // _contactEmailController.text = person.contactEmail ?? '';
      // _contactPhoneController.text = person.contactPhone ?? '';
    });
    widget.showMessage('Editing ${person.name}.', MessageType.info);
  }

  /// Clears the form and exits edit mode.
  void _clearForm() {
    setState(() {
      _editingPerson = null;
      _nameController.clear();
      _personType = 'employee';
      _randomRemindersPerYear = 1;
      _fixedDates = [];
      _fixedDateType = 'birthday';
      _customFixedDateNameController.clear();
      _selectedFixedDate = null;
      // Removed clearing contact info, as it's now global
      // _reminderPreference = 'none';
      // _contactEmailController.clear();
      // _contactPhoneController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Random Reminders'),
        backgroundColor: const Color(0xFF2196F3), // blue-600
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings), // NEW: Settings icon
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => SettingsScreen(
                    userId: widget.userId,
                    showMessage: widget.showMessage,
                  ),
                ),
              );
            },
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _signOut,
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFE3F2FD),
                    Color(0xFFE1BEE7),
                  ], // from-blue-100 to-purple-100
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
                  final upcomingReminders = DateHelpers.calculateReminders(
                    people,
                  );

                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your User ID: ${widget.userId}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                            ),
                          ),
                        ),
                        // Add/Edit Person Form
                        Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _editingPerson == null
                                          ? 'Add New Person'
                                          : 'Edit Person',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF37474F),
                                      ),
                                    ),
                                    if (_editingPerson != null)
                                      TextButton.icon(
                                        onPressed: _clearForm,
                                        icon: const Icon(
                                          Icons.cancel,
                                          color: Colors.red,
                                        ),
                                        label: const Text(
                                          'Cancel Edit',
                                          style: TextStyle(color: Colors.red),
                                        ),
                                      ),
                                  ],
                                ),
                                const Divider(height: 20, thickness: 1),
                                TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: "Person's Name",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  value: _personType,
                                  decoration: InputDecoration(
                                    labelText: 'Person Type',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  items: const [
                                    DropdownMenuItem(
                                      value: 'employee',
                                      child: Text('Employee'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'spouse',
                                      child: Text('Spouse'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'child',
                                      child: Text('Child'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'friend',
                                      child: Text('Friend'),
                                    ),
                                    DropdownMenuItem(
                                      value: 'customer',
                                      child: Text('Customer'),
                                    ),
                                  ],
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        _personType = value;
                                      });
                                    }
                                  },
                                ),
                                const SizedBox(height: 16),
                                // Fixed Dates Section
                                Container(
                                  padding: const EdgeInsets.all(16.0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: Colors.blue.shade200,
                                    ),
                                    borderRadius: BorderRadius.circular(8.0),
                                    color: Colors.blue.shade50,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Fixed Events for this Person',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF1565C0),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      if (_fixedDates.isNotEmpty)
                                        Column(
                                          children: _fixedDates.asMap().entries.map((
                                            entry,
                                          ) {
                                            int idx = entry.key;
                                            FixedDate fd = entry.value;
                                            return Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4.0,
                                                  ),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Text(
                                                      '${fd.type == 'custom' ? fd.customName : fd.type.capitalize()}: ${DateFormat.yMd().format(fd.date)}',
                                                      style: const TextStyle(
                                                        fontSize: 14,
                                                      ),
                                                    ),
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.close,
                                                      size: 18,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () =>
                                                        _removeFixedDate(idx),
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        )
                                      else
                                        const Text(
                                          'No fixed events added yet. Add one below.',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      const SizedBox(height: 16),
                                      // Fixed Date Input
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            'Add Fixed Event',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          DropdownButtonFormField<String>(
                                            value: _fixedDateType,
                                            decoration: InputDecoration(
                                              labelText: 'Event Type',
                                              border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                            ),
                                            items: const [
                                              DropdownMenuItem(
                                                value: 'birthday',
                                                child: Text('Birthday'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'anniversary',
                                                child: Text('Anniversary'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'work_anniversary',
                                                child: Text('Work Anniversary'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'gotcha_day',
                                                child: Text('Gotcha Day'),
                                              ),
                                              DropdownMenuItem(
                                                value: 'custom',
                                                child: Text('Custom'),
                                              ),
                                            ],
                                            onChanged: (value) {
                                              if (value != null) {
                                                setState(() {
                                                  _fixedDateType = value;
                                                  if (value != 'custom') {
                                                    _customFixedDateNameController
                                                        .clear();
                                                  }
                                                });
                                              }
                                            },
                                          ),
                                          if (_fixedDateType == 'custom') ...[
                                            const SizedBox(height: 16),
                                            TextField(
                                              controller:
                                                  _customFixedDateNameController,
                                              decoration: InputDecoration(
                                                labelText: 'Custom Event Name',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.0,
                                                      ),
                                                ),
                                                hintText:
                                                    'e.g., Pet Adoption Day',
                                              ),
                                            ),
                                          ],
                                          const SizedBox(height: 16),
                                          InkWell(
                                            onTap: () async {
                                              final DateTime? picked =
                                                  await showDatePicker(
                                                    context: context,
                                                    initialDate:
                                                        _selectedFixedDate ??
                                                        DateTime.now(),
                                                    firstDate: DateTime(1900),
                                                    lastDate: DateTime(2100),
                                                  );
                                              if (picked != null &&
                                                  picked !=
                                                      _selectedFixedDate) {
                                                setState(() {
                                                  _selectedFixedDate = picked;
                                                });
                                              }
                                            },
                                            child: InputDecorator(
                                              decoration: InputDecoration(
                                                labelText: 'Date',
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                        8.0,
                                                      ),
                                                ),
                                                suffixIcon: const Icon(
                                                  Icons.calendar_today,
                                                ),
                                              ),
                                              baseStyle: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                              child: Text(
                                                _selectedFixedDate == null
                                                    ? 'Select Date'
                                                    : DateFormat.yMd().format(
                                                        _selectedFixedDate!,
                                                      ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 16),
                                          ElevatedButton(
                                            onPressed: _addFixedDate,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.green[600],
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(8.0),
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 12,
                                                  ),
                                              minimumSize: const Size(
                                                double.infinity,
                                                40,
                                              ),
                                            ),
                                            child: const Text(
                                              'Add Fixed Event',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                // Random Reminders
                                TextField(
                                  controller: TextEditingController(
                                    text: _randomRemindersPerYear.toString(),
                                  ),
                                  decoration: InputDecoration(
                                    labelText:
                                        'Number of Random Reminders per Year',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onChanged: (value) {
                                    setState(() {
                                      _randomRemindersPerYear =
                                          int.tryParse(value) ?? 0;
                                    });
                                  },
                                ),
                                const SizedBox(height: 24),
                                // Removed Reminder Preference Section from here
                                ElevatedButton(
                                  onPressed: _savePerson,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2196F3),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    minimumSize: const Size(
                                      double.infinity,
                                      50,
                                    ),
                                  ),
                                  child: Text(
                                    _editingPerson == null
                                        ? 'Add Person'
                                        : 'Update Person',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Added People List
                        Card(
                          margin: const EdgeInsets.only(bottom: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Added People',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF37474F),
                                  ),
                                ),
                                const Divider(height: 20, thickness: 1),
                                if (people.isEmpty)
                                  const Text(
                                    'No people added yet. Add someone above!',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: people.length,
                                    itemBuilder: (context, index) {
                                      final person = people[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        elevation: 2.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      '${person.name} (${person.type.capitalize()})',
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Random Reminders: ${person.randomRemindersPerYear}',
                                                      style: const TextStyle(
                                                        fontSize: 13,
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                    if (person
                                                        .fixedDates
                                                        .isNotEmpty) ...[
                                                      const SizedBox(height: 8),
                                                      const Text(
                                                        'Fixed Events:',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w600,
                                                        ),
                                                      ),
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: person.fixedDates.map((
                                                          fd,
                                                        ) {
                                                          return Text(
                                                            '• ${fd.type == 'custom' ? fd.customName : fd.type.capitalize()}: ${DateFormat.yMd().format(fd.date)}',
                                                            style:
                                                                const TextStyle(
                                                                  fontSize: 12,
                                                                  color: Colors
                                                                      .grey,
                                                                ),
                                                          );
                                                        }).toList(),
                                                      ),
                                                    ],
                                                    // Removed reminder preference display from here
                                                  ],
                                                ),
                                              ),
                                              // Action buttons for each person
                                              Column(
                                                children: [
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.edit,
                                                      color: Colors.green,
                                                    ),
                                                    onPressed: () =>
                                                        _editPerson(person),
                                                    tooltip: 'Edit Person',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.send,
                                                      color: Colors.blue,
                                                    ),
                                                    onPressed: () =>
                                                        _sendTestReminder(
                                                          person,
                                                        ),
                                                    tooltip:
                                                        'Send Test Reminder',
                                                  ),
                                                  IconButton(
                                                    icon: const Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                    ),
                                                    onPressed: () =>
                                                        _deletePerson(
                                                          person.id!,
                                                        ),
                                                    tooltip: 'Delete Person',
                                                  ),
                                                ],
                                              ),
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

                        // Upcoming Reminders List
                        Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          elevation: 4.0,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Upcoming Reminders',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF37474F),
                                  ),
                                ),
                                const Divider(height: 20, thickness: 1),
                                if (upcomingReminders.isEmpty)
                                  const Text(
                                    'No upcoming reminders.',
                                    style: TextStyle(color: Colors.grey),
                                  )
                                else
                                  ListView.builder(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    itemCount: upcomingReminders.length,
                                    itemBuilder: (context, index) {
                                      final reminder = upcomingReminders[index];
                                      return Card(
                                        margin: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        elevation: 1.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                        ),
                                        color: Colors.blue.shade50,
                                        child: Padding(
                                          padding: const EdgeInsets.all(12.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                '${reminder.personName} - ${reminder.personType.capitalize()}',
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFF1976D2),
                                                ),
                                              ),
                                              Text(
                                                'Event: ${reminder.eventType == 'custom' ? reminder.eventCustomName : reminder.eventType.capitalize()}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                'Reminder Date: ${DateFormat.yMd().format(reminder.reminderDate)}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                'Original Event Date: ${DateFormat.yMd().format(reminder.originalDate)} (${reminder.offset})',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
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
