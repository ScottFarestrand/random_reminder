import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:random_reminder/models/person.dart';
import 'package:random_reminder/utilities/fixed_date.dart';
import 'package:random_reminder/utilities/date_helpers.dart'; // For .capitalize()
import 'dart:math'; // For random date calculation
import 'package:random_reminder/widgets/fixed_date_dialog.dart'; // Import dialog

// 'PersonType' enum is now GONE.

class AddEditPersonScreen extends StatefulWidget {
  final String userId;
  final Function(String, Color) showMessage;
  final Person? personToEdit;

  const AddEditPersonScreen({super.key, required this.userId, required this.showMessage, this.personToEdit});

  @override
  _AddEditPersonScreenState createState() => _AddEditPersonScreenState();
}

class _AddEditPersonScreenState extends State<AddEditPersonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  // State variables
  // _personType is GONE.
  double _randomRemindersPerYear = 0; // Default to 0
  List<FixedDate> _fixedDates = [];
  DateTime? _nextRandomDate;

  @override
  void initState() {
    super.initState();
    if (widget.personToEdit != null) {
      final person = widget.personToEdit!;
      _nameController.text = person.name;
      // 'type' logic is GONE.
      _randomRemindersPerYear = person.randomRemindersPerYear.toDouble();
      _fixedDates = List<FixedDate>.from(person.fixedDates);
      _nextRandomDate = person.nextRandomReminderDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// --- UPDATED SAVE FUNCTION ---
  void _savePerson() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // --- NEW: Simplified Calculation Logic ---
      if (_randomRemindersPerYear > 0) {
        // Only calculate a new date if one doesn't already exist.
        if (_nextRandomDate == null) {
          print("Calculating first random reminder date...");
          _nextRandomDate = _calculateNextRandomDate(remindersPerYear: _randomRemindersPerYear.toInt(), personFixedDates: _fixedDates);
        }
      } else {
        // If slider is at 0, wipe any pending random date.
        _nextRandomDate = null;
      }

      // Create the new Person object
      final person = Person(
        id: widget.personToEdit?.id,
        name: _nameController.text,
        // 'type' is GONE.
        randomRemindersPerYear: _randomRemindersPerYear.toInt(),
        fixedDates: _fixedDates,
        createdAt: widget.personToEdit?.createdAt ?? DateTime.now(),
        nextRandomReminderDate: _nextRandomDate,
      );

      try {
        final collection = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('people');

        if (person.id == null) {
          await collection.add(person.toMap());
          if (!mounted) return;
          widget.showMessage('Person added successfully', Colors.green);
        } else {
          await collection.doc(person.id).update(person.toMap());
          if (!mounted) return;
          widget.showMessage('Person updated successfully', Colors.green);
        }
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        widget.showMessage('Error saving person: $e', Colors.red);
      }
    }
  }

  /// --- NEW: Helper function to call the dialog for ADDING ---
  void _onAddEventPressed({required bool isRecurring}) async {
    // We pass the isRecurring flag to the dialog
    final FixedDate? newDate = await showDialog<FixedDate>(
      context: context,
      builder: (BuildContext dialogContext) {
        // We'll need to update the dialog to accept this new param
        return FixedDateDialog(
          // dateToEdit: null, // Implicitly null
          // isRecurringForNew: isRecurring, // We will add this
        );
      },
    );

    // This part is a placeholder for our *next* step.
    // For now, I'll just show the TODO
    widget.showMessage('TODO: Update Dialog to accept isRecurring', Colors.blue);

    // This is what the code WILL be:
    // if (newDate != null) {
    //   setState(() {
    //     _fixedDates.add(newDate);
    //   });
    // }
  }

  /// --- UPDATED: Helper function to call the dialog for EDITING ---
  void _onEditEventPressed(FixedDate dateToEdit, int index) async {
    final FixedDate? editedDate = await showDialog<FixedDate>(
      context: context,
      builder: (BuildContext dialogContext) {
        // This call is unchanged. The dialog will get its state
        // from the dateToEdit object.
        return FixedDateDialog(dateToEdit: dateToEdit);
      },
    );

    if (editedDate != null) {
      setState(() {
        _fixedDates[index] = editedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.personToEdit == null ? 'Add Person' : 'Edit Person')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // --- MOVED: Random Section is now always visible ---
              _buildRandomSection(),

              const Divider(height: 32),

              // --- UPDATED: Fixed Section ---
              _buildFixedSection(),

              const SizedBox(height: 24),
              Center(
                child: ElevatedButton(onPressed: _savePerson, child: Text(widget.personToEdit == null ? 'Add Person' : 'Save Changes')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// --- Random Reminders Section (Unchanged) ---
  Widget _buildRandomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Random Reminders', style: Theme.of(context).textTheme.titleMedium),
        Text('Approx. ${_randomRemindersPerYear.toInt()} times per year', style: Theme.of(context).textTheme.bodySmall),
        Slider(
          value: _randomRemindersPerYear,
          min: 0, // <-- Now starts at 0
          max: 12,
          divisions: 12, // <-- Now 12 divisions
          label: _randomRemindersPerYear.toInt().toString(),
          onChanged: (double value) {
            setState(() {
              _randomRemindersPerYear = value;
            });
          },
        ),
      ],
    );
  }

  /// --- UPDATED: Fixed Reminders Section ---
  Widget _buildFixedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fixed Events', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        if (_fixedDates.isEmpty) const Center(child: Text('No fixed events added.')),

        // --- List of existing fixed dates ---
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _fixedDates.length,
          itemBuilder: (context, index) {
            final date = _fixedDates[index];
            final displayName = date.type == FixedDateType.custom ? date.customName ?? 'Event' : date.type.displayName;

            // --- NEW: Subtitle to show recurrence ---
            final subTitleText = date.isRecurring ? 'Repeats Yearly' : 'One-Time Event';

            return Card(
              child: ListTile(
                title: Text(displayName),
                subtitle: Text('${DateFormat.yMd().format(date.date)} ($subTitleText)'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      // --- UPDATED Call ---
                      onPressed: () => _onEditEventPressed(date, index),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          _fixedDates.removeAt(index);
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),

        const SizedBox(height: 16),

        // --- NEW: Two-button layout ---
        Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center, // Makes buttons full-width
            children: [
              ElevatedButton.icon(
                // Changed to ElevatedButton
                icon: const Icon(Icons.cake),
                label: const Text('Add Yearly Event'),
                onPressed: () => _onAddEventPressed(isRecurring: true),
              ),
              const SizedBox(height: 8), // A little space
              ElevatedButton.icon(
                // Changed to ElevatedButton
                icon: const Icon(Icons.calendar_today),
                label: const Text('Add One-Time Event'),
                onPressed: () => _onAddEventPressed(isRecurring: false),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -----------------------------------------------------------------
// --- "SMART" CALCULATOR LOGIC (Unchanged) ---
// -----------------------------------------------------------------
DateTime _calculateNextRandomDate({required int remindersPerYear, required List<FixedDate> personFixedDates, DateTime? fromDate}) {
  // ... (all the code from before is identical) ...
  final now = fromDate ?? DateTime.now();
  final random = Random();
  final int avgDays = (365 / remindersPerYear).round();
  final int flexibility = 14;
  final int minDays = max(avgDays - flexibility, 7);
  final int maxDays = avgDays + flexibility;
  final blackoutDates = _getBlackoutDates(personFixedDates);
  int attempts = 0;
  while (attempts < 100) {
    final int daysToAdd = minDays + random.nextInt(maxDays - minDays + 1);
    final DateTime candidateDate = now.add(Duration(days: daysToAdd));
    if (_isDateSafe(candidateDate, blackoutDates)) {
      return candidateDate;
    }
    attempts++;
  }
  return now.add(Duration(days: minDays));
}

bool _isDateSafe(DateTime candidateDate, List<DateTime> blackoutDates) {
  const int safetyWindow = 14;
  for (final blackoutDate in blackoutDates) {
    final int difference = candidateDate.difference(blackoutDate).inDays.abs();
    if (difference <= safetyWindow) {
      return false;
    }
  }
  return true;
}

List<DateTime> _getBlackoutDates(List<FixedDate> personFixedDates) {
  final now = DateTime.now();
  final currentYear = now.year;
  List<DateTime> dates = [];
  for (final fixedDate in personFixedDates) {
    DateTime dateThisYear = DateTime(currentYear, fixedDate.date.month, fixedDate.date.day);
    if (dateThisYear.isBefore(now)) {
      dates.add(DateTime(currentYear + 1, fixedDate.date.month, fixedDate.date.day));
    } else {
      dates.add(dateThisYear);
    }
  }
  for (int year in [currentYear, currentYear + 1]) {
    dates.add(DateTime(year, 1, 1)); // New Year's Day
    dates.add(DateTime(year, 2, 14)); // Valentine's Day
    dates.add(DateTime(year, 12, 25)); // Christmas
    dates.add(_findThanksgiving(year));
  }
  return dates;
}

DateTime _findThanksgiving(int year) {
  DateTime firstDayOfNov = DateTime(year, 11, 1);
  int daysUntilFirstThursday = (4 - firstDayOfNov.weekday + 7) % 7;
  DateTime firstThursday = firstDayOfNov.add(Duration(days: daysUntilFirstThursday));
  DateTime fourthThursday = firstThursday.add(const Duration(days: 21));
  return fourthThursday;
}
