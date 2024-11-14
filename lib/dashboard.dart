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
  final List<String> chartTypes = ['Line', 'Bar', 'Scatter Plot'];
  String selectedChartType = "Line";

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

  Map<DateTime, Map<String, int>> countsPerDay(List<Map<String, dynamic>> data, String metricStr) {
    Map<DateTime, Map<String, int>> groupCounts = {};
    // loop each entry in the data list
    for (var entry in data) {
      // get the date and type
      DateTime date = DateTime(entry['timestamp'].year, entry['timestamp'].month, entry['timestamp'].day);
      String group = entry[metricStr];

      // if the date is not already in the list, add it
      if (!groupCounts.containsKey(date)) {
        groupCounts[date] = {};
      }
      // if the group is not in the list, add it
      if (!groupCounts[date]!.containsKey(group)) {
        groupCounts[date]![group] = 0;
      }
      // increment the count for this group on this day
      groupCounts[date]![group] = groupCounts[date]![group]! + 1;
    }
    return groupCounts;
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
          String? selectedOption = 'Graph'; // Default selected option
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
                        // Chips for selecting between Graph and Data
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
                          // After selecting the date range, update the button text
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

  // function to process data and group it into intervals based on date range
  List<GraphDataPoint> processData(List<Map<String, dynamic>> data) {
      // determine the interval using a helper function
      Duration interval = getIntervalBasedOnDateRange(startDate!, endDate!);
      print(interval);
      Map<DateTime, Map<String, int>> countsPerInterval = {};

      // initialize counts for each interval in the date range
      DateTime currentIntervalStart = startDate!;
      while (currentIntervalStart.isBefore(endDate!) || currentIntervalStart.isAtSameMomentAs(endDate!)) {
        countsPerInterval[currentIntervalStart] = {
          for (var group in allGroups[selectedData] ?? []) group: 0
        };
        print("Initialized interval ${currentIntervalStart} with groups: ${countsPerInterval[currentIntervalStart]}");
        currentIntervalStart = getNextIntervalStart(currentIntervalStart, interval);
      }

      // populate countsPerInterval with actual data from `data`
      data.forEach((entry) {
        if (entry['timestamp'] == null) return;
        DateTime timestamp = entry['timestamp'];
        DateTime intervalStart = getIntervalStart(timestamp, interval);

        // determine the group based on the selectedData type
        String? group;
        if (selectedData == 'Resource Type Searches') {
          group = entry['Type'];
        } else if (selectedData == "Age Range Searches") {
          group = entry['Age Range'];
        } else {
          group = entry['type'];
        }

        if (group == null) return;

        // initialize group count if missing and increment count
        countsPerInterval[intervalStart] ??= {};
        countsPerInterval[intervalStart]![group] = (countsPerInterval[intervalStart]![group] ?? 0) + 1;
        print("Processed entry for group '$group' on date ${timestamp}: interval ${intervalStart}, current count: ${countsPerInterval[intervalStart]![group]}");
      });

      // ensure all groups have zero counts for missing intervals
      List<String> groups = allGroups[selectedData] ?? [];
      countsPerInterval.forEach((date, groupCounts) {
        for (var group in groups) {
          if (!groupCounts.containsKey(group)) {
            groupCounts[group] = 0; // set zero count for missing group in this interval
          }
        }
      });

      // convert countsPerInterval to a list of GraphDataPoint objects
      List<GraphDataPoint> processedData = [];
      countsPerInterval.forEach((date, groupCounts) {
        groupCounts.forEach((group, count) {
          // Use millisecondsSinceEpoch to ensure consistency in time representation
          processedData.add(GraphDataPoint(x: date, y: count.toDouble(), group: group));
        });
      });

      return processedData;
    }

// get the start of the current interval based on the interval duration
  DateTime getIntervalStart(DateTime timestamp, Duration interval) {
    if (interval.inDays == 30) {
      return DateTime(timestamp.year, timestamp.month);
    } else if (interval.inDays == 7) {
      return timestamp.subtract(Duration(days: timestamp.weekday - 1));
    } else {
      return DateTime(timestamp.year, timestamp.month, timestamp.day);
    }
  }

// get the next interval start date based on the interval
  DateTime getNextIntervalStart(DateTime date, Duration interval) {
    if (interval.inDays == 30) {
      return DateTime(date.year, date.month + 1);
    } else if (interval.inDays == 7) {
      return date.add(Duration(days: 7));
    } else {
      return date.add(Duration(days: 1));
    }
  }

  // function to determine the interval based on the total date range
  Duration getIntervalBasedOnDateRange(DateTime startDate, DateTime endDate) {
    int totalDays = endDate.difference(startDate).inDays;

    if (totalDays >= 90) {
      return Duration(days: 30); // monthly intervals for ranges over 3 months
    } else if (totalDays >= 30) {
      return Duration(days: 7); // weekly intervals for ranges between 1 and 3 months
    } else {
      return Duration(days: 1); // daily intervals for ranges under 1 month
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

  double calculateXAxisInterval(List<DateTime> dateRange) {
    if (dateRange.isEmpty) return Duration(days: 1).inMilliseconds.toDouble();

    DateTime startDate = dateRange.first;
    DateTime endDate = dateRange.last;

    // get interval based on the date range
    Duration interval = getIntervalBasedOnDateRange(startDate, endDate);
    print(interval);

    // return the interval in milliseconds for the x-axis interval
    return interval.inMilliseconds.toDouble();
  }


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

    List<GraphDataPoint> processedData = processData(data);
    switch (chartType) {
      case 'Line':
        return buildLineChart(processedData);
      case 'Bar':
        return buildBarChart(processedData);
      case 'Scatter Plot':
        return buildScatterPlot(processedData);
      default:
        return Container();
    }
  }

  // build a line chart widget using GraphDataPoints
  Widget buildLineChart(List<GraphDataPoint> data) {

    // sort data by date first to ensure we can iterate efficiently
    data.sort((a, b) => a.x.compareTo(b.x));

    // group data points by their group
    Map<String, List<FlSpot>> groupedData = {};

    // get date range for the graph
    DateTime startDate = this.startDate!;
    DateTime endDate = this.endDate!;

    List<DateTime> dateRange = [];
    for (DateTime date = startDate;
    date.isBefore(endDate) || date.isAtSameMomentAs(endDate);
    date = date.add(Duration(days: 1))) {
      dateRange.add(date);
    }

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
        FlSpot(point.x.millisecondsSinceEpoch.toDouble(), point.y),
      );
    }

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
              DateTime date = DateTime.fromMillisecondsSinceEpoch(value.toInt());
              String formattedDate;
              Duration interval = getIntervalBasedOnDateRange(startDate!, endDate!);
              if (interval.inDays >= 30) {
                formattedDate = '${date.month}/${date.year}';
              } else if (interval.inDays >= 7) {
                formattedDate = '${date.month}/${date.day}';
              } else {
                formattedDate = '${date.month}/${date.day}';
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(formattedDate, style: TextStyle(fontSize: 12)),
              );
            },
            interval: calculateXAxisInterval(data.map((d) => d.x).toList()),
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
        verticalInterval: calculateXAxisInterval(data.map((d) => d.x).toList()),
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

  // TODO: implement bar chart
  Widget buildBarChart(List<GraphDataPoint> data) {
    return Container(child: Text('Bar chart under development'));
  }

  // TODO: scatter, pie?
  Widget buildScatterPlot(List<GraphDataPoint> data) {
    return Container(child: Text('Scatter plot under development'));
  }
}

// class representing a data point for a graph
class GraphDataPoint {
  // x,y coordinates of data point and the group that the point belongs to
  final DateTime x;
  final double y;
  final String group;

  // initialize GraphDataPoint instance
  GraphDataPoint({required this.x, required this.y, required this.group});
}