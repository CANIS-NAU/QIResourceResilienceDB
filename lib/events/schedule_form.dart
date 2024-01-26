import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;

import '../common.dart';
import '../time.dart';
import 'schedule.dart';

/// Implements form fields for entering Schedule data.
class ScheduleFormFields extends StatefulWidget {
  final Function(Schedule?) onChanged;

  ScheduleFormFields({super.key, required this.onChanged});

  @override
  State<ScheduleFormFields> createState() => _ScheduleFormState();
}

const EdgeInsets fieldPadding = EdgeInsets.symmetric(vertical: 8.0);
const EdgeInsets rowMargin = EdgeInsets.symmetric(horizontal: 4.0);

const double iconButtonSize = 40.0;
const double iconButtonRadius = 20.0;

class _ScheduleFormState extends State<ScheduleFormFields> {
  DateTime _date = DateTime.now().withoutTime();
  TimeOfDay? _time;
  TimeOfDay? _endTime;
  String? _timeZone = 'US/Arizona';
  bool _isRecurring = false;
  Frequency _frequency = Frequency.daily;
  DateTime? _until;

  /// Respond to form changes by triggering the widget's onChanged
  /// with the Schedule instance that results from this form.
  /// If the form is invalid, onChanged is given null instead.
  void onChanged() {
    Schedule? schedule = null;
    int? startTimeMinute = _time == null ? null : toMinuteOfDay(_time!);
    int? endTimeMinute = _endTime == null ? null : toMinuteOfDay(_endTime!);
    // timezone and end time are only valid if start time is set
    final z = _time == null ? null : _timeZone;
    final et = _time == null ? null : _endTime;

    if (_time != null && _timeZone == null) {
      // If time is set, time zone is required.
      schedule = null;
    } else if (startTimeMinute != null &&
        endTimeMinute != null &&
        startTimeMinute >= endTimeMinute) {
      // endTime, if set, must come after start time.
      schedule = null;
    } else if (!_isRecurring) {
      schedule =
          ScheduleOnce(date: _date, time: _time, endTime: et, timeZone: z);
    } else {
      schedule = ScheduleRecurring(
          date: _date,
          time: _time,
          endTime: et,
          timeZone: z,
          frequency: _frequency,
          until: _until);
    }
    // debugPrint(schedule?.toJson().toString() ?? 'schedule is null');
    widget.onChanged(schedule);
  }

  @override
  Widget build(BuildContext context) {
    List<String> allTimeZones = tz.timeZoneDatabase.locations.keys.toList();

    return Column(children: [
      // Event date controls
      Padding(
        padding: fieldPadding,
        child: Row(children: [
          Container(
            margin: rowMargin,
            child: Text('Event date:'),
          ),
          Container(
            margin: rowMargin,
            child: Text(longDateFormat.format(_date)),
          ),
          Spacer(),
          Container(
            margin: rowMargin,
            child: IconButton(
              icon: Icon(Icons.edit),
              splashRadius: iconButtonRadius,
              onPressed: () async {
                DateTime? selection = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2101),
                );
                if (selection != null) {
                  setState(() {
                    // Make sure time is zeroed-out.
                    _date = selection.withoutTime();
                    onChanged();
                  });
                }
              },
              tooltip: 'Change Date',
            ),
          ),
          Container(
            margin: rowMargin,
            width: iconButtonSize,
            child: null, // space for clear button
          ),
        ]),
      ),

      // Event time controls
      Padding(
        padding: fieldPadding,
        child: Row(children: [
          Container(
            margin: rowMargin,
            child: Text('Event start time:'),
          ),
          Container(
            margin: rowMargin,
            child: Text(_time != null ? _time!.format(context) : 'None'),
          ),
          Spacer(),
          Container(
            margin: rowMargin,
            child: IconButton(
              icon: Icon(Icons.edit),
              splashRadius: iconButtonRadius,
              onPressed: () async {
                TimeOfDay? selection = await showTimePicker(
                  context: context,
                  initialTime: _time ?? TimeOfDay.now(),
                );
                if (selection != null) {
                  setState(() {
                    _time = selection;
                    onChanged();
                  });
                }
              },
              tooltip: 'Change Time',
            ),
          ),
          Container(
            margin: rowMargin,
            child: IconButton(
              icon: Icon(Icons.clear),
              splashRadius: iconButtonRadius,
              onPressed: () {
                setState(() {
                  // Can't have end time if start time is blank.
                  _time = null;
                  _endTime = null;
                  onChanged();
                });
              },
              tooltip: 'Clear Time',
            ),
          ),
        ]),
      ),

      Padding(
        padding: fieldPadding,
        child: Row(children: [
          Container(
            margin: rowMargin,
            child: Text('Event end time:'),
          ),
          Container(
            margin: rowMargin,
            child: Text(_endTime != null ? _endTime!.format(context) : 'None'),
          ),
          Spacer(),
          Container(
            margin: rowMargin,
            child: IconButton(
              icon: Icon(Icons.edit),
              splashRadius: iconButtonRadius,
              // disabled if there's no start time selected
              onPressed: _time == null
                  ? null
                  : () async {
                      TimeOfDay? selection = await showTimePicker(
                        context: context,
                        initialTime: _endTime ?? TimeOfDay.now(),
                      );
                      if (selection != null) {
                        setState(() {
                          _endTime = selection;
                          onChanged();
                        });
                      }
                    },
              tooltip: 'Change Time',
            ),
          ),
          Container(
            margin: rowMargin,
            child: IconButton(
              icon: Icon(Icons.clear),
              splashRadius: iconButtonRadius,
              // disabled if there's no start time selected
              onPressed: _time == null
                  ? null
                  : () {
                      setState(() {
                        _endTime = null;
                        onChanged();
                      });
                    },
              tooltip: 'Clear Time',
            ),
          ),
        ]),
      ),

      // Event time zone dropdown
      Padding(
        padding: fieldPadding,
        child: Row(children: [
          Container(
            margin: rowMargin,
            child: Text('Time zone:'),
          ),
          Container(
            margin: rowMargin,
            child: DropdownButton<String>(
              items: allTimeZones.map((timeZone) {
                return DropdownMenuItem<String>(
                  value: timeZone,
                  child: Text(timeZone),
                );
              }).toList(),
              value: _timeZone,
              // disabled if there's no time selected
              onChanged: _time == null
                  ? null
                  : (selection) {
                      _timeZone = selection;
                      onChanged();
                    },
            ),
          ),
        ]),
      ),

      // Is recurring?
      Padding(
        padding: fieldPadding,
        child: Row(
          children: [
            Container(
              margin: rowMargin,
              child: Text('Is recurring?'),
            ),
            Container(
              margin: rowMargin,
              child: Checkbox(
                value: _isRecurring,
                onChanged: (checked) {
                  setState(() {
                    _isRecurring = checked!;
                    onChanged();
                  });
                },
              ),
            ),
          ],
        ),
      ),

      // Recurring event controls section
      Visibility(
        visible: _isRecurring,
        child: Column(children: [
          // Frequency dropdown
          Padding(
            padding: fieldPadding,
            child: Row(children: [
              Container(
                margin: rowMargin,
                child: Text('Event frequency:'),
              ),
              Container(
                margin: rowMargin,
                child: DropdownButton<Frequency?>(
                  items: toOptions(Frequency.values),
                  value: _frequency,
                  onChanged: (selection) {
                    if (selection != null) {
                      _frequency = selection;
                      onChanged();
                    }
                  },
                ),
              ),
            ]),
          ),

          // End date
          Padding(
            padding: fieldPadding,
            child: Row(children: [
              Container(
                margin: rowMargin,
                child: Text('Recurs until:'),
              ),
              Container(
                margin: rowMargin,
                child: Text(_until != null
                    ? longDateFormat.format(_until!)
                    : '(no end date selected)'),
              ),
              Spacer(),
              Container(
                margin: rowMargin,
                child: IconButton(
                  icon: Icon(Icons.edit),
                  splashRadius: iconButtonRadius,
                  onPressed: () async {
                    DateTime? selection = await showDatePicker(
                      context: context,
                      initialDate: _until ?? DateTime.now().withoutTime(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2101),
                    );
                    if (selection != null) {
                      setState(() {
                        // Make sure time is zeroed-out.
                        _until = selection.withoutTime();
                        onChanged();
                      });
                    }
                  },
                  tooltip: 'Change Date',
                ),
              ),
              Container(
                margin: rowMargin,
                child: IconButton(
                  icon: Icon(Icons.clear),
                  splashRadius: iconButtonRadius,
                  onPressed: () {
                    setState(() {
                      _until = null;
                      onChanged();
                    });
                  },
                  tooltip: 'Clear End Date',
                ),
              ),
            ]),
          ),
        ]),
      ),
    ]);
  }
}
