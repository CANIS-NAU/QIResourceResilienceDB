// General purpose utilities for the RRDB application.

import 'package:flutter/material.dart';

abstract class HasLabel {
  String get label;
}

/// Turn a list of items which have labels to a list of dropdown menu items.
/// This is especially useful for enums which implement HasLabel.
/// The item itself will be used as the value.
List<DropdownMenuItem<T>> toOptions<T extends HasLabel>(List<T> items) {
  return items
      .map((x) => DropdownMenuItem<T>(
            value: x,
            child: Text(x.label),
          ))
      .toList();
}

/// Prepend an blank menu item to a list of menu items.
/// Its value is null. This would allow the user to clear their selection.
List<DropdownMenuItem<T?>> withEmptyOption<T>(
    List<DropdownMenuItem<T>> options) {
  return [DropdownMenuItem<T?>(value: null, child: Text('')), ...options];
}

/// A custom JSON codec extension for TimeOfDay instances.
extension TimeOfDayJson on TimeOfDay {
  String toJson() {
    final hh = this.hour.toString().padLeft(2, '0');
    final mm = this.minute.toString().padLeft(2, '0');
    return 'T$hh:$mm';
  }

  static TimeOfDay parse(String string) {
    final hour = int.parse(string.substring(1, 3));
    final minute = int.parse(string.substring(4));
    return TimeOfDay(hour: hour, minute: minute);
  }
}

/// A custom JSON codec extension for DateTime instances
/// that represent dates (without time information).
extension DateJson on DateTime {
  /// Created a DateTime that is the same date but with all time information
  /// zeroed-out.
  DateTime withoutTime() {
    return DateTime(this.year, this.month, this.day);
  }

  String toDateJson() {
    final yyyy = this.year.toString().padLeft(4, '0');
    final MM = this.month.toString().padLeft(2, '0');
    final dd = this.day.toString().padLeft(2, '0');
    return '$yyyy-$MM-$dd';
  }

  static DateTime parse(String string) {
    final year = int.parse(string.substring(0, 4));
    final month = int.parse(string.substring(5, 7));
    final day = int.parse(string.substring(8));
    return DateTime(year, month, day);
  }
}

/// Join a list of items where each item is a nullable String.
/// Any item that is null or the empty string will be ignored.
/// Anything remaining will be joined with the given separator (default `', '`),
/// unless the filtered list contains no items, then `emptyValue` is returned
/// instead (default `''`).
String? filterJoin(List<String?> items,
    {String separator = ', ', String? emptyValue = ''}) {
  final filtered = items.where((x) => x != null && x.isNotEmpty).toList();
  return filtered.isNotEmpty ? filtered.join(separator) : emptyValue;
}


// Get the current date
DateTime getCurrentTime() {
  return DateTime.now();
}
