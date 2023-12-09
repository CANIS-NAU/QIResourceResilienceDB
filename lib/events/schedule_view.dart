import 'package:flutter/material.dart';
import 'package:web_app/common.dart';
import 'package:web_app/time.dart';

import 'schedule.dart';

class ScheduleView extends StatelessWidget {
  ScheduleView({super.key, required this.schedule});

  final Schedule schedule;

  @override
  Widget build(BuildContext context) {
    if (schedule is ScheduleOnce) {
      return ScheduleOnceView(schedule: schedule as ScheduleOnce);
    } else if (schedule is ScheduleRecurring) {
      return ScheduleRecurringView(schedule: schedule as ScheduleRecurring);
    } else {
      return Text(
          '(Error: rendering unknown schedule type ${schedule.runtimeType.toString()}.)');
    }
  }
}

class ScheduleOnceView extends StatelessWidget {
  ScheduleOnceView({super.key, required this.schedule});

  final ScheduleOnce schedule;

  @override
  Widget build(BuildContext context) {
    return Text(
      filterJoin([
        longDateFormat.format(schedule.date),
        if (schedule.time != null) schedule.time!.format(context),
        if (schedule.timeZone != null) '(${schedule.timeZone})',
      ], separator: ' ')!,
    );
  }
}

class ScheduleRecurringView extends StatelessWidget {
  ScheduleRecurringView({super.key, required this.schedule});

  final ScheduleRecurring schedule;

  @override
  Widget build(BuildContext context) {
    final started = filterJoin([
      longDateFormat.format(schedule.date),
      if (schedule.time != null) schedule.time!.format(context),
      if (schedule.timeZone != null) '(${schedule.timeZone})',
    ], separator: ' ')!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${schedule.frequency.label} recurring event'),
        Text('Starting: ${started}'),
        if (schedule.until != null) //
          Text('Until: ${longDateFormat.format(schedule.until!)}')
      ],
    );
  }
}
