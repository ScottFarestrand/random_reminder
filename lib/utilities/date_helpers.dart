import 'dart:math';
import 'package:random_reminder/models/person.dart';
import 'package:random_reminder/utilities/fixed_date.dart';
import 'package:random_reminder/models/reminder.dart';

class DateHelpers {
  // Function to normalize a DateTime object to YYYY-MM-DD (start of day)
  static DateTime normalizeDate(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Generates unique random dates for the current year, all in the future,
  /// at least 4 weeks apart, and capped at 8 dates.
  static List<DateTime> generateRandomDates({required int numReminders, required List<FixedDate> fixedDates}) {
    final List<DateTime> generatedDates = [];
    final DateTime today = normalizeDate(DateTime.now());
    final int currentYear = today.year;
    final Random random = Random();

    // Cap numReminders at 8
    numReminders = min(numReminders, 8);

    int attempts = 0;
    const int maxAttemptsPerDate = 1000; // Max attempts to find a single valid date
    const int minDaysApart = 28; // 4 weeks

    // Collect all dates to exclude (fixed dates + already generated random dates)
    final List<DateTime> allExcludedDates = fixedDates.map((fd) {
      // Consider fixed date for current year
      DateTime fixedDateThisYear = DateTime(currentYear, fd.date.month, fd.date.day);
      // If fixed date for current year has passed, consider next year's
      if (fixedDateThisYear.isBefore(today)) {
        fixedDateThisYear = DateTime(currentYear + 1, fd.date.month, fd.date.day);
      }
      return normalizeDate(fixedDateThisYear);
    }).toList();

    while (generatedDates.length < numReminders && attempts < numReminders * maxAttemptsPerDate) {
      bool newDateFound = false;
      int currentAttempt = 0;

      while (!newDateFound && currentAttempt < maxAttemptsPerDate) {
        final int month = random.nextInt(12) + 1; // 1-12
        final int day = random.nextInt(28) + 1; // 1-28 to simplify, avoiding month-end issues for now

        DateTime newRandomDate = DateTime(currentYear, month, day);

        // If the generated date is in the past, move it to the next year
        if (newRandomDate.isBefore(today)) {
          newRandomDate = DateTime(currentYear + 1, month, day);
        }

        // Normalize newRandomDate to start of day
        newRandomDate = normalizeDate(newRandomDate);

        // Check if the new date is too close to any already generated dates or excluded fixed dates
        bool isTooClose = false;
        final List<DateTime> allCheckedDates = [...generatedDates, ...allExcludedDates];

        for (final existingDate in allCheckedDates) {
          final Duration diff = newRandomDate.difference(existingDate).abs();
          if (diff.inDays < minDaysApart) {
            isTooClose = true;
            break;
          }
        }

        // Also ensure it's not the exact same month/day as any fixed date (for this or next year)
        for (final fixedDate in fixedDates) {
          final DateTime fixedDateCurrentYear = normalizeDate(DateTime(currentYear, fixedDate.date.month, fixedDate.date.day));
          final DateTime fixedDateNextYear = normalizeDate(DateTime(currentYear + 1, fixedDate.date.month, fixedDate.date.day));

          if (newRandomDate == fixedDateCurrentYear || newRandomDate == fixedDateNextYear) {
            isTooClose = true;
            break;
          }
        }

        if (!isTooClose) {
          generatedDates.add(newRandomDate);
          newDateFound = true;
        }
        currentAttempt++;
      }
      attempts++;
    }

    // Sort the generated dates
    generatedDates.sort((a, b) => a.compareTo(b));
    return generatedDates;
  }

  // Calculates all reminders based on fixed and random dates
  static List<Reminder> calculateReminders(List<Person> people) {
    final List<Reminder> reminders = [];
    final DateTime today = DateTime.now();
    final DateTime normalizedToday = normalizeDate(today);

    for (var person in people) {
      final String personName = person.name;
      final String personType = person.type;
      final int currentYear = today.year;

      // Handle Fixed Date reminders
      for (var fixedEvent in person.fixedDates) {
        final DateTime eventDate = fixedEvent.date;
        final String eventType = fixedEvent.type;
        final String? eventCustomName = fixedEvent.customName;

        final List<DateTime> datesToConsider = [];
        // Consider this year's fixed event
        final DateTime thisYearEvent = normalizeDate(DateTime(currentYear, eventDate.month, eventDate.day));
        datesToConsider.add(thisYearEvent);

        // If this year's event has passed, also consider next year's
        if (thisYearEvent.isBefore(normalizedToday)) {
          final DateTime nextYearEvent = normalizeDate(DateTime(currentYear + 1, eventDate.month, eventDate.day));
          datesToConsider.add(nextYearEvent);
        }

        for (var eventConsiderationDate in datesToConsider) {
          const List<int> reminderOffsets = [0, 1, 5, 10]; // Days before
          for (var offset in reminderOffsets) {
            final DateTime reminderDate = eventConsiderationDate.subtract(Duration(days: offset));
            final DateTime normalizedReminderDate = normalizeDate(reminderDate);

            // Only add if the reminder date is today or in the future
            if (!normalizedReminderDate.isBefore(normalizedToday)) {
              reminders.add(
                Reminder(
                  personName: personName,
                  personType: personType,
                  originalDate: eventConsiderationDate,
                  reminderDate: normalizedReminderDate,
                  eventType: eventType,
                  eventCustomName: eventCustomName,
                  offset: offset == 0 ? 'On Day' : '$offset Days Before',
                ),
              );
            }
          }
        }
      }

      // Handle Random Date reminders
      if (person.randomDates.isNotEmpty) {
        for (var rd in person.randomDates) {
          final DateTime randomDate = rd;
          // Consider this year's random date
          final DateTime thisYearRandomDate = normalizeDate(DateTime(currentYear, randomDate.month, randomDate.day));

          // Only consider if the random date is today or in the future
          if (!thisYearRandomDate.isBefore(normalizedToday)) {
            const List<int> reminderOffsets = [0, 1, 5, 10]; // Days before
            for (var offset in reminderOffsets) {
              final DateTime reminderDate = thisYearRandomDate.subtract(Duration(days: offset));
              final DateTime normalizedReminderDate = normalizeDate(reminderDate);

              // Only add if the reminder date is today or in the future
              if (!normalizedReminderDate.isBefore(normalizedToday)) {
                reminders.add(
                  Reminder(
                    personName: personName,
                    personType: personType,
                    originalDate: thisYearRandomDate,
                    reminderDate: normalizedReminderDate,
                    eventType: 'random_reminder',
                    eventCustomName: null,
                    offset: offset == 0 ? 'On Day' : '$offset Days Before',
                  ),
                );
              }
            }
          }
        }
      }
    }

    // Sort reminders by date
    reminders.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
    return reminders;
  }
}

// Helper extension for capitalizing strings
extension StringExtension on String {
  String capitalize() {
    if (isEmpty) {
      return this;
    }
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}'.replaceAll('_', ' ');
  }
}
