import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_reminder/models/person.dart';
import 'package:random_reminder/services/firestore_service.dart';
import 'package:random_reminder/utilities/message_box.dart';
import 'package:random_reminder/utilities/date_helpers.dart'; // For StringExtension and DateHelpers
import 'package:random_reminder/utilities/fixed_date.dart';

class AddEditPersonScreen extends StatefulWidget {
  final String userId;
  final Person? personToEdit; // Optional: if provided, we are in edit mode

  const AddEditPersonScreen({
    super.key,
    required this.userId,
    this.personToEdit,
  });

  @override
  State<AddEditPersonScreen> createState() => _AddEditPersonScreenState();
}

class _AddEditPersonScreenState extends State<AddEditPersonScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form field controllers and state
  final TextEditingController _nameController = TextEditingController();
  String _personType = 'employee';
  int _randomRemindersPerYear = 1;
  List<FixedDate> _fixedDates =
      []; // List of fixed dates for the current person being added/edited

  String _fixedDateType = 'birthday';
  final TextEditingController _customFixedDateNameController =
      TextEditingController();
  DateTime? _selectedFixedDate;

  Person? _editingPerson; // Internal state to hold the person being edited

  @override
  void initState() {
    super.initState();
    // If a personToEdit is passed, populate the form fields
    if (widget.personToEdit != null) {
      _editingPerson = widget.personToEdit;
      _nameController.text = _editingPerson!.name;
      _personType = _editingPerson!.type;
      _randomRemindersPerYear = _editingPerson!.randomRemindersPerYear;
      _fixedDates = List.from(
        _editingPerson!.fixedDates,
      ); // Create a mutable copy
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _customFixedDateNameController.dispose();
    super.dispose();
  }

  /// Adds a new fixed date event for the person being added/edited.
  void _addFixedDate() {
    if (_selectedFixedDate == null) {
      showMessageBox(
        context,
        'Please select a date for the fixed event.',
        MessageType.error,
      );
      return;
    }
    if (_fixedDateType == 'custom' &&
        _customFixedDateNameController.text.trim().isEmpty) {
      showMessageBox(
        context,
        'Please enter a name for your custom event.',
        MessageType.error,
      );
      return;
    }

    // Prevent duplicate birthday entries
    if (_fixedDateType == 'birthday' &&
        _fixedDates.any((fd) => fd.type == 'birthday')) {
      showMessageBox(
        context,
        'A birthday has already been added for this person.',
        MessageType.info,
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
    showMessageBox(context, 'Fixed event added to person!', MessageType.info);

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
    if (!_formKey.currentState!.validate()) {
      return; // Form validation failed
    }
    if (_fixedDates.isEmpty) {
      showMessageBox(
        context,
        'Please add at least one fixed event for the person.',
        MessageType.error,
      );
      return;
    }
    if (!_fixedDates.any((fd) => fd.type == 'birthday')) {
      showMessageBox(
        context,
        'It is recommended to add a birthday for the person, but you can proceed with other fixed dates.',
        MessageType.info,
      );
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Generate random dates using the updated logic and fixedDates
      final randomDates = DateHelpers.generateRandomDates(
        numReminders: _randomRemindersPerYear,
        fixedDates: _fixedDates,
      );

      final personToSave = Person(
        id: _editingPerson
            ?.id, // Will be null for new person, existing ID for update
        name: _nameController.text.trim(),
        type: _personType,
        fixedDates: _fixedDates,
        randomRemindersPerYear: _randomRemindersPerYear,
        randomDates: randomDates, // Use the newly generated random dates
        createdAt:
            _editingPerson?.createdAt ??
            DateTime.now(), // Preserve creation date if editing
      );

      if (_editingPerson == null) {
        // Add new person
        await _firestoreService.addPerson(widget.userId, personToSave);
        showMessageBox(
          context,
          'Person added successfully!',
          MessageType.success,
        );
      } else {
        // Update existing person
        await _firestoreService.updatePerson(widget.userId, personToSave);
        showMessageBox(
          context,
          'Person updated successfully!',
          MessageType.success,
        );
      }

      Navigator.pop(context); // Go back to PeopleListScreen after saving
    } catch (e) {
      showMessageBox(
        context,
        'Failed to save person: ${e.toString()}',
        MessageType.error,
      );
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
        title: Text(_editingPerson == null ? 'Add New Person' : 'Edit Person'),
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 0.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    elevation: 4.0,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: "Person's Name",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter a name.';
                              }
                              return null;
                            },
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
                              border: Border.all(color: Colors.blue.shade200),
                              borderRadius: BorderRadius.circular(8.0),
                              color: Colors.blue.shade50,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4.0,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                '${fd.type == 'custom' ? fd.customName : (fd.type).capitalize()}: ${DateFormat.yMd().format(fd.date)}',
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
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
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
                                      TextFormField(
                                        controller:
                                            _customFixedDateNameController,
                                        decoration: InputDecoration(
                                          labelText: 'Custom Event Name',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
                                              8.0,
                                            ),
                                          ),
                                          hintText: 'e.g., Pet Adoption Day',
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 16),
                                    InkWell(
                                      onTap: () async {
                                        final DateTime?
                                        picked = await showDatePicker(
                                          context: context,
                                          initialDate:
                                              _selectedFixedDate ??
                                              DateTime.now(),
                                          firstDate: DateTime(1900),
                                          lastDate: DateTime(
                                            2100,
                                          ), // Allow future dates for fixed events
                                        );
                                        if (picked != null &&
                                            picked != _selectedFixedDate) {
                                          setState(() {
                                            _selectedFixedDate = picked;
                                          });
                                        }
                                      },
                                      child: InputDecorator(
                                        decoration: InputDecoration(
                                          labelText: 'Date',
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(
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
                                        backgroundColor: Colors.green[600],
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            8.0,
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        minimumSize: const Size(
                                          double.infinity,
                                          40,
                                        ),
                                      ),
                                      child: const Text('Add Fixed Event'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            initialValue: _randomRemindersPerYear.toString(),
                            decoration: InputDecoration(
                              labelText:
                                  'Number of Random Reminders per Year (Max 8)',
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
                            validator: (value) {
                              if (value == null ||
                                  int.tryParse(value) == null ||
                                  int.parse(value) < 0 ||
                                  int.parse(value) > 8) {
                                return 'Please enter a number between 0 and 8.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _savePerson,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2196F3),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              minimumSize: const Size(double.infinity, 50),
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
                ),
              ),
            ),
    );
  }
}
