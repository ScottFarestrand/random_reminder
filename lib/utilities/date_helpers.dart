import 'dart:math';
import 'package:random_reminder/models/person.dart';

class DateHelpers {
  static List<DateTime> generateRandomDates(
    List<DateTime> fixedDates,
    int numReminders,
  ) {
    final year = DateTime.now().year;
    final Set<String> excludedDatesSet = {}; // Stores "YYYY-MM-DD" strings

    // Helper to add a date and its surrounding 14 days to the exclusion set
    void addDateRangeToExclusion(DateTime baseDate) {
      for (int i = -14; i <= 14; i++) {
        final date = DateTime(baseDate.year, baseDate.month, baseDate.day + i);
        // Normalize to start of day before converting to ISO string for consistent comparison
        excludedDatesSet.add(date.toIso8601String().split('T')[0]);
      }
    }

    // 1. Add fixed dates (month/day for current year) to exclusion
    for (var fdDate in fixedDates) {
      final date = DateTime(year, fdDate.month, fdDate.day);
      addDateRangeToExclusion(date);
    }

    // 2. Add Valentine's Day exclusion (Feb 14)
    final valentinesDay = DateTime(
      year,
      2,
      14,
    ); // Month is 0-indexed, so 1 is Feb
    addDateRangeToExclusion(valentinesDay);

    // 3. Add Christmas exclusion (Dec 25)
    final christmasDay = DateTime(
      year,
      12,
      25,
    ); // Month is 0-indexed, so 11 is Dec
    addDateRangeToExclusion(christmasDay);

    final random = Random();
    final List<DateTime> generatedRandomDates = [];
    int attempts = 0;
    const maxAttempts = 1000; // Increased attempts for more robust generation

    while (generatedRandomDates.length < numReminders &&
        attempts < maxAttempts) {
      final month = random.nextInt(12) + 1; // 1-12
      final day =
          random.nextInt(28) + 1; // 1-28 to avoid issues with month lengths
      final newDate = DateTime(year, month, day);

      final newDateString = newDate.toIso8601String().split('T')[0];

      // Check if the generated date is in the exclusion set
      if (!excludedDatesSet.contains(newDateString)) {
        generatedRandomDates.add(newDate);
        excludedDatesSet.add(
          newDateString,
        ); // Add newly generated random date to exclusion to avoid duplicates
      }
      attempts++;
    }
    return generatedRandomDates;
  }

  static List<Reminder> calculateReminders(List<Person> people) {
    final List<Reminder> reminders = [];
    final today = DateTime.now();
    final currentYear = today.year;

    for (var person in people) {
      // Handle Fixed Date reminders
      for (var fixedEvent in person.fixedDates) {
        final eventDate = fixedEvent.date;
        final eventType = fixedEvent.type;
        final eventCustomName = fixedEvent.customName;

        final List<DateTime> datesToConsider = [];
        // Consider this year's fixed event
        final thisYearEvent = DateTime(
          currentYear,
          eventDate.month,
          eventDate.day,
        );
        datesToConsider.add(thisYearEvent);

        // If this year's event has passed, also consider next year's
        if (thisYearEvent.isBefore(today.subtract(const Duration(days: 1)))) {
          // Check if past yesterday
          final nextYearEvent = DateTime(
            currentYear + 1,
            eventDate.month,
            eventDate.day,
          );
          datesToConsider.add(nextYearEvent);
        }

        for (var date in datesToConsider) {
          const reminderOffsets = [0, 1, 5, 10]; // Days before
          for (var offset in reminderOffsets) {
            final reminderDate = date.subtract(Duration(days: offset));
            if (!reminderDate.isBefore(
              today.subtract(const Duration(days: 1)),
            )) {
              // Check if today or in the future
              reminders.add(
                Reminder(
                  id: '${person.id}-${eventType}-${date.toIso8601String()}-${offset}',
                  personName: person.name,
                  personType: person.type,
                  originalDate: date,
                  reminderDate: reminderDate,
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
      for (var randomDate in person.randomDates) {
        final List<DateTime> datesToConsider = [];
        final thisYearRandomDate = DateTime(
          currentYear,
          randomDate.month,
          randomDate.day,
        );
        datesToConsider.add(thisYearRandomDate);

        if (thisYearRandomDate.isBefore(
          today.subtract(const Duration(days: 1)),
        )) {
          final nextYearRandomDate = DateTime(
            currentYear + 1,
            randomDate.month,
            randomDate.day,
          );
          datesToConsider.add(nextYearRandomDate);
        }

        for (var date in datesToConsider) {
          const reminderOffsets = [0, 1, 5, 10]; // Days before
          for (var offset in reminderOffsets) {
            final reminderDate = date.subtract(Duration(days: offset));
            if (!reminderDate.isBefore(
              today.subtract(const Duration(days: 1)),
            )) {
              reminders.add(
                Reminder(
                  id: '${person.id}-random-${date.toIso8601String()}-${offset}',
                  personName: person.name,
                  personType: person.type,
                  originalDate: date,
                  reminderDate: reminderDate,
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

    reminders.sort((a, b) => a.reminderDate.compareTo(b.reminderDate));
    return reminders;
  }
}
