import 'package:flutter/material.dart';

class Top10Resources extends StatefulWidget {
  @override
  _TopResourcesState createState() => _TopResourcesState();
}

class _TopResourcesState extends State<Top10Resources> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Top 10 Resources'),
        ),
        body: LayoutBuilder(builder: (context, windowSize) {
      return Container(
          padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: [
              Text(
                "Top 10 Resources", // ${ username }
                style: TextStyle(fontSize: 25.0),
              ),
            ],
          ),
        ),

      );}));
  }
}