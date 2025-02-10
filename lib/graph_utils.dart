import 'package:flutter/material.dart';

// class representing a data point for a graph
class GraphDataPoint {
  // x,y coordinates of data point and the group that the point belongs to
  final int bucket; // use bucket number as x int value
  final double y;
  final String group;

  // initialize GraphDataPoint instance
  GraphDataPoint({required this.bucket, required this.y, required this.group});
}

Widget buildLegend(Map<String, Color> groupColors, {Axis direction = Axis.vertical}) {
  List<Widget> keyWidgets = groupColors.entries.map((entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: entry.value,
              border: Border.all(color: Colors.black, width: 1),
            ),
          ),
          SizedBox(width: 5),
          Text(entry.key),
        ],
      ),
    );
  }).toList();
  return direction == Axis.vertical
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: keyWidgets,
        )
      : Row(
          children: keyWidgets,
        );
}

// convert a timestamp to an integer bucket number
  int getBucketNumber(DateTime timestamp, Duration bucketSize, DateTime baseline) {
    // convert to UTC to avoid timezone issues
    DateTime utcTimestamp = timestamp.toUtc();
    DateTime utcBaseline = baseline.toUtc();
    // calculate the bucket number by determining how many bucket durations
    return utcTimestamp.difference(utcBaseline).inMilliseconds ~/ bucketSize.inMilliseconds;
  }

// map a bucket number back to its start date
  DateTime getBucketStartDate(int bucketNumber, Duration bucketSize, DateTime baseline) {
    DateTime utcBaseline = baseline.toUtc(); // ensure UTC timezone
    // calculate the start date of the bucket using the bucket number
    return utcBaseline.add(Duration(milliseconds: bucketNumber * bucketSize.inMilliseconds));
  }

  // process data into buckets
  List<GraphDataPoint> processDataWithBuckets( List<Map<String, dynamic>> data,
      Duration bucketSize, DateTime startDate, DateTime endDate, 
      String selectedData,  Map<String, List<String>> allGroups) {

    // map to hold counts per bucket for each group
    Map<int, Map<String, int>> countsPerBucket = {};

    // use the start date as baseline for bucket calculations
    DateTime baseline = startDate.toUtc();

    // iterate over the data to populate counts per bucket
    for (var entry in data) {
      if (entry['timestamp'] == null) continue;
      DateTime timestamp = entry['timestamp'].toUtc(); // convert to UTC
      if (timestamp.isBefore(startDate) || timestamp.isAfter(endDate)) continue;

      // get the bucket number for the current timestamp
      int bucketNumber = getBucketNumber(timestamp, bucketSize, baseline);

      // determine the group based on selected data
      String? group;
      if (selectedData == 'Resource Type Searches') {
        group = entry['Type'];
      } else if (selectedData == "Age Range Searches") {
        group = entry['Age Range'];
      } else {
        group = entry['type'];
      }
      if (group == null) continue;

      // initialize the bucket and group count
      countsPerBucket[bucketNumber] ??= {};
      countsPerBucket[bucketNumber]![group] = (countsPerBucket[bucketNumber]![group] ?? 0) + 1;
    }

    // ensure all buckets are initialized, in order to plot 0 data
    List<String> groups = allGroups[selectedData] ?? [];
    DateTime currentBucketStart = startDate.toUtc();
    // create all buckets
    while (currentBucketStart.isBefore(endDate.toUtc()) || currentBucketStart.isAtSameMomentAs(endDate.toUtc())) {
      int bucketNumber = getBucketNumber(currentBucketStart, bucketSize, baseline);

      // initialize the bucket if it doesn't exist
      countsPerBucket[bucketNumber] ??= {};
      for (var group in groups) {
        // set 0 count for any missing values
        countsPerBucket[bucketNumber]![group] ??= 0;
      }
      // move to next bucket
      currentBucketStart = currentBucketStart.add(bucketSize);
    }

    // convert countsPerBucket to GraphDataPoint objects
    List<GraphDataPoint> processedData = [];
    countsPerBucket.forEach((bucketNumber, groupCounts) {
      // add group data as graph point
      groupCounts.forEach((group, count) {
        processedData.add(GraphDataPoint(
          bucket: bucketNumber, // use bucket number as x-value
          y: count.toDouble(),
          group: group,
        ));
      });
    });

    // return data points
    return processedData;
  }

   // adjust bucket size dynamically based on date range
  Duration getDynamicBucketSize(DateTime startDate, DateTime endDate) {
    int totalDays = endDate.difference(startDate).inDays;
    if(totalDays >= 365 * 5) {
      return Duration(days: 365); // year buckets
    } else if(totalDays >= 365) {
      return Duration(days: 90); // 3 month buckets
    } else if (totalDays >= 90) {
      return Duration(days: 30); // monthly buckets
    } else if (totalDays >= 30) {
      return Duration(days: 7); // weekly buckets
    } else {
      return Duration(days: 1); // daily buckets
    }
  }

  double calculateYAxisInterval(List<GraphDataPoint> data)
  {
    if (data.isEmpty) {
      return 1; // interval when there is no data
    }
    // find the maximum Y value in the data
    double maxY = data.map((point) => point.y).reduce((a, b) => a > b ? a : b);

    // set an interval based on the max Y value
    if (maxY >= 100) {
      return 10;
    } else if (maxY >= 50) {
      return 5;
    } else if (maxY >= 10) {
      return 2;
    } else {
      return 1;
    }
  }
