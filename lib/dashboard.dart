import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as Math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class DummyData {
  static List<FlSpot> generateDummyLineChartDataWithDates(int days) {
    List<FlSpot> data = [];
    DateTime currentDate = DateTime.now();
    for (int i = 0; i < days; i++) {
      data.add(FlSpot(i.toDouble(), i * 10));
      currentDate = currentDate.subtract(Duration(days: 1));
    }
    return data.reversed.toList();
  }

  static List<BarChartGroupData> generateDummyBarChartDataWithDates(int days) {
    List<BarChartGroupData> data = [];
    DateTime currentDate = DateTime.now();
    for (int i = 0; i < days; i++) {
      List<BarChartRodData> rods = [];
      for (int j = 0; j < 3; j++) {
        rods.add(BarChartRodData(
          fromY: 0,
          toY: i * (10 + j * 5),
        ));
      }
      data.add(BarChartGroupData(
        x: i,
        barRods: rods,
      ));
      currentDate = currentDate.subtract(Duration(days: 1));
    }
    return data.reversed.toList();
  }

  static List<ScatterSpot> generateDummyScatterPlotDataWithDates(int days) {
    List<ScatterSpot> data = [];
    for (int i = 0; i < days; i++) {
      // Generate random coordinates for each day
      double x = i.toDouble(); // X-coordinate
      double y = Math.Random().nextDouble() * 100; // Y-coordinate (random value between 0 and 100)
      data.add(ScatterSpot(x, y));
    }
    return data;
  }
}

class _DashboardState extends State<Dashboard>
{
  DateTime? startDate;
  DateTime? endDate;

  Widget? graphWidget;

  List<FlSpot> dummyLineChartData = DummyData.generateDummyLineChartDataWithDates(7);

  List<BarChartGroupData> dummyBarChartData = DummyData.generateDummyBarChartDataWithDates(7);

  List<ScatterSpot> dummyScatterPlotData = DummyData.generateDummyScatterPlotDataWithDates(7);

  final List<String> chartTypes = ['Line', 'Bar', 'Scatter Plot'];
  String selectedChartType = "Line";

  String selectedExportType = 'PDF';
  final List<String> exportTypes = ['PDF', 'Image'];

  String selectedData = 'Total Site Visits';
  final List<String> dataSources = ['Total Site Visits', 'Clicks to Offsite Links',
    'Searches per Age Range', 'Searches per Health Focus', 'Searches per Resource Type'];

  // map to store x and y labels for each data source
  // TODO: group by type (color code for each type of age range, health focus, resource type)
  final Map<String, Map<String, String>> dataSourceLabels = {
    'Total Site Visits': {'xLabel': 'Day', 'yLabel': 'Number Of Visits'},
    'Clicks to Offsite Links': {'xLabel': 'Day', 'yLabel': 'Number Of Clicks'},
    'Searches per Age Range': {'xLabel': 'Day', 'yLabel': 'Number Of Searches'},
    'Searches per Health Focus': {'xLabel': 'Day', 'yLabel': 'Number Of Searches'},
    'Searches per Resource Type': {'xLabel': 'Day', 'yLabel': 'Number Of Searches'},
  };

  // Function to get x label based on selected data source
  String getXLabel(String selectedData) {
    return dataSourceLabels[selectedData]!['xLabel']!;
  }

  // Function to get y label based on selected data source
  String getYLabel(String selectedData) {
    return dataSourceLabels[selectedData]!['yLabel']!;
  }

  // function to show date picker for start date
  Future<void> selectStartDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: startDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != startDate) {
      setState(() {
        startDate = pickedDate;
        print(startDate);
      });
    }
  }

  // function to show date picker for end date
  Future<void> selectEndDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: endDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null && pickedDate != endDate) {
      setState(() {
        endDate = pickedDate;
      });
    }
  }

  // function that depending on the selected export type, exports the graph as PNG or PDF
  Future<void> exportGraph(BuildContext context) async {
    if (selectedExportType == 'PDF') {
      // // export the graph as PDF
      // final pdf = pw.Document();
      // pdf.addPage(pw.Page(
      //   build: (pw.Context context) {
      //     return pw.Center(
      //       child:pw.Container(
      //         width: 500,
      //         height: 300,
      //         child: graphWidget,
      //       ),
      //     );
      //   },
      // ),
      // );
      // // Save the PDF file
      // final output = await File('graph.pdf').writeAsBytes(await pdf.save());

      print('Exporting graph as PDF...');
    } else if (selectedExportType == 'Image') {
      // export the graph as PNG

      print('Exporting graph as PNG...');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: LayoutBuilder(builder: (context, windowSize) {
        return Container(
          padding: EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome Back, User!", // ${ username }
                      style: TextStyle(fontSize: 25.0),
                    ),
                    Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 5, top: 10, right: 5, bottom: 0),
                          child: ElevatedButton(
                            onPressed: () => selectStartDate(context),
                            child: Text(startDate != null
                                ? 'Start Date: ${DateFormat('yyyy-MM-dd').format(startDate!)}'
                                : 'Select Start Date'),
                          ),
                        ),
                        SizedBox(width: 10),
                        Padding(
                          padding: EdgeInsets.only(left: 5, top: 10, right: 5, bottom: 0),
                          child: ElevatedButton(
                            onPressed: () => selectEndDate(context),
                            child: Text(endDate != null
                                ? 'End Date: ${DateFormat('yyyy-MM-dd').format(endDate!)}'
                                : 'Select End Date'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20.0),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: graphWidget = _buildChart(selectedChartType, startDate, endDate),
                      )
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(25),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Chart Type'),
                          value: selectedChartType,
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                selectedChartType = newValue;
                              });
                            }
                          },
                          items: chartTypes
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.2,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Data Source'),
                        value: selectedData,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedData = newValue;
                            });
                          }
                        },
                        items: dataSources
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20),
                    SizedBox(width: MediaQuery.of(context).size.width * 0.2,
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(labelText: 'Export Type'),
                        value: selectedExportType,
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            setState(() {
                              selectedExportType = newValue;
                            });
                          }
                        },
                        items: exportTypes
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.1,
                        child: ElevatedButton(
                          onPressed: () => exportGraph(context),
                          child: Text("Export"),
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/top10resources');
                        },
                        child: Text("See Top 10 Resources"),
                      )
                    )
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChart(String chartType, DateTime? startDate, DateTime? endDate) {
    // filter data based on the selected date range
    List<FlSpot> filteredLineChartData = [];
    List<BarChartGroupData> filteredBarChartData = [];
    List<ScatterSpot> filteredScatterData = [];
    for (int i = 0; i < dummyLineChartData.length; i++) {
      if (startDate != null && endDate != null) {
        if (i >= startDate.weekday - 1 && i <= endDate.weekday - 1) {
          filteredLineChartData.add(dummyLineChartData[i]);
          filteredBarChartData.add(dummyBarChartData[i]);
          filteredScatterData.add(dummyScatterPlotData[i]);
        }
      } else {
        // if no date range is selected, use all data
        filteredLineChartData = dummyLineChartData;
        filteredBarChartData = dummyBarChartData;
        filteredScatterData = dummyScatterPlotData;
        break;
      }
    }
    String xLabel = getXLabel(selectedData);
    String yLabel = getYLabel(selectedData);

    switch (chartType) {
      case 'Line':
        return LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: filteredLineChartData,
                isCurved: false,
                dotData: FlDotData(show: true),
                color: Colors.blue,
              ),
            ],
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitles,
                axisNameWidget: Text(xLabel),
              ),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                  axisNameWidget: Text(yLabel)),
              //${ leftLabelText }
              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                  axisNameWidget: Text('$yLabel Per Day')),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          ),
          swapAnimationDuration: Duration(milliseconds: 150),
          swapAnimationCurve: Curves.linear,
        );
      case 'Bar':
        return BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween,
            barGroups: filteredBarChartData,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitles,
                axisNameWidget: Text(xLabel),
              ),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                  axisNameWidget: Text(yLabel)),
              //${ leftLabelText }
              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                  axisNameWidget: Text('$yLabel Per Day')),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          ),
        );
      case 'Scatter Plot':
        return ScatterChart(
          ScatterChartData(
            scatterSpots: filteredScatterData,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitles,
                axisNameWidget: Text(xLabel),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
                axisNameWidget: Text(yLabel),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
                axisNameWidget: Text('$yLabel Per Day'),
              ),
              rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          ),
        );
      default:
        return Container();
    }
  }

  // todo: FIX so show correct dates
  SideTitles get _bottomTitles => SideTitles(
        showTitles: false,
        getTitlesWidget: (value, meta) {
          DateTime date = startDate!.add(Duration(days: value.toInt()));
          return Text(DateFormat('MM-dd').format(date));
          }
  );
}
