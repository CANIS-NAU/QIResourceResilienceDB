import 'dart:math';
import 'package:flutter/material.dart';

import 'package:intl/intl.dart';

import './common.dart';

final DateFormat longDateFormat = DateFormat.yMMMMd('en_US');

List<int> _daysInMonthNormalYear = const [
  31,
  28,
  31,
  30,
  31,
  30,
  31,
  31,
  30,
  31,
  30,
  31
];

List<int> _daysInMonthLeapYear = const [
  31,
  29,
  31,
  30,
  31,
  30,
  31,
  31,
  30,
  31,
  30,
  31
];

bool isLeapYear(int year) {
  return (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0);
}

int daysInMonth(int year, int month) {
  final dim = isLeapYear(year) ? _daysInMonthLeapYear : _daysInMonthNormalYear;
  return dim[month - 1];
}

int toMinuteOfDay(TimeOfDay time) {
  return time.hour * 60 + time.minute;
}

enum Frequency implements HasLabel {
  daily('Daily'),
  weekly('Weekly'),
  monthly('Monthly'),
  annually('Annually');

  const Frequency(this.label);
  final String label;

  static Frequency parse(String string) {
    return Frequency.values.firstWhere(
      (e) => e.name == string,
      orElse: () => throw ArgumentError('Invalid Frequency: $string'),
    );
  }
}

/// Generate a sequence of dates from a given `starting`
/// and repeating according to Frequency.
Iterable<DateTime> dateSequence(DateTime starting, Frequency frequency) sync* {
  Function(DateTime) next;
  switch (frequency) {
    case Frequency.annually:
      next = (prev) =>
          DateTime(prev.year + 1, prev.month, prev.day, prev.hour, prev.minute);
      break;
    case Frequency.monthly:
      // Monthly is tricky because months have different numbers of days.
      // This implementation prefers the same day of the month as the initial
      // date, but will use the latest available day in the correct month
      // if it has to. In other words, 'Jan 31st, 2023' becomes 'Feb 28th, 2023'
      // and then 'Mar 31st, 2023' after that. Leap year accounted for.
      next = (prev) {
        // increment year if prev was in December
        final year = prev.month == 12 ? prev.year + 1 : prev.year;
        // increment month; must be in range [1,12]
        final month = prev.month % 12 + 1;
        final day = min(starting.day, daysInMonth(year, month));
        return DateTime(year, month, day, prev.hour, prev.minute);
      };
      break;
    case Frequency.weekly:
      next = (prev) => prev.add(const Duration(days: 7));
      break;
    case Frequency.daily:
      next = (prev) => prev.add(const Duration(days: 1));
      break;
  }

  var curr = starting;
  while (true) {
    yield curr;
    curr = next(curr);
  }
}

/// Generate a sequence of dates from a given `starting`
/// and repeating according to Frequency, but bound to the range
/// specified from `after` to `before`. Both endpoints are optional.
Iterable<DateTime> boundedDateSequence(DateTime starting, Frequency frequency,
    {DateTime? after, DateTime? before}) {
  // NOTE: this may be really inefficient if there are a lot of dates
  // to chew through before the 'after' date... but maybe it doesn't matter.
  if (after != null && before != null && after.isAfter(before)) {
    // Quick shortcut: if the start of our range (`after`)
    // is past the end of our range (`before`) there will be no dates
    // in the sequence.
    return Iterable.empty();
  }
  if (before != null && before.isBefore(starting)) {
    // Similar shortcut: if the end of our range (`before`)
    // is before the starting date there will be no dates in the sequence.
    return Iterable.empty();
  }
  var seq = dateSequence(starting, frequency);
  if (after != null) {
    seq = seq.skipWhile((value) => value.isBefore(after));
  }
  if (before != null) {
    seq = seq.takeWhile((value) => value.isBefore(before));
  }
  return seq;
}
