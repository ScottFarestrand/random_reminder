import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_reminder/utilities/fixed_date.dart'; // We need our enum

class FixedDateDialog extends StatefulWidget {
  final FixedDate? dateToEdit;

  // --- NEW: We pass this in when creating a new event ---
  final bool? isRecurringForNew;

  const FixedDateDialog({
    super.key,
    this.dateToEdit,
    this.isRecurringForNew, // isRecurringForNew is for 'add', dateToEdit is for 'edit'
  });

  @override
  _FixedDateDialogState createState() => _FixedDateDialogState();
}

class _FixedDateDialogState extends State<FixedDateDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form state
  FixedDateType _selectedType = FixedDateType.birthday;
  DateTime? _selectedDate;
  final _customNameController = TextEditingController();

  // --- NEW: Simplified state. This is set once and never changed by the user. ---
  bool _isRecurring = true;
  bool _showCustomNameField = false;

  @override
  void initState() {
    super.initState();
    // If we are editing, populate the form
    if (widget.dateToEdit != null) {
      final date = widget.dateToEdit!;
      _selectedType = date.type;
      _selectedDate = date.date;
      _customNameController.text = date.customName ?? '';
      _isRecurring = date.isRecurring; // Get value from existing object
      _showCustomNameField = (date.type == FixedDateType.custom);
    } else {
      // If we are ADDING, get the value from the constructor
      _isRecurring = widget.isRecurringForNew ?? true; // Default to true
      _showCustomNameField = (_selectedType == FixedDateType.custom);
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    super.dispose();
  }

  /// --- UPDATED: When the user taps "Save" ---
  void _saveDialog() {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date.'), backgroundColor: Colors.red));
        return;
      }

      // Build the new FixedDate object
      final newFixedDate = FixedDate(
        type: _selectedType,
        date: _selectedDate!,
        customName: _showCustomNameField ? _customNameController.text : null,
        // --- Use the _isRecurring value we set in initState ---
        isRecurring: _isRecurring,
      );

      // Pop the dialog and return the new object
      Navigator.of(context).pop(newFixedDate);
    }
  }

  /// When the user picks a date from the calendar
  void _pickDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(1900), lastDate: DateTime(2101));
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      // --- NEW: Title changes based on recurrence ---
      title: Text(widget.dateToEdit != null ? 'Edit Fixed Event' : (_isRecurring ? 'Add Yearly Event' : 'Add One-Time Event')),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Event Type Dropdown ---
              DropdownButtonFormField<FixedDateType>(
                value: _selectedType,
                items: FixedDateType.values.map((type) => DropdownMenuItem(value: type, child: Text(type.displayName))).toList(),
                onChanged: (FixedDateType? newValue) {
                  if (newValue == null) return;
                  setState(() {
                    _selectedType = newValue;
                    _showCustomNameField = (newValue == FixedDateType.custom);
                  });
                },
                decoration: const InputDecoration(labelText: 'Event Type'),
              ),

              // --- Custom Name Field (Conditional) ---
              if (_showCustomNameField)
                TextFormField(
                  controller: _customNameController,
                  decoration: const InputDecoration(labelText: 'Event Name'),
                  validator: (value) {
                    if (_showCustomNameField && (value == null || value.isEmpty)) {
                      return 'Please enter a name for your custom event.';
                    }
                    return null;
                  },
                ),

              const SizedBox(height: 20),

              // --- Date Picker ---
              Text('Selected Date:', style: Theme.of(context).textTheme.bodySmall),
              Text(_selectedDate == null ? 'No date chosen' : DateFormat.yMMMd().format(_selectedDate!), style: Theme.of(context).textTheme.titleMedium),
              TextButton.icon(icon: const Icon(Icons.calendar_today), label: Text(_selectedDate == null ? 'Select Date' : 'Change Date'), onPressed: _pickDate),

              // --- CHECKBOX IS GONE ---
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        ElevatedButton(onPressed: _saveDialog, child: const Text('Save')),
      ],
    );
  }
}
