import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:html' as html;
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:csv/csv.dart' as csv;
import 'package:path_provider/path_provider.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}
class _DashboardState extends State<Dashboard>
{
  DateTime? startDate = DateTime.now().subtract(Duration(days: 30));
  DateTime? endDate = DateTime.now();

  final GlobalKey graphToExport = GlobalKey();
  Widget? graphWidget;

  final List<String> chartTypes = ['Line', 'Bar', 'Scatter Plot'];
  String selectedChartType = "Line";

  String selectedExportType = 'PDF';
  final List<String> exportTypes = ['PDF', 'Image'];

  String selectedData = 'Total Site Visits';
  final List<String> dataSources = ['Total Site Visits', 'Clicks to Offsite Links',
    'Age Range Searches', 'Health Focus Searches', 'Resource Type Searches'];

  // map to store x and y labels for each data source
  // TODO: group by type (color code for each type of age range, health focus, resource type)
  final Map<String, Map<String, String>> dataSourceLabels = {
    'Total Site Visits': {'xLabel': 'Date', 'yLabel': 'Number Of Visits'},
    'Clicks to Offsite Links': {'xLabel': 'Date', 'yLabel': 'Number Of Clicks'},
    'Searches per Age Range': {'xLabel': 'Date', 'yLabel': 'Number Of Searches'},
    'Searches per Health Focus': {'xLabel': 'Date', 'yLabel': 'Number Of Searches'},
    'Searches per Resource Type': {'xLabel': 'Date', 'yLabel': 'Number Of Searches'},
  };
  // create a set to keep track of used colors
  final Set<Color> usedColors = {};
  // create a predefined list of distinct colors for graphs
  final List<Color> predefinedColors = [
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.teal,
    Colors.pink,
    Colors.indigo,
    // add more colors as needed
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
      final csvData = convertDataToCsv(data!);
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

  // convert data to CSV format
  // TODO: get uuid with data?
  // TODO: Format time with timezone indicator
  String convertDataToCsv(List<Map<String, dynamic>> data) {
    List<List<dynamic>> rows = [];

    // add headers conditionally based on selected data source
    if (selectedData == 'Clicks to Offsite Links') {
      rows.add(['Timestamp', 'Group', 'Link']);

    } else {
      rows.add(['Timestamp', 'Group']); // no link header for other data sources
    }

    for (var item in data) {
      // format timestamp as ISO8601
      String formattedTimestamp = item['timestamp'] != null
          ? (item['timestamp'] is DateTime
          ? item['timestamp'].toIso8601String()
          : DateTime.parse(item['timestamp'].toString()).toIso8601String())
          : '';
      List<dynamic> row = [
        formattedTimestamp,
        item.containsKey('Age Range') ? item['Age Range'] :
        item.containsKey('Type') ? item['Type'] :
        item.containsKey('type') ? item['type'] : 'Unknown',
        item.containsKey('link') ? item['link'] : '',
      ];
      rows.add(row);
    }
    // convert rows to CSV format
    return csv.ListToCsvConverter().convert(rows);
  }

  // function to fetch data from RRDBFilters
  // TODO: only done AGE RANGE, RESOURCE TYPE, CLICKS OFFSITE LINKS
  Future<List<Map<String, dynamic>>> fetchData() async {
    try {
      if (selectedData == 'Resource Type Searches' ||
          selectedData == 'Age Range Searches') {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('RRDBEventLog')
            .where('timestamp', isGreaterThanOrEqualTo: startDate)
            .where('timestamp', isLessThanOrEqualTo: endDate)
            .where('event', isEqualTo: 'filter')
            .get();
        print("collected data");

        List<Map<String, dynamic>> data = [];

        querySnapshot.docs.forEach((doc) {
          Map<String, dynamic> docData = doc.data() as Map<String, dynamic>;

          if (selectedData == 'Resource Type Searches') {
            if (docData['payload'] != null &&
                docData['payload'].containsKey('Type')) {
              Map<String, dynamic> validDocData = {
                'timestamp': doc['timestamp'].toDate(),
                'Type': docData['payload']['Type']
              };
              data.add(validDocData);
            }
          }
          if (selectedData == 'Age Range Searches') {
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
      else if(selectedData == 'Clicks to Offsite Links')
        {
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
              if (docData['payload'] != null &&
                  docData['payload'].containsKey('link')) {
                Map<String, dynamic> validDocData = {
                  'timestamp': doc['timestamp'].toDate(),
                  'type': docData['payload']['type'],
                  'link': docData['payload']['link']
                };
                data.add(validDocData);
              }
          });
          print(data);
          return data;
        }
      else {
        return [];
      }
    }
    catch (e) {
      print("error: $e");
    }
    return [];
  }

// TODO: function to count number of items per group per day
  // 'type' for offsite, 'Type' for types of resources, and 'Age Range'
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

  // TODO: keep these! use to label axis when making graph
  // function to get x label based on selected data source
  String getXLabel(String selectedData) {
    return dataSourceLabels[selectedData]!['xLabel']!;
  }

  // function to get y label based on selected data source
  String getYLabel(String selectedData) {
    return dataSourceLabels[selectedData]!['yLabel']!;
  }

  // TODO: make smaller pop-up
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
                        // Conditional content based on selected option
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
      // Show a message if no data is available
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
                  ElevatedButton(
                    onPressed: () => selectDateRange(context),
                    child: Text(
                      (startDate != null && endDate != null)
                          ? 'Selected Date Range: ${DateFormat('yyyy-MM-dd').format(startDate!)} - ${DateFormat('yyyy-MM-dd').format(endDate!)}'
                          : 'Select Date Range',
                    ),
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
  // function to count the data per day, and get the formatted date
  List<GraphDataPoint> processData(List<Map<String, dynamic>> data) {
    Map<DateTime, Map<String, int>> countsPerDay = {};

    data.forEach((entry) {
      DateTime date = DateTime(entry['timestamp'].year,
          entry['timestamp'].month, entry['timestamp'].day);
      String group ='';
      if(selectedData == 'Resource Type Searches')
        {
          group = entry['Type'];
        }
      else if (selectedData == "Age Range Searches")
        {
         group = entry['Age Range'];
        }
      else {
       group = entry['type'];
       print(entry['type']);
      }

      if (!countsPerDay.containsKey(date)) {
        countsPerDay[date] = {};
      }
      countsPerDay[date]![group] = (countsPerDay[date]![group] ?? 0) + 1;
    });

    List<GraphDataPoint> processedData = [];
    countsPerDay.forEach((date, typeCounts) {
      typeCounts.forEach((group, count) {
        DateTime roundedDate = DateTime(date.year, date.month, date.day);
        processedData.add(
            GraphDataPoint(x: roundedDate, y: count.toDouble(), group: group));
      });
    });
    return processedData;
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
    // print the data to the console
    data.forEach((point) {
      print('Date: ${point.x}, Value: ${point.y}, Group: ${point.group}');
    });

    // return a container with printed data for debugging: TODO: will fix
    return Container(
      child: Text(
        data
            .map((point) => '(${point.x}, ${point.y}, ${point.group})')
            .join('\n'),
        style: TextStyle(fontSize: 16),
      ),
    );
  }

  // TODO: implement bar chart
  Widget buildBarChart(List<GraphDataPoint> data) {
    return Container(child: Text('Bar chart under development'));
  }

  // TODO: fl_chart does not support scatter, only pie
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