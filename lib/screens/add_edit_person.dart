import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:random_reminder/models/person.dart';
import 'package:random_reminder/utilities/fixed_date.dart'; // <-- RIGHT
import 'package:random_reminder/utilities/date_helpers.dart';

// Define an enum for clarity
enum PersonType { random, fixed }

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

  // --- NEW STATE VARIABLES ---
  PersonType _personType = PersonType.random;
  double _randomRemindersPerYear = 3;
  List<FixedDate> _fixedDates = [];

  @override
  void initState() {
    super.initState();
    if (widget.personToEdit != null) {
      final person = widget.personToEdit!;
      _nameController.text = person.name;
      _personType = person.type == 'random' ? PersonType.random : PersonType.fixed;
      _randomRemindersPerYear = person.randomRemindersPerYear.toDouble();
      // Create a new list from the old one to avoid modifying the original
      _fixedDates = List<FixedDate>.from(person.fixedDates);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// --- RE-WRITTEN SAVE FUNCTION ---
  void _savePerson() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Create the new Person object
      final person = Person(
        id: widget.personToEdit?.id, // Keep ID if editing
        name: _nameController.text,
        type: _personType == PersonType.random ? 'random' : 'fixed',
        randomRemindersPerYear: _randomRemindersPerYear.toInt(),
        fixedDates: _fixedDates,
        // These are required by your model, so we add defaults
        randomDates: widget.personToEdit?.randomDates ?? [],
        createdAt: widget.personToEdit?.createdAt ?? DateTime.now(),
      );

      try {
        final collection = FirebaseFirestore.instance.collection('users').doc(widget.userId).collection('people');

        if (person.id == null) {
          // Add new person
          await collection.add(person.toMap());
          if (!mounted) return;
          widget.showMessage('Person added successfully', Colors.green);
        } else {
          // Update existing person
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

  /// --- NEW: Shows a dialog to add or edit a FixedDate ---
  /// This is the next piece of UI you'll need to build out.
  void _showFixedDateDialog({FixedDate? existingDate, int? index}) {
    // TODO: Build a dialog (AlertDialog) with fields for:
    // 1. Dropdown for type ('birthday', 'anniversary', 'custom')
    // 2. TextFormField for 'customName' (if type is 'custom')
    // 3. DatePicker to select the 'date'
    //
    // On save, you'll get a new FixedDate object
    // final newDate = FixedDate(type: ..., date: ...);
    //
    // setState(() {
    //   if (index != null) {
    //     _fixedDates[index] = newDate; // Update existing
    //   } else {
    //     _fixedDates.add(newDate); // Add new
    //   }
    // });

    // For now, let's just show a placeholder:
    widget.showMessage('TODO: Build Fixed Date dialog', Colors.blue);
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

              // --- NEW: Type Selector ---
              Text('Reminder Type', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              SegmentedButton<PersonType>(
                segments: const [
                  ButtonSegment(value: PersonType.random, label: Text('Random')),
                  ButtonSegment(value: PersonType.fixed, label: Text('Fixed')),
                ],
                selected: {_personType},
                onSelectionChanged: (Set<PersonType> newSelection) {
                  setState(() {
                    _personType = newSelection.first;
                  });
                },
              ),
              const SizedBox(height: 24),

              // --- NEW: Conditional UI ---
              if (_personType == PersonType.random)
                _buildRandomSection() // Show Random UI
              else
                _buildFixedSection(), // Show Fixed UI

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

  /// --- NEW: UI for Random Reminders ---
  Widget _buildRandomSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Reminders Per Year', style: Theme.of(context).textTheme.titleMedium),
        Text('Approx. ${_randomRemindersPerYear.toInt()} times per year', style: Theme.of(context).textTheme.bodySmall),
        Slider(
          value: _randomRemindersPerYear,
          min: 1,
          max: 12,
          divisions: 11,
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

  /// --- NEW: UI for Fixed Reminders ---
  Widget _buildFixedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fixed Events', style: Theme.of(context).textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                _showFixedDateDialog(); // Call dialog to add new
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_fixedDates.isEmpty) const Center(child: Text('No fixed events added.')),

        // List of existing fixed dates
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _fixedDates.length,
          itemBuilder: (context, index) {
            final date = _fixedDates[index];
            final displayName = date.type == 'custom' ? date.customName ?? 'Event' : date.type.capitalize();
            return Card(
              child: ListTile(
                title: Text(displayName),
                subtitle: Text(DateFormat.yMd().format(date.date)),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () {
                        // Call dialog to edit existing
                        _showFixedDateDialog(existingDate: date, index: index);
                      },
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
      ],
    );
  }
}
