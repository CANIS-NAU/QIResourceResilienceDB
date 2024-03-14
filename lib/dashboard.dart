import 'package:flutter/material.dart';
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

class _DashboardState extends State<Dashboard>
{
  List<FlSpot> dummyLineChartData = List.generate( 7, (index) {
    return FlSpot( index.toDouble(), index * 10 );
  }); // Linear dummy data

  List<BarChartGroupData> dummyBarChartData = List.generate(7, (index) {
    return BarChartGroupData(x: index, barRods: [BarChartRodData(fromY: index * 10, toY: 100)]);
  }); // Bar chart dummy data

  final List<String> chartTypes = ['Line', 'Bar', 'Pie'];
  String selectedChartType = "Line";

  String selectedExportType = 'PDF';
  final List<String> exportTypes = ['PDF', 'Image', 'CSV'];

  String selectedData = 'Total Searches';
  final List<String> dataSources = ['Total Searches', 'Searches per Age Range', 'Searches per Health Focus', 'Searches per Resource Type'];

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
                    SizedBox(height: 20.0),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(25),
                        child: _buildChart(selectedChartType),
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
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildChart(String chartType) {
    switch (chartType) {
      case 'Line':
        return LineChart(
          LineChartData(
            lineBarsData: [
              LineChartBarData(
                spots: dummyLineChartData,
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
            alignment: BarChartAlignment.center,
            barGroups: dummyBarChartData,
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

  SideTitles get _bottomTitles => SideTitles(
        showTitles: true,
        getTitlesWidget: (value, meta) {
          String text = '';
          switch (value.toInt()) {
            case 0:
              text = 'Mon';
              break;
            case 1:
              text = 'Tue';
              break;
            case 2:
              text = 'Wen';
              break;
            case 3:
              text = 'Thu';
              break;
            case 4:
              text = 'Fri';
              break;
            case 5:
              text = 'Sat';
              break;
            case 6:
              text = 'Sun';
              break;
            default:
              return Container();
          }
          return Text(text);
        },
      );
}
