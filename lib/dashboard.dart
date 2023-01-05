import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:fl_chart/fl_chart.dart';

class Dashboard extends StatelessWidget
{
  List<FlSpot> dummyData = List.generate( 7, (index) {
    return FlSpot( index.toDouble(), index * 10 );
  }); // Linear dummy data

  //change values on health focus or age bracket

  @override
  Widget build(BuildContext context) 
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: LayoutBuilder( builder: ( context, windowSize ) {
        return Container(
          child: new Stack(
            children: [
              Text(
                "Welcome Back, User!", // ${ username }
                style: TextStyle( fontSize: 30.0 ),
              ),
              Container(
                height: windowSize.maxHeight / 2.5,
                width: windowSize.maxWidth / 3,
                padding: EdgeInsets.only( top: windowSize.maxHeight / 10, left: windowSize.maxWidth / 70 ),
                child:
                LineChart(
                  LineChartData(
                    lineBarsData: [
                      LineChartBarData(
                        belowBarData: BarAreaData(show: true),
                        spots: dummyData,
                        isCurved: false,
                        dotData: FlDotData(
                          show: true,
                        ),
                        color: Colors.blue,
                      ),
                    ],
                    gridData: FlGridData( show: false ),
                    titlesData: FlTitlesData(
                      bottomTitles: AxisTitles( sideTitles: _bottomTitles, axisNameWidget:Text('Day'), ),
                      leftTitles: AxisTitles( sideTitles: SideTitles( showTitles: false ), axisNameWidget: Text('Number Of Searches') ),
                      topTitles: AxisTitles( sideTitles: SideTitles( showTitles: false ), axisNameWidget: Text('Number Of Searches Per Day') ),
                      rightTitles: AxisTitles( sideTitles: SideTitles( showTitles: false ) ),
                    ),
                  ),
                  swapAnimationDuration: Duration( milliseconds: 150 ),
                  swapAnimationCurve: Curves.linear,
                ),
              ),
              Container(
                padding: EdgeInsets.only( top: windowSize.maxHeight / 2.5, left: windowSize.maxWidth / 75 ),
                width: windowSize.maxWidth / 3,
                child:
                  Row(
                    children: [
                      Expanded(
                        child:
                          Container(
                            padding: EdgeInsets.only( right: windowSize.maxWidth / 100, left: 0 ),
                            //margin: EdgeInsets.only(right: 0, left: 1200),
                            width: windowSize.maxWidth / 1000,
                            child: 
                              TextButton(
                                style: ButtonStyle(
                                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                                  backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                      side: BorderSide(color: Colors.blue)
                                    )
                                  )
                                ),
                                onPressed: () { 
                                
                                },
                                child: Text('Searches Per Day'),
                              ),
                        ),
                      ),
                      Expanded(
                        child:
                        Container(
                            padding: EdgeInsets.only( right: windowSize.maxWidth / 100, left: 0 ),
                            //margin: EdgeInsets.only(right: 0, left: 1200),
                            width: windowSize.maxWidth / 1000,
                            child: 
                              TextButton(
                                style: ButtonStyle(
                                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                                  backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                      side: BorderSide(color: Colors.blue)
                                    )
                                  )
                                ),
                                onPressed: () { 
                                
                                },
                                child: Text('Searches Per Health Focus Per Day'),
                              ),
                        ),
                      ),
                      Expanded(
                        child:
                        Container(
                            padding: EdgeInsets.only( right: windowSize.maxWidth / 100, left: 0 ),
                            //margin: EdgeInsets.only(right: 0, left: 1200),
                            width: windowSize.maxWidth / 1000,
                            child: 
                              TextButton(
                                style: ButtonStyle(
                                  foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                                  backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                                  shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18.0),
                                      side: BorderSide(color: Colors.blue)
                                    )
                                  )
                                ),
                                onPressed: () { 
                                
                                },
                                child: Text('Searches Per Age Range Per Day'),
                              ),
                        ),
                      ),
                    ],
                  ),
              ),
            ],
          ),
        );
       }
      )
    );
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
        return Text( text );
      },
    );
}