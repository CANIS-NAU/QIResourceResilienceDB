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
  String? _timeZone = 'US/Arizona';
  bool _isRecurring = false;
  Frequency _frequency = Frequency.daily;
  DateTime? _until;

  void onChanged() {
    Schedule? schedule = null;
    if (_time != null && _timeZone == null) {
      // If time is set, time zone is required.
      schedule = null;
    } else if (!_isRecurring) {
      final z = _time == null ? null : _timeZone;
      schedule = ScheduleOnce(date: _date, time: _time, timeZone: z);
    } else {
      final z = _time == null ? null : _timeZone;
      schedule = ScheduleRecurring(
          date: _date,
          time: _time,
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
            child: Text('Event time:'),
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
                  _time = null;
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
