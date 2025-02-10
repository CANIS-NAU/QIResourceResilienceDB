import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'view_resource/resource_detail.dart';
import 'package:web_app/Analytics.dart';

class Top10Resources extends StatefulWidget {
  @override
  _TopResourcesState createState() => _TopResourcesState();
}

class _TopResourcesState extends State<Top10Resources> {
  // list of top resources
  List<ResourceData> topResources = [];

  // start and end date filters
  DateTime startDate = DateTime(2000, 1, 1);
  DateTime endDate = DateTime.now();

  // loading state
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    getTopResources();
  }

  // function to show date range picker
  Future<void> selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), // earliest date
      lastDate: DateTime.now(),  // latest date
      initialDateRange: DateTimeRange(
        start: startDate, // default start date to display
        end: endDate, // default end date to display
      ),
      builder: (BuildContext context, Widget? child) {
        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            return Dialog(
              child: Container(
                width: constraints.maxWidth * 0.5,
                height: constraints.maxHeight * 0.5,
                child: child,
              ),
            );
          },
        );
      },
    );

    // if there is a date range
    if (pickedDateRange != null) {
      setState(() {
        // set the start and end dates to the selected date
        startDate = pickedDateRange.start;
        endDate = pickedDateRange.end;
        // get the top resources based on new dates selected
        getTopResources();
      });
    }
  }

  // function to fetch resource clicks and process them to get a list of the top
  // 10 resources clicked within a date range
  Future<void> getTopResources() async {
    // set loading state to true
    setState(() {
      isLoading = true;
    });

    // define the start and end dates for filtering
    DateTime? startDateFilter = startDate;
    DateTime? endDateFilter = endDate;

    // retrieve data from firebase with date filters
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance.collection('RRDBEventLog')
        .where('timestamp', isGreaterThanOrEqualTo: startDateFilter)
        .where('timestamp', isLessThanOrEqualTo: endDateFilter)
        .where('event', isEqualTo: 'clicked-resource')
        .get();

    // map to store resource ids and their click counts
    Map<String, int> resourceClickCounts = {};

    // iterate through documents to count clicks per resource
    querySnapshot.docs.forEach((doc) {
      final resourceId = doc['payload']['resource'] as String;
      resourceClickCounts.update(resourceId, (value) => value + 1, ifAbsent: () => 1);
    });

    // sort the resources based on the number of clicks
    List<MapEntry<String, int>> sortedResources = resourceClickCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // get the top 10 resources, or less if there are fewer than 10
    List<String> topResourceIds = sortedResources.map((entry) => entry.key).toList();
    if (topResourceIds.length > 10) {
      topResourceIds = topResourceIds.take(10).toList();
    }

    // retrieve resource details (name) from firebase based on resource ids
    List<ResourceData> topResourcesData = [];
    for (String resourceId in topResourceIds) {
      final DocumentSnapshot resourceSnapshot = await FirebaseFirestore.instance
          .collection('resources')
          .doc(resourceId)
          .get();
      if (resourceSnapshot.exists) {
        final resourceName = resourceSnapshot['name'] as String;
        // handle any data inconsistencies to ensure clicks in not null
        final clicks = resourceClickCounts[resourceId] ?? 0;
        topResourcesData.add(ResourceData(resourceId, resourceName, clicks));
      }
    }
    // update state with top resources data
    setState(() {
      topResources = topResourcesData;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Top 10 Resources'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            splashRadius: 20.0,
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          return Container(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: Column(
                children: [
                  // display page title
                  Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      "Top 10 Resources",
                      style: TextStyle(fontSize: 25.0),
                    ),
                  ),
                  // show date range selector
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 6, horizontal: 6),
                    child: ElevatedButton(
                      onPressed: () => selectDateRange(context),
                      child: Text('Date Range: ${DateFormat('yyyy-MM-dd').format(startDate!)} - ${DateFormat('yyyy-MM-dd').format(endDate)}'
                      ),
                    ),
                  ),
                  // display loading indicator if resources are loading
                  if (isLoading)
                    CircularProgressIndicator()
                  // display no resources available if there are no top 10 resources
                  // for the specified range
                  else if (topResources.isEmpty)
                    Text('No top resources available')
                  // otherwise, display each resource as a list tile
                  else
                    Padding(
                      padding: EdgeInsets.all(12),
                      child: Column(
                        children: [
                          Container( height: constraints.maxHeight - 250,
                            child: FocusTraversalGroup(
                              policy: OrderedTraversalPolicy(),
                              child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: topResources.length,
                                itemBuilder: (context, index){
                                  // display top resources as list tiles with rank(index)
                                  return TopResourceTile(resource: topResources[index], index: index, analytics: HomeAnalytics(),);
                                },
                              ),
                            ),)
                        ],
                      ),
                    )
                ],
              ),
            ),

          );}));
  }
}

// class to represent resource data (name and click count)
class ResourceData {
  final String resourceId;
  final String resourceName;
  final int clicks;

  ResourceData(this.resourceId, this.resourceName, this.clicks);
}

// display a resource in a list tile format
class TopResourceTile extends StatefulWidget {
  const TopResourceTile({
    Key? key,
    required this.resource,
    required this.index,
    required this.analytics,  // pass the analytics object
  }) : super(key: key);

  final ResourceData resource;
  final int index;
  final HomeAnalytics analytics;

  @override
  _TopResourceTileState createState() => _TopResourceTileState();
}

class _TopResourceTileState extends State<TopResourceTile> {
  Future<void> _showResourceDetails() async {
    try {
      // fetch the full resource details
      final DocumentSnapshot resourceSnapshot = await FirebaseFirestore.instance
          .collection('resources')
          .doc(widget.resource.resourceId)
          .get();

      if (resourceSnapshot.exists) {
        // display the ResourceDetail popup
        showDialog(
          context: context,
          builder: (context) => ResourceDetail(
            analytics: widget.analytics,
            resource: resourceSnapshot,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Resource not found!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching resource: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
        dense: false,
        leading: Text(
              '${widget.index + 1}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
        title: Text(
          widget.resource.resourceName,
           textAlign: TextAlign.left,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              softWrap: true,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
        ),
        subtitle:  Text(
              'Clicks: ${widget.resource.clicks}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
        ),
        trailing: IconButton(
          icon: Icon(Icons.arrow_forward),
          splashRadius: 20,
          onPressed: _showResourceDetails,
        ),
      ),
    );
  }
}