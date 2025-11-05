import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:random_reminder/utilities/fixed_date.dart'; // We need our enum

class FixedDateDialog extends StatefulWidget {
  final FixedDate? dateToEdit; // Pass in a date to edit, or null for new

  const FixedDateDialog({super.key, this.dateToEdit});

  @override
  _FixedDateDialogState createState() => _FixedDateDialogState();
}

class _FixedDateDialogState extends State<FixedDateDialog> {
  final _formKey = GlobalKey<FormState>();

  // Form state
  FixedDateType _selectedType = FixedDateType.birthday;
  DateTime? _selectedDate;
  final _customNameController = TextEditingController();

  // --- NEW STATE VARIABLES ---
  bool _isRecurring = true; // Default to recurring
  bool _showCustomNameField = false;
  bool _showRecurringCheckbox = false; // Only show for 'custom' type

  @override
  void initState() {
    super.initState();
    // If we are editing, populate the form
    if (widget.dateToEdit != null) {
      final date = widget.dateToEdit!;
      _selectedType = date.type;
      _selectedDate = date.date;
      _customNameController.text = date.customName ?? '';
      _isRecurring = date.isRecurring; // Set from saved data

      // Set visibility based on saved data
      _showCustomNameField = (date.type == FixedDateType.custom);
      _showRecurringCheckbox = (date.type == FixedDateType.custom);
    } else {
      // If adding a new event, set recurring based on default type (birthday)
      _updateRecurringLogic(_selectedType);
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
        isRecurring: _isRecurring, // <-- Use the state variable
      );

      // Pop the dialog and return the new object
      Navigator.of(context).pop(newFixedDate);
    }
  }

  /// When the user picks a date from the calendar
  void _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(1900),
      // Allow future dates for things like graduation
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  /// --- NEW: Helper to manage the recurring logic ---
  void _updateRecurringLogic(FixedDateType newType) {
    // Set visibility of the text field
    _showCustomNameField = (newType == FixedDateType.custom);
    // Set visibility of the checkbox
    _showRecurringCheckbox = (newType == FixedDateType.custom);

    // Set the value of _isRecurring
    if (newType == FixedDateType.graduation) {
      // Graduations are one-time events
      _isRecurring = false;
    } else if (newType == FixedDateType.custom) {
      // For custom, leave the checkbox as it is (or default to true)
      _isRecurring = _isRecurring; // No change
    } else {
      // All other types (Birthday, etc.) are recurring
      _isRecurring = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.dateToEdit == null ? 'Add Fixed Event' : 'Edit Fixed Event'),
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
                    // Call our new helper function
                    _updateRecurringLogic(newValue);
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

              const SizedBox(height: 10),

              // --- NEW: Recurring Checkbox (Conditional) ---
              if (_showRecurringCheckbox)
                CheckboxListTile(
                  title: const Text("Repeat this event every year?"),
                  value: _isRecurring,
                  onChanged: (bool? newValue) {
                    setState(() {
                      _isRecurring = newValue ?? true;
                    });
                  },
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                ),
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
