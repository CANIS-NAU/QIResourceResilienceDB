//Package imports
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

//Declare class that has state
class MyHomePage extends StatefulWidget {
  const MyHomePage( { super.key } );

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

//Filter class for each filter item
class filterItem {
  final int id;
  final String name;

  //Class construtor
  filterItem({
    required this.id,
    required this.name,
  });
}

//Home Page state
class _MyHomePageState extends State<MyHomePage> {

  //Set booleans for filtering types
  bool ageFilter = false, responsivenessType = false, reportingType = false, locationType = false;

  //Static list of filter items, more to be added. Added with constructor
  static List<filterItem> filterItems = [
    filterItem(id: 1, name: "Online"),
    filterItem(id: 2, name: "In Person"),
    filterItem(id: 3, name: "App"),

    filterItem(id: 4, name: "Low Cultural Responsivness"),
    filterItem(id: 5, name: "Medium Cultural Responsivness"),
    filterItem(id: 6, name: "High Cultural Responsivness"),

    filterItem(id: 7, name: "HIPAA Compliant"),
    filterItem(id: 8, name: "Anonymous"),
    filterItem(id: 9, name: "Mandatory Reporting"),

    filterItem(id: 10, name: "0-5"),
    filterItem(id: 11, name: "6-10"),
    filterItem(id: 12, name: "11-15"),
    filterItem(id: 13, name: "16-20"),
    filterItem(id: 14, name: "21-25"),
    filterItem(id: 15, name: "26-35"),
    filterItem(id: 16, name: "36-55"),
    filterItem(id: 17, name: "56-75"),
    filterItem(id: 18, name: "76+"),
  ];

  //Create a list that is casted dynamic, to hold filter items
  List<dynamic> selectedFilter = [];

  //Search bar query string
  String searchQuery = "";

  //Get resources only if verified
  Stream<QuerySnapshot> resources = FirebaseFirestore.instance.collection('resources').where( 'verified', isEqualTo: true ).snapshots();
  CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');

  //TODO: Finish filter mech. Needs to be a compund filter
  Stream<QuerySnapshot> filter( List<dynamic> selectedFilter )
  {
    String potentialLocationType = "", potentialResponsivenessType = "", potentialReportingType = "", potentialAgeType = "";
    String currentArrayItem = "";

    //Since list is dynamic type with id and name, we must map only to name
    List<String> selectedFilterNames = selectedFilter.map( (item) => item.name.toString() ).toList();

    //Get all queries that are verified
    Query query = FirebaseFirestore.instance.collection('resources').where('verified', isEqualTo: true);

    //Check what filter catagories have been selected
    setTypeFilter( selectedFilter );

    //Loop through selected filter options
    for( int filterIterator = 0; filterIterator < selectedFilterNames.length; filterIterator++ ) 
    {
      //Get current item
      currentArrayItem = selectedFilterNames[ filterIterator ];

      //Check items in catagories and set the potential filter query
      if( currentArrayItem == "Online" || currentArrayItem == "In Person" ||
                                                     currentArrayItem == "App" ) 
      {
        potentialLocationType = currentArrayItem;
      }
      else if( currentArrayItem == "Low Cultural Responsivness" || 
               currentArrayItem == "Medium Cultural Responsivness" || 
               currentArrayItem == "High Cultural Responsivness" )
      {
        potentialResponsivenessType = currentArrayItem;
      }
      else if( currentArrayItem == "HIPAA Compliant" || 
               currentArrayItem == "Anonymous" || 
               currentArrayItem == "Mandatory Reporting" )
      {
        potentialReportingType = currentArrayItem;
      }
      else
      {
        potentialAgeType = currentArrayItem;
      }
    }

    //Query based on selected filter catagories collected
    if( locationType )
    {
      query = query.where('resourceType', isEqualTo: potentialLocationType );
    }
    if( responsivenessType )
    {
      query = query.where('culturalResponse', isEqualTo : potentialResponsivenessType );
    }
    if( reportingType )
    {
      query = query.where('privacy', isEqualTo: potentialReportingType );
    }
    if( ageFilter )
    {
      query = query.where('agerange', isEqualTo: potentialAgeType );
    }

    Stream<QuerySnapshot> filtered = query.snapshots();

    //set filter booleans back to false for filter removable
    locationType = false;
    responsivenessType = false;
    reportingType = false;
    ageFilter = false;

    return filtered;
  }

  //Set what was selected for filtering 
  void setTypeFilter( List<dynamic> selectedFilter )
  {
    int selectedFilterId = 0;
    for( int dynamicListIndex = 0; dynamicListIndex < selectedFilter.length; dynamicListIndex++ ) 
    {
      selectedFilterId = selectedFilter[ dynamicListIndex ].id;

      if( selectedFilterId >= 1 && selectedFilterId <= 3 ) 
      {
        locationType = true;
      }
      else if( selectedFilterId >= 4 && selectedFilterId <= 6 ) 
      {
        responsivenessType = true;
      }
      else if( selectedFilterId >= 7 && selectedFilterId <= 9 ) 
      {
        reportingType = true;
      }
      // Note:
      else if( selectedFilterId >= 10 && selectedFilterId <= 18 )
      {
        ageFilter = true;
      }
    }
  }

  //Search query by keyword. Get resource with matching name
  Stream<QuerySnapshot> searchResource( searchQuery ){
    return FirebaseFirestore.instance.collection('resources').where('name', isEqualTo: "${ searchQuery }" ).where('verified', isEqualTo: true).snapshots();
  }

  //Home screen UI 
  @override
  Widget build( BuildContext context ) {
            return Scaffold(
                resizeToAvoidBottomInset : false,
                body: 
                 LayoutBuilder( builder: ( context, windowSize ) {
                  return SingleChildScrollView(
                    child: new Column(
                        children: [
                          new Container(
                            width: windowSize.maxWidth,
                            child:
                            new Row(
                                children: [
                                  SizedBox(
                                    //width: windowSize.maxWidth / 50,
                                    child: 
                                      Container(
                                        //margin: EdgeInsets.only( right: windowSize.maxWidth / 1.07, left: 0 ),
                                        height: windowSize.maxHeight / 13,
                                        width: windowSize.maxWidth / 10,
                                        decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: AssetImage(
                                              'assets/rrdb_logo.png'),
                                          fit: BoxFit.fill,
                                        ),                                
                                      ),
                                   ),
                                  ),
                                  SizedBox(
                                    width: windowSize.maxWidth / 10,
                                    child:
                                      Container(
                                        width: windowSize.maxWidth / 100,
                                        padding: EdgeInsets.only( right: windowSize.maxWidth / 100, left: 0 ),
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
                                            //Button navigation 
                                            onPressed: () { 
                                              Navigator.pushNamed( context, '/createresource' );
                                            },
                                            child: Text('Submit Resource'),
                                          )
                                    ),
                                  ),
                                  SizedBox(
                                    width: windowSize.maxWidth / 10,
                                    child: 
                                      Container(
                                        padding: EdgeInsets.only( right: windowSize.maxWidth / 100, left: 0 ),
                                        //margin: const EdgeInsets.only(right: 0, left: 1200),
                                        width: windowSize.maxWidth / 100,
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
                                            //Button navigation
                                            onPressed: () { 
                                              Navigator.pushNamed(context, '/verify');
                                            },
                                            child: Text('Verify New Resources'),
                                          )
                                    ),
                                  ),
                                  SizedBox(
                                    width: windowSize.maxWidth / 10,
                                    child: 
                                      Container(
                                        padding: EdgeInsets.only( right: windowSize.maxWidth / 100, left: 0 ),
                                        //margin: const EdgeInsets.only(right: 0, left: 1200),
                                        width: windowSize.maxWidth / 100,
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
                                            //Button navigation
                                            onPressed: () { 
                                              Navigator.pushNamed( context, '/login' );
                                            },
                                            child: Text('Dashboard'),
                                          )
                                    ),
                                  ),
                               ],
                             ),
                            ),
                            //Search bar
                            new Container(
                              padding: EdgeInsets.symmetric( vertical: windowSize.maxHeight / 100 ),
                              margin: EdgeInsets.only( right: windowSize.maxWidth / 6, left: windowSize.maxWidth / 6 ),
                              child: 
                                Column(
                                  mainAxisAlignment: MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Search for a Resource", style: TextStyle(color: Colors.black, fontSize: 28.0, fontWeight: FontWeight.bold,),),
                                    SizedBox(height: 20.0,),
                                    TextField(
                                      decoration: InputDecoration(
                                        filled: true,
                                        fillColor: Color(0xFFEEEEEE),
                                        border: OutlineInputBorder(),
                                        labelText: "Enter a keyword for the Resource",
                                        suffixIcon: Icon(Icons.search),
                                      ),
                                      obscureText: false,
                                      //Send text to search function 
                                      onSubmitted: ( text ) {
                                          setState(() {
                                            resources = searchResource( text );
                                        });
                                      },
                                    ),
                                    //Filter drop down
                                    SizedBox(
                                     width: 90,
                                     child:
                                      MultiSelectDialogField(
                                      title: Text("Filter"),
                                      decoration: BoxDecoration(
                                      borderRadius: BorderRadius.all(Radius.circular(18.0)),
                                      ),
                                      chipDisplay: MultiSelectChipDisplay.none(),
                                      items: filterItems.map( (e) => MultiSelectItem(e, e.name) ).toList(),
                                      listType: MultiSelectListType.CHIP,
                                      onConfirm: (values) {
                                        setState(() {
                                          selectedFilter = values;
                                          resources = filter( selectedFilter ); 
                                        });
                                      },                            
                                      ), 
                                    ),
                                    MultiSelectChipDisplay(
                                      items: selectedFilter.map( (e) => MultiSelectItem( e, e.name ) ).toList(),
                                      onTap: (value) {
                                        setState(() {
                                          selectedFilter.remove( value );
                                          resources = filter( selectedFilter );
                                        });
                                      },
                                    ),
                                  ]
                                ),
                            ),
                            new Container(
                              padding: const EdgeInsets.symmetric( vertical: 10),
                              child:
                                StreamBuilder<QuerySnapshot>(
                                stream: resources,
                                builder: (
                                BuildContext context,
                                AsyncSnapshot<QuerySnapshot> snapshot, 
                              ) {
                              //Check for firestore snapshot error
                              if( snapshot.hasError )
                              {
                                return Text("${snapshot.error}");
                              }
                              //Check if connection is being made
                              if( snapshot.connectionState == ConnectionState.waiting )
                              {
                                return Text("Loading Resources");
                              }
                              //Get the snapshot data
                              final data = snapshot.requireData;

                              //Return a list of the data
                              if( data.size != 0 )
                              {
                                return ListView.builder(
                                  scrollDirection: Axis.vertical,
                                  shrinkWrap: true,
                                  itemCount: data.size,
                                  itemBuilder: ( context, index ) {
                                  return DataTable(
                                    columns: [
                                      DataColumn(label: Text(
                                          index == 0 ? 'Name' : '',
                                          style: TextStyle(fontSize: index == 0 ? 18 : 0, fontWeight: FontWeight.bold),
                                      )),
                                      DataColumn(label: Text(
                                          index == 0 ? 'Type': '',
                                          style: TextStyle(fontSize: index == 0 ? 18 : 0, fontWeight: FontWeight.bold),
                                      )),
                                      DataColumn(label: Text(
                                          index == 0 ? 'Reporting' : '',
                                          style: TextStyle(fontSize: index == 0 ? 18 : 0, fontWeight: FontWeight.bold),
                                      )),
                                      DataColumn(label: Text(
                                          index == 0 ? 'Responsiveness' : '',
                                          style: TextStyle(fontSize: index == 0 ? 18 : 0, fontWeight: FontWeight.bold),
                                      )),
                                      DataColumn(label: Text(
                                          index == 0 ? 'Location' : '',
                                          style: TextStyle(fontSize: index == 0 ? 18 : 0, fontWeight: FontWeight.bold),
                                      )),
                                      DataColumn(label: Text(
                                          index == 0 ? 'Description' : '',
                                          style: TextStyle(fontSize: index == 0 ? 18 : 0, fontWeight: FontWeight.bold),
                                          
                                      )),
                                    ],
                                    rows: [
                                      DataRow(cells: [
                                        DataCell( SizedBox( width: index == 0 ? 95 : 80, child: Text('${data.docs[ index ][ 'name' ]}', overflow: TextOverflow.visible, softWrap: true,))),
                                        DataCell( SizedBox( width: index == 0 ? 100 : 80, child: Text('${data.docs[ index ][ 'resourceType' ]}', overflow: TextOverflow.visible, softWrap: true,))),
                                        DataCell( SizedBox( width: index == 0 ? 95 : 80, child: Text('${data.docs[ index ][ 'privacy' ]}',overflow: TextOverflow.visible, softWrap: true,))),
                                        DataCell( SizedBox( width: index == 0 ? 0 : 80, child: Text('${data.docs[ index ][ 'culturalResponsivness' ]}', overflow: TextOverflow.visible, softWrap: true,))),
                                        DataCell( SizedBox( width: index == 0 ? 90 : 80, child: Text('${data.docs[ index ][ 'location' ]}', overflow: TextOverflow.visible, softWrap: true,))),
                                        DataCell( SizedBox( width: 80, child: Text('${data.docs[ index ][ 'description' ]}', overflow: TextOverflow.visible, softWrap: true,)))
                                      ]),
                                    ],
                                  );
                              }
                            );
                          }
                          else
                          {
                            return Text("No resources");
                          }
                          }
                        ),
                      ),
                    ],
                  ),
                );
               }
              ),
             );
            }
          }