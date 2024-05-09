// Schedule data model.
import 'package:flutter/material.dart';
import 'package:web_app/common.dart';
import 'package:web_app/time.dart';

abstract class Schedule {
  DateTime? getNextDate({DateTime? after = null});
  DateTime? getPrevDate({DateTime? before = null});

  /// Format a DateTime according to what makes sense
  /// for the way this schedule is specified.
  String format(DateTime dateTime);

  Map<String, dynamic> toJson();

  static Schedule fromJson(dynamic json) {
    switch (json['type']) {
      case 'once':
        return ScheduleOnce.fromJson(json);
      case 'recurring':
        return ScheduleRecurring.fromJson(json);
      default:
        throw ArgumentError('Unable to parse schedule from the given json.');
    }
  }
}

String _scheduleFormat(DateTime dateTime, TimeOfDay? scheduleTime,
    TimeOfDay? scheduleEndTime, String? scheduleTimeZone) {
  // This formats a scheduled date, start-and-end times, and timezone.
  // The given DateTime is used only for its date content
  // (we use scheduleTime and scheduleEndTime for the times, if given),
  // so it's irrelevant if its time content matches the schedule or not.
  var result = longDateFormat.format(dateTime);
  if (scheduleTime != null) {
    final hh = scheduleTime.hourOfPeriod.toString();
    final mm = scheduleTime.minute.toString().padLeft(2, '0');
    final aa = scheduleTime.period == DayPeriod.am ? 'am' : 'pm';
    result += ' $hh:$mm $aa';
    if (scheduleEndTime != null) {
      final hh = scheduleEndTime.hourOfPeriod.toString();
      final mm = scheduleEndTime.minute.toString().padLeft(2, '0');
      final aa = scheduleEndTime.period == DayPeriod.am ? 'am' : 'pm';
      result += '-$hh:$mm $aa';
    }
    if (scheduleTimeZone != null) {
      result += ' (${scheduleTimeZone})';
    }
  }
  return result;
}

class ScheduleOnce implements Schedule {
  final String type = 'once';
  final DateTime date;
  final TimeOfDay? time;
  final TimeOfDay? endTime;
  final String? timeZone;

  ScheduleOnce({required this.date, this.time, this.endTime, timeZone})
      // If time is null, force timeZone to be null too.
      : timeZone = time == null ? null : timeZone;

  DateTime asDateTime() {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
  }

  DateTime? getNextDate({DateTime? after = null}) {
    if (after == null) {
      after = DateTime.now();
    }
    final dateTimeNoTz = asDateTime();
    return dateTimeNoTz.isAfter(after) ? dateTimeNoTz : null;
  }

  DateTime? getPrevDate({DateTime? before = null}) {
    if (before == null) {
      before = DateTime.now();
    }
    final dateTimeNoTz = asDateTime();
    return dateTimeNoTz.isBefore(before) ? dateTimeNoTz : null;
  }

  String format(DateTime dateTime) {
    return _scheduleFormat(dateTime, this.time, this.endTime, this.timeZone);
  }

  factory ScheduleOnce.fromJson(Map<String, dynamic> json) {
    return ScheduleOnce(
      date: DateJson.parse(json['date']),
      time: json['time'] == null ? null : TimeOfDayJson.parse(json['time']),
      endTime:
          json['endTime'] == null ? null : TimeOfDayJson.parse(json['endTime']),
      timeZone: json['timeZone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "date": date.toDateJson(),
      "time": time?.toJson(),
      "endTime": endTime?.toJson(),
      "timeZone": timeZone,
    };
  }
}

class ScheduleRecurring extends Schedule {
  final String type = 'recurring';
  final DateTime date;
  final TimeOfDay? time;
  final TimeOfDay? endTime;
  final String? timeZone;
  final Frequency frequency;
  final DateTime? until;

  ScheduleRecurring(
      {required this.date,
      this.time,
      this.endTime,
      this.timeZone,
      required this.frequency,
      this.until});

  DateTime startAsDateTime() {
    return DateTime(
      date.year,
      date.month,
      date.day,
      time?.hour ?? 0,
      time?.minute ?? 0,
    );
  }

  DateTime? getNextDate({DateTime? after = null}) {
    if (after == null) {
      after = DateTime.now();
    }
    try {
      return boundedDateSequence(
        startAsDateTime(),
        frequency,
        after: after,
        before: until, // If there's a stop date, make sure we don't pass it.
      ).first;
    } on StateError {
      return null;
    }
  }

  DateTime? getPrevDate({DateTime? before = null}) {
    if (before == null) {
      before = DateTime.now();
    }
    try {
      return boundedDateSequence(
        startAsDateTime(),
        frequency,
        before: before,
      ).last;
    } on StateError {
      return null;
    }
  }

  String format(DateTime dateTime) {
    return _scheduleFormat(dateTime, this.time, this.endTime, this.timeZone);
  }

  factory ScheduleRecurring.fromJson(Map<String, dynamic> json) {
    return ScheduleRecurring(
      date: DateJson.parse(json['date']),
      time: json['time'] == null ? null : TimeOfDayJson.parse(json['time']),
      endTime:
          json['endTime'] == null ? null : TimeOfDayJson.parse(json['endTime']),
      timeZone: json['timeZone'],
      frequency: Frequency.parse(json['frequency']),
      until: json['until'] == null ? null : DateJson.parse(json['until']),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      "type": type,
      "date": date.toDateJson(),
      "time": time?.toJson(),
      "endTime": endTime?.toJson(),
      "timeZone": timeZone,
      "frequency": frequency.name,
      "until": until?.toDateJson(),
    };
  }
}
