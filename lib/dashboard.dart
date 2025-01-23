import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart' as csv;
import 'package:fl_chart/fl_chart.dart';

// main dashboard widget
class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard>
{
  // variables for date range selection
  DateTime? startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime? endDate = DateTime.now();

  // global key to capture graph for export
  final GlobalKey graphToExport = GlobalKey();
  Widget? graphWidget;

  // options for chart types
  final List<String> chartTypes = ['Line Graph', 'Bar Graph', 'Pie Chart'];
  String selectedChartType = "Line Graph";

  // options for export types
  String selectedExportType = 'PDF';
  final List<String> exportTypes = ['PDF', 'Image'];

  // options for data source
  String selectedData = 'Total Site Visits';
  final List<String> dataSources = ['Total Site Visits', 'Clicks to Offsite Links',
    'Age Range Searches', 'Health Focus Searches', 'Resource Type Searches'];

  // map to store x and y labels for each data source
  // TODO: group by type (color code for each type of age range, health focus, resource type)
  final Map<String, Map<String, String>> dataSourceLabels = {
    'Total Site Visits': {'xLabel': 'Date', 'yLabel': 'Number Of Visits'},
    'Clicks to Offsite Links': {'xLabel': 'Date', 'yLabel': 'Number Of Clicks'},
    'Age Range Searches': {'xLabel': 'Date', 'yLabel': 'Number Of Searches'},
    'Searches per Health Focus': {'xLabel': 'Date', 'yLabel': 'Number Of Searches'},
    'Resource Type Searches': {'xLabel': 'Date', 'yLabel': 'Number Of Searches'},
  };

  // define all possible groups for each data source
  final Map<String, List<String>> allGroups = {
    'Total Site Visits': ['Total Site Visits'], // single group
    'Clicks to Offsite Links': ['url', 'phone', 'address'],
    'Age Range Searches': ['Under 18', '18-24', '24-65', '65+', 'All ages'],
    'Health Focus Searches': ['Focus Area 1', 'Focus Area 2', 'Focus Area 3'], // TODO: replace
    'Resource Type Searches': ['Online', 'In Person', 'App', 'Hotline', 'Event', 'Podcast'],
  };

  // create a set to keep track of used colors
  final Set<Color> usedColors = {};
  // create a predefined list of distinct colors for graphs
  final List<Color> predefinedColors = [
    Color(0xFF003a7d),
    Color(0xFF008dff),
    Color(0xFFff73b6),
    Color(0xFFc701ff),
    Color(0xFF4ecb8d),
    Color(0xFFff9d3a),
    Color(0xFFf9e858),
    Color(0xFFd83034)
    // add more colors if needed
  ];

  List<Map<String, dynamic>>? data;

  // function that exports the graph as PNG or PDF
  // TODO: is this similar to pdfDownload.dart, can it be incorporated?
  Future<void> exportGraph(BuildContext context) async {
    Uint8List? pngBytes;
    try {
      // capture the graph as an image
      RenderRepaintBoundary renderer = graphToExport.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await renderer.toImage();
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      pngBytes = byteData!.buffer.asUint8List();
    } catch (e) {
      print('Error capturing graph image: $e');
      return;
    }

    // export the graph based on the selected export type
    if (selectedExportType == 'PDF') {
      await exportAsPDF(pngBytes);
    } else if (selectedExportType == 'Image') {
      await exportAsImage(pngBytes);
    }
  }

  Future<void> exportAsPDF(Uint8List? pngBytes) async {
    try {
      final pdf = pw.Document();
      final imageProvider = pw.MemoryImage(pngBytes!);
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.topCenter,
              child: pw.Image(imageProvider),
            );
          },
        ),
      );
      final pdfBytes = await pdf.save();
      final blob = html.Blob([pdfBytes], 'application/pdf');
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "graph.pdf")
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error exporting graph as PDF: $e');
    }
  }

  Future<void> exportAsImage(Uint8List? pngBytes) async {
    try {
      final blob = html.Blob([pngBytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "graph.png")
        ..click();
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error exporting graph as PNG: $e');
    }
  }

  Future<void> exportCSVData(BuildContext context, List<Map<String, dynamic>>? data) async {
    try {
      final csvData =await convertDataToCsv(data!);
      // create a blob with the CSV data
      final bytes = utf8.encode(csvData);
      final blob = html.Blob([Uint8List.fromList(bytes)], 'text/csv');
      final url = html.Url.createObjectUrlFromBlob(blob);

      // create an anchor element and simulate a click to download the file
      final anchor = html.AnchorElement(href: url)
        ..setAttribute("download", "data_export.csv")
        ..click();

      // revoke the object URL to free up memory
      html.Url.revokeObjectUrl(url);
    } catch (e) {
      print('Error exporting CSV file: $e');
    }
  }

  // function to fetch the resource name from resourceId
  Future<String?> getResourceName(resourceId) async {
    if(resourceId != null) {
      var doc = await FirebaseFirestore.instance.collection('resources').doc(
          resourceId).get();
      String? resourceName = doc.data()?['name'];
      return resourceName;
    }
    else {
      return "Unknown Resource"; // no resource name found
    }
  }

  // convert data to CSV format
  Future<String> convertDataToCsv(List<Map<String, dynamic>> data) async {
    List<List<dynamic>> rows = [];

    // add headers conditionally based on selected data source
    if (selectedData == 'Clicks to Offsite Links') {
      rows.add(['Timestamp', 'Group', 'Link', 'Resource Name']);

    } else {
      rows.add(['Timestamp', 'Group']); // no link header for other data sources
    }

    for (var item in data) {
      // format timestamp as ISO8601
      // check if timestamp exists and format it with a timezone indicator
      String formattedTimestamp = '';
      if (item['timestamp'] != null) {
        if (item['timestamp'] is DateTime) {
          // add timezone offset to ISO 8601 format
          DateTime timestamp = item['timestamp'];
          formattedTimestamp = timestamp.toUtc().toIso8601String();
        } else {
          DateTime timestamp = DateTime.parse(item['timestamp'].toString());
          formattedTimestamp = timestamp.toUtc().toIso8601String();
        }
      }
      // determine group based on available keys
      String group = item.containsKey('Age Range') ? item['Age Range'] :
      item.containsKey('Type') ? item['Type'] :
      item.containsKey('type') ? item['type'] : 'Unknown';

      // get the link if it exists
      String link = item.containsKey('link') ? item['link'] : '';

      // initialize resource name
      String resourceName = '';

      // check if the event is 'clicked-link' and if there's a resourceId
      if(selectedData == 'Clicks to Offsite Links'){
        resourceName = await getResourceName(item['resourceId']) ?? '';  // fetch the resource name
      }


      // create the row of data
      List<dynamic> row = [formattedTimestamp, group];

      // include link and resource name only for 'Clicks to Offsite Links'
      if (selectedData == 'Clicks to Offsite Links') {
        row.add(link);
        row.add(resourceName);
      }
      rows.add(row);
    }
    // convert rows to CSV format
    return csv.ListToCsvConverter().convert(rows);
  }

  // function to fetch data from RRDBFilters
  // TODO: only done AGE RANGE, RESOURCE TYPE, CLICKS OFFSITE LINKS
  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      // check if data source is type or age
      if (selectedData == 'Resource Type Searches' ||
          selectedData == 'Age Range Searches') {
        // get documents in event log collection where event is filter
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('RRDBEventLog')
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .where('timestamp', isLessThanOrEqualTo: endDate)
            .where('event', isEqualTo: 'filter')
            .get();
        print("collected data");

        List<Map<String, dynamic>> data = [];

        // loop through each document in the query result
        querySnapshot.docs.forEach((doc) {
          // extract data from the document
          Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

          // if the selected data source is 'Resource Type Searches'
          if (selectedData == 'Resource Type Searches') {
            // check if the document's payload contains the 'Type' key
            if (docData['payload'] != null &&
                docData['payload'].containsKey('Type')) {
              Map<String, dynamic> validDocData = {
                'timestamp': doc['timestamp'].toDate(),
                'Type': docData['payload']['Type']
              };
              data.add(validDocData);
            }
          }
          // if the selected data source is 'Age Range Searches'
          if (selectedData == 'Age Range Searches') {
            // check if the document's payload contains the 'Age Range' key
            if (docData['payload'] != null &&
                docData['payload'].containsKey('Age Range')) {
              Map<String, dynamic> validDocData = {
                'timestamp': doc['timestamp'].toDate(),
                'Age Range': docData['payload']['Age Range']
              };
              data.add(validDocData);
            }
          }
        });
        print(data);
        return data;
      }
      // check if the selected data source is 'Clicks to Offsite Links'
      else if(selectedData == 'Clicks to Offsite Links')
      {
        // get documents in the event log collection where event is 'clicked-link'
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('RRDBEventLog')
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .where('timestamp', isLessThanOrEqualTo: endDate)
            .where('event', isEqualTo: 'clicked-link')
            .get();
        print("collected data");

        List<Map<String, dynamic>> data = [];

        querySnapshot.docs.forEach((doc) {
          Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;
          // check if the document's payload contains the 'link' key
          if (docData['payload'] != null &&
              docData['payload'].containsKey('link')) {
            // create a map with timestamp, type, link, and resourceId data and add it to the list
            Map<String, dynamic> validDocData = {
              'timestamp': doc['timestamp'].toDate(),
              'type': docData['payload']['type'],
              'link': docData['payload']['link'],
              'resourceId': docData['payload']['resourceId']
            };
            data.add(validDocData);
          }
        });
        print(data);
        return data;
      }
      else {
        return []; // empty list if no data source matches
      }
    }
    catch (e) {
      print("error: $e");
    }
    return [];
  }

  // function to get x label based on selected data source
  String getXLabel(String selectedData) {
    return dataSourceLabels[selectedData]!['xLabel']!;
  }

  // function to get y label based on selected data source
  String getYLabel(String selectedData) {
    return dataSourceLabels[selectedData]!['yLabel']!;
  }

  Future<void> selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(
        start: startDate ?? DateTime.now(),
        end: endDate ?? DateTime.now(),
      ),
      builder: (BuildContext context, Widget? child) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Dialog(
              child: Container(
                width: constraints.maxWidth * 0.5,
                height: constraints.maxHeight * 0.7,
                child: child,
              ),
            );
          },
        );
      },
    );
    if (pickedDateRange != null) {
      setState(() {
        startDate = pickedDateRange.start;
        endDate = pickedDateRange.end;
      });
    }
  }

  void showExportDialog() {
    if(data != null && data!.isNotEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          final screenWidth = MediaQuery
              .of(context)
              .size
              .width;
          final isSmallScreen = screenWidth < 600;
          // variables to manage selection and export type
          String? selectedOption = 'Graph';
          String? selectedExportType = exportTypes.isNotEmpty ? exportTypes
              .first : null;

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return AlertDialog(
                title: Text('Export Settings'),
                content: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: isSmallScreen ? screenWidth * 0.9 : screenWidth *
                        0.8,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // chips for selecting between Graph and Data
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FilterChip(
                              label: Text('Graph',
                                  style: TextStyle(
                                      color: selectedOption == 'Graph' ? Colors
                                          .white : Colors.black)),
                              selected: selectedOption == 'Graph',
                              onSelected: (bool selected) {
                                setState(() {
                                  selectedOption = 'Graph';
                                });
                              },
                            ),
                            SizedBox(width: 8),
                            FilterChip(
                              label: Text('Data (CSV)',
                                  style: TextStyle(
                                      color: selectedOption == 'Data (CSV)'
                                          ? Colors.white
                                          : Colors.black)),
                              selected: selectedOption == 'Data (CSV)',
                              onSelected: (bool selected) {
                                setState(() {
                                  selectedOption = 'Data (CSV)';
                                });
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: 16.0),
                        if (selectedOption == 'Graph')
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16.0),
                                  child: DropdownButton<String>(
                                    value: selectedExportType,
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        selectedExportType = newValue;
                                      });
                                    },
                                    items: exportTypes
                                        .map<DropdownMenuItem<String>>((
                                        String value) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (selectedOption == 'Graph') {
                        exportGraph(context);
                      } else {
                        exportCSVData(context, data);
                      }
                      Navigator.of(context).pop();
                    },
                    child: Text('Export'),
                  ),
                ],
              );
            },
          );
        },
      );
    }
    else {
      // no data is available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No data available to export')),
      );
    }
  }


  // function that creates a pop-up for adjusting graphing settings
  // date range, chart type, data source
  void showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final screenWidth = MediaQuery.of(context).size.width;
        final isSmallScreen = screenWidth < 600;
        return AlertDialog(
          title: Text('Chart Settings'),
          content: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenWidth * 0.9 : screenWidth * 0.8,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return ElevatedButton(
                        onPressed: () async {
                          await selectDateRange(context);
                          // after selecting the date range, update the button text
                          setState(() {});
                        },
                        child: Text(
                          (startDate != null && endDate != null)
                              ? 'Selected Date Range: ${DateFormat('yyyy-MM-dd').format(startDate!)} - ${DateFormat('yyyy-MM-dd').format(endDate!)}'
                              : 'Select Date Range',
                        ),
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 16.0),
                    child: isSmallScreen
                        ? Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: DropdownButtonFormField<String>(
                            decoration:
                            InputDecoration(labelText: 'Chart Type'),
                            value: selectedChartType,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedChartType = newValue;
                                });
                              }
                            },
                            items: chartTypes
                                .map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: DropdownButtonFormField<String>(
                            decoration:
                            InputDecoration(labelText: 'Data Source'),
                            value: selectedData,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedData = newValue;
                                });
                              }
                            },
                            items: dataSources
                                .map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    )
                        : Row(
                      children: [
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 16.0),
                            child: DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                  labelText: 'Chart Type'),
                              value: selectedChartType,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    selectedChartType = newValue;
                                  });
                                }
                              },
                              items: chartTypes
                                  .map<DropdownMenuItem<String>>(
                                      (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                            ),
                          ),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            decoration:
                            InputDecoration(labelText: 'Data Source'),
                            value: selectedData,
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedData = newValue;
                                });
                              }
                            },
                            items: dataSources
                                .map<DropdownMenuItem<String>>(
                                    (String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ElevatedButton(
                        onPressed: showSettingsDialog,
                        child: Text('Chart Settings'),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton(
                        onPressed: showExportDialog,
                        child: Text("Export"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: fetchData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    } else {
                      data = snapshot.data;
                      return RepaintBoundary(
                        key: graphToExport,
                        child: buildChart(selectedChartType, data!),
                      );
                    }
                  },
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/top10resources');
                },
                child: Text("See Top 10 Resources"),
              ),
            ),
          ],
        ),
      ),
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
  List<GraphDataPoint> processDataWithBuckets(
      List<Map<String, dynamic>> data,
      Duration bucketSize,
      DateTime startDate,
      DateTime endDate) {
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
      // get the start and end dates for buckets
      DateTime bucketStartDate = getBucketStartDate(bucketNumber, bucketSize, baseline);
      DateTime bucketEndDate = bucketStartDate.add(bucketSize).subtract(Duration(days: 1));

      // print the bucket details
      print('Bucket Number: $bucketNumber, Date Range: ${bucketStartDate.month}/${bucketStartDate.day}–${bucketEndDate.month}/${bucketEndDate.day}');

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

  double calculateXAxisInterval(Duration bucketSize) {
    // return the interval in terms of bucket numbers
    return 1.0; // each bucket is represented as a single unit (1 bucket = 1 interval)
  }

  // build the chart based on selected chart type
  Widget buildChart(String chartType, List<Map<String, dynamic>> data) {
    if (selectedData != 'Age Range Searches' &&
        selectedData != 'Resource Type Searches' &&
        selectedData != 'Clicks to Offsite Links') {
      return Center(
        child: Text(
          "No data available for '${selectedData}' at this time",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      );
    }
    // determine bucket size
    Duration bucketSize = getDynamicBucketSize(startDate!, endDate!);
    // process data into buckets
    List<GraphDataPoint> processedData = processDataWithBuckets(data, bucketSize, startDate!, endDate!);

    switch (chartType) {
      case 'Line Graph':
        return buildLineChart(processedData);
      case 'Bar Graph':
        return buildBarChart(processedData);
      case 'Pie Chart':
        return buildPieChart(processedData);
      default:
        return Container();
    }
  }

  // build a line chart widget using GraphDataPoints
  Widget buildLineChart(List<GraphDataPoint> data) {

    // sort data by bucket to ensure correct order
    data.sort((a, b) => a.bucket.compareTo(b.bucket));

    // group data points by their group
    Map<String, List<FlSpot>> groupedData = {};

    // get the list of all groups for the selectedData
    List<String> groups = allGroups[selectedData] ?? [];

    // create a map to store colors for each group
    Map<String, Color> groupColors = {};

    for (var group in groups) {
      groupedData[group] = [];
      // assign a unique color for each group
      groupColors[group] = predefinedColors[groupColors.length % predefinedColors.length];
    }

    // populate groupedData with the actual processed data
    for (var point in data) {
      if (!groupedData.containsKey(point.group)) {
        groupedData[point.group] = [];
        // assign a color
        Color color = predefinedColors[groupedData.length % predefinedColors.length];
        groupColors[point.group] = color;
      }
      groupedData[point.group]!.add(
        FlSpot(point.bucket.toDouble(), point.y),
      );
    }

    // TODO: show xaxis label
    // create a list of LineChartBarData for each group
    List<LineChartBarData> lines = groupedData.entries.map((entry) {
      return LineChartBarData(
        spots: entry.value,
        isCurved: true,
        preventCurveOverShooting: true,
        barWidth: 1,
        dotData: FlDotData(show: true),
        belowBarData: BarAreaData(show: false),
        color: groupColors[entry.key],
      );
    }).toList();

    // get the corresponding labels for the selected data source
    String xLabel = getXLabel(selectedData);
    String yLabel = getYLabel(selectedData);

    // prepare LineChartData
    LineChartData chartData = LineChartData(
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(tooltipBgColor: Colors.grey[300]!),
      ),
      lineBarsData: lines,
      titlesData: FlTitlesData(
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              // map bucket number back to start date for labeling
              DateTime bucketStart = getBucketStartDate(
                value.toInt(),
                getDynamicBucketSize(startDate!, endDate!),
                startDate!,
              );
              DateTime bucketEnd = bucketStart.add(getDynamicBucketSize(startDate!, endDate!)).subtract(Duration(days: 1)); // inclusive end
              // truncate bucketEnd if it exceeds the selected endDate
              if (bucketEnd.isAfter(endDate!)) {
                bucketEnd = endDate!;
              }

              // check if the bucket is a single day
              String formattedDateRange;
              if (bucketStart == bucketEnd) {
                // single-day bucket format
                formattedDateRange = '${bucketStart.month}/${bucketStart.day}';
              } else {
                // multi-day bucket range
                formattedDateRange = '${bucketStart.month}/${bucketStart.day}–${bucketEnd.month}/${bucketEnd.day}';
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(formattedDateRange, style: TextStyle(fontSize: 12)),
              );
            },
            interval: 1,
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          axisNameWidget: Padding(
            padding: const EdgeInsets.only(left: 6.0),
            child: Text(yLabel, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),),

          ),
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toInt()}',
                style: TextStyle(fontSize: 12),
              );
            },
            interval: calculateYAxisInterval(data),
          ),
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        verticalInterval: 1.0, // interval for integer buckets
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 1,
        ),
        drawHorizontalLine: true,
        horizontalInterval: calculateYAxisInterval(data),
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 1,
        ),
      ),
      borderData: FlBorderData(show: true),
    );

    // create legend widgets for the groups
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

    // return a line chart widget with title and key
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    selectedData,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: LineChart(chartData),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: keyWidgets,
          ),
        ),
      ],
    );
  }

  Widget buildBarChart(List<GraphDataPoint> data) {
    
    // sort data by bucket to ensure correct order
    data.sort((a, b) => a.bucket.compareTo(b.bucket));

    // group data by buckets
    Map<int, Map<String, double>> groupedData = {};
    for (var point in data) {
      groupedData[point.bucket] ??= {};
      groupedData[point.bucket]![point.group] = point.y;
    }

    // get the list of all groups for the selectedData
    List<String> groups = allGroups[selectedData] ?? [];

    // assign colors for each group
    Map<String, Color> groupColors = {};
    for (var group in groups) {
      groupColors[group] = predefinedColors[groupColors.length % predefinedColors.length];
    }

    // dynamically calculate bar width based on the number of buckets and chart space
    int totalBuckets = groupedData.keys.length;
    double chartWidth = MediaQuery.of(context).size.width * 0.8; 
    double maxBarWidth = chartWidth / (totalBuckets * groups.length + totalBuckets - 1); // allow space for bars and groups
    double barWidth = maxBarWidth.clamp(1.0, 20.0); // limit bar width between 1 and 20


     List<BarChartGroupData> barGroups = groupedData.entries.map((entry) {
    int bucket = entry.key;
    Map<String, double> groupCounts = entry.value;

    // create a bar for each group in the bucket
    List<BarChartRodData> rods = groups.map((group) {
      return BarChartRodData(
        toY: groupCounts[group] ?? 0,
        color: groupColors[group],
        width: barWidth, // set bar width
        borderRadius: BorderRadius.circular(4),
      );
    }).toList();

    return BarChartGroupData(
      x: bucket,
      barRods: rods,
      barsSpace: barWidth * 0.2,
    );
  }).toList();

  BarChartData barChartData = BarChartData(
    barGroups: barGroups,
    groupsSpace: barWidth * 0.5, // space between groups
    titlesData: FlTitlesData(
      topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
           // map bucket number back to start date for labeling
              DateTime bucketStart = getBucketStartDate(
                value.toInt(),
                getDynamicBucketSize(startDate!, endDate!),
                startDate!,
              );
              DateTime bucketEnd = bucketStart.add(getDynamicBucketSize(startDate!, endDate!)).subtract(Duration(days: 1)); // inclusive end
              // truncate bucketEnd if it exceeds the selected endDate
              if (bucketEnd.isAfter(endDate!)) {
                bucketEnd = endDate!;
              }
              String formattedDateRange;
              if (bucketStart == bucketEnd) {
                // single-day bucket format
                formattedDateRange = '${bucketStart.month}/${bucketStart.day}';
              } else {
                // multi-day bucket range
                formattedDateRange = '${bucketStart.month}/${bucketStart.day}–${bucketEnd.month}/${bucketEnd.day}';
              }

              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(formattedDateRange, style: TextStyle(fontSize: 12)),
              );
            },
            interval: 1,
        ),
      ),
      rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      leftTitles: AxisTitles(
        axisNameWidget: Text(
          getYLabel(selectedData),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.0),
        ),
        sideTitles: SideTitles(
          showTitles: true,
          getTitlesWidget: (value, meta) {
            return Text(
              '${value.toInt()}',
              style: TextStyle(fontSize: 12),
            );
          },
          interval: calculateYAxisInterval(data),
        ),
      ),
    ),
    gridData: FlGridData(
      show: true,
        drawVerticalLine: true,
        verticalInterval: 1.0, // interval for integer buckets
        getDrawingVerticalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 1,
        ),
        drawHorizontalLine: true,
        horizontalInterval: calculateYAxisInterval(data),
        getDrawingHorizontalLine: (value) => FlLine(
          color: Colors.grey.withOpacity(0.3),
          strokeWidth: 1,
        ),
    ),
    borderData: FlBorderData(show: true),
    barTouchData: BarTouchData(
       touchTooltipData: BarTouchTooltipData(
         tooltipBgColor: Colors.grey[300]!,
         getTooltipItem: (group, groupIndex, rod, rodIndex)
         {
          if (rod.toY == 0) {
            return null;
          }
          return BarTooltipItem(
           '${rod.toY.toInt()}',
        TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
        );
         }
       ),
   
        handleBuiltInTouches: true, 
    )
  );

  // create legend
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

  // return the bar chart widget
  return Row(
    children: [
      Expanded(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: Center(
                child: Text(
                  selectedData,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            Expanded(
              child: BarChart(barChartData),
            ),
          ],
        ),
      ),
      Container(
        padding: EdgeInsets.symmetric(vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: keyWidgets,
        ),
      ),
    ],
  );
}


  // TODO: scatter, pie?
  Widget buildPieChart(List<GraphDataPoint> data) {
    // calculate total count for each group
    Map<String, double> groupTotals = {};
    for (var point in data) {
      groupTotals[point.group] = (groupTotals[point.group] ?? 0) + point.y;
    }
    // assign colors for each group
    Map<String, Color> groupColors = {};
    List<String> groups = allGroups[selectedData] ?? [];
    for (var group in groups) {
      groupColors[group] = predefinedColors[groupColors.length % predefinedColors.length];
    }

     // Create PieChartSectionData for each group
    List<PieChartSectionData> sections = groupTotals.entries.map((entry) {
      double percentage = (entry.value / groupTotals.values.reduce((a, b) => a + b)) * 100;
      return PieChartSectionData(
        color: groupColors[entry.key],
        value: entry.value,
        title: '${percentage.toStringAsFixed(1)}%',
        radius: 150,
        titleStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    // Create legend
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

    // Return PieChart with legend
    return Row(
      children: [
        Expanded(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Text(
                    selectedData,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              Expanded(
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    centerSpaceRadius: double.infinity,
                    sectionsSpace: 2,
                    borderData: FlBorderData(show: false),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: keyWidgets,
          ),
        ),
      ],
    );
  }
}

// class representing a data point for a graph
class GraphDataPoint {
  // x,y coordinates of data point and the group that the point belongs to
  final int bucket; // use bucket number as x int value
  final double y;
  final String group;

  // initialize GraphDataPoint instance
  GraphDataPoint({required this.bucket, required this.y, required this.group});
}