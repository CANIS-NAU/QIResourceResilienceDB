import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class Top10Resources extends StatefulWidget {
  @override
  _TopResourcesState createState() => _TopResourcesState();
}

class _TopResourcesState extends State<Top10Resources> {
  // list of top resources
  List<ResourceData> topResources = [];

  // start and end date filters
  DateTime? startDate;
  DateTime? endDate;

  // loading state
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // get the first data's date
    fetchDefaultDates();
  }

  // fetch the first data entry to set default dates
  Future<void> fetchDefaultDates() async {
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('RRDBClickedResources')
        .orderBy('timestamp')
        .limit(1)
        .get();

    // if there is data, set the start date to the first data entry and
    // the end date to the current date
    if (querySnapshot.docs.isNotEmpty) {
      setState(() {
        startDate = (querySnapshot.docs.first['timestamp'] as Timestamp).toDate();
        endDate = DateTime.now();
        // get the top clicked resources
        getTopResources();
      });
    }
  }

  // function to show date range picker
  Future<void> selectDateRange(BuildContext context) async {
    final DateTimeRange? pickedDateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000), // earliest date
      lastDate: DateTime.now(),  // latest date
      initialDateRange: DateTimeRange(
        start: startDate ?? DateTime.now(), // default start date to display
        end: endDate ?? DateTime.now(), // default end date to display
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

    //  check if either start date or end date is null
    if (startDate == null || endDate == null ) {
      setState(() {
        topResources = []; // clear existing top resources
        isLoading = false; // set loading state to false
      });
      return; // return if the date range is invalid
    }

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
    // TODO: get any other info we want to display for a resource on the top10 page
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
        topResourcesData.add(ResourceData(resourceName, clicks));
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
        ),
        body: LayoutBuilder(builder: (context, constraints) {
          bool isSmallScreen = constraints.maxWidth < 600;
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
                      child: Text(startDate != null && endDate != null
                          ? 'Date Range: ${DateFormat('yyyy-MM-dd').format(startDate!)} - ${DateFormat('yyyy-MM-dd').format(endDate!)}'
                          : 'Select Date Range'),
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
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: topResources.length,
                              itemBuilder: (context, index){
                                // display top resources as list tiles with rank(index)
                                return TopResourceTile(resource: topResources[index], index: index);
                              },
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
  final String resourceName;
  final int clicks;

  ResourceData(this.resourceName, this.clicks);
}

// display a resource in a list tile format
class TopResourceTile extends StatelessWidget {

  const TopResourceTile({
    Key? key,
    required this.resource,
    required this.index
  }) : super(key: key);

  final ResourceData resource;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      child: Card(
        color: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(0),
        ),
        child: ListTile(
          contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
          dense: false,
          title: Text(
            resource.resourceName,
            textAlign: TextAlign.left,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
            softWrap: true,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          leading: Text(
            '${index + 1}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          subtitle: Text(
            'Clicks: ${resource.clicks}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}