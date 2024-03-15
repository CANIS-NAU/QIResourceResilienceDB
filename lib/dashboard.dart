import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as Math;

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
          fromY: i * (10 + j * 5), toY: 100
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
}

class _DashboardState extends State<Dashboard>
{
  DateTime? startDate;
  DateTime? endDate;

  List<FlSpot> dummyLineChartData = DummyData.generateDummyLineChartDataWithDates(7);

  List<BarChartGroupData> dummyBarChartData = DummyData.generateDummyBarChartDataWithDates(7);

  final List<String> chartTypes = ['Line', 'Bar', 'Pie'];
  String selectedChartType = "Line";

  String selectedExportType = 'PDF';
  final List<String> exportTypes = ['PDF', 'Image'];

  String selectedData = 'Total Searches';
  final List<String> dataSources = ['Total Searches', 'Searches per Age Range', 'Searches per Health Focus', 'Searches per Resource Type'];

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
                        child: _buildChart(selectedChartType, startDate, endDate),
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
                    SizedBox(height: 30),
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.2,
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Text("See Top 10 Searches"),
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
    for (int i = 0; i < dummyLineChartData.length; i++) {
      if (startDate != null && endDate != null) {
        if (i >= startDate.weekday - 1 && i <= endDate.weekday - 1) {
          filteredLineChartData.add(dummyLineChartData[i]);
          filteredBarChartData.add(dummyBarChartData[i]);
        }
      } else {
        // if no date range is selected, use all data
        filteredLineChartData = dummyLineChartData;
        filteredBarChartData = dummyBarChartData;
        break;
      }
    }
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
                axisNameWidget: Text('Day'),
              ),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                  axisNameWidget: Text('Number Of Searches')),
              //${ leftLabelText }
              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                  axisNameWidget: Text('Number Of Searches Per Day')),
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
            alignment: BarChartAlignment.start,
            barGroups: filteredBarChartData,
            titlesData: FlTitlesData(
              bottomTitles: AxisTitles(
                sideTitles: _bottomTitles,
                axisNameWidget: Text('Day'),
              ),
              leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                  axisNameWidget: Text('Number Of Searches')),
              //${ leftLabelText }
              topTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                  axisNameWidget: Text('Number Of Searches Per Day')),
              rightTitles:
                  AxisTitles(sideTitles: SideTitles(showTitles: false)),
            ),
          ),
        );
      case 'Pie':
        return PieChart(
          PieChartData(
            sections: List.generate(4, (index) {
              return PieChartSectionData(value: 25, color: _getRandomColor());
            }),
          ),
        );
      default:
        return Container();
    }
  }

  Color _getRandomColor() {
    return Color((Math.Random().nextDouble() * 0xFFFFFF).toInt() << 0)
        .withOpacity(1.0);
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
