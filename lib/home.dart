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

  //Static list of filter items, more to be added. Added with constructor
  static List<filterItem> filterItems = [
    filterItem(id: 1, name: "Online"),
    filterItem(id: 2, name: "In Person"),
    filterItem(id: 3, name: "App"),
    filterItem(id: 4, name: "Low Cultural Responsivness"),
    filterItem(id: 5, name: "Medium Cultural Responsivness"),
    filterItem(id: 6, name: "High Cultural Responsivness"),
    filterItem(id: 7, name: "HIPAA Compliant"),
    filterItem(id: 7, name: "Anonymous"),
    filterItem(id: 7, name: "Mandatory Reporting"),
  ];

  //Create a list that is casted dynamic, to hold filter items
  List<dynamic> selectedFilter = [];

  //Search bar query string
  String searchQuery = "";

  //Get resources only if verified
  Stream<QuerySnapshot> resources = FirebaseFirestore.instance.collection('resources').where( 'verified', isEqualTo: true ).snapshots();
  CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');

  //TODO: Finish filter mech. Needs to be a compund filter
  Stream<QuerySnapshot> filter( List<dynamic> selectedFilter ) {
    List<String> selectedFilterNames = selectedFilter.map((item) => item.name.toString()).toList();

    Query query = FirebaseFirestore.instance.collection('resources').where('verified', isEqualTo: true);
    
    query = query.where( 'tagline', arrayContainsAny: selectedFilterNames );

    Stream<QuerySnapshot> filtered = query.snapshots();

    return filtered;
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
                            new Row(
                                children: [
                                  Expanded(
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
                                  Expanded(
                                    child:
                                      Container(
                                        padding: EdgeInsets.only( right: windowSize.maxWidth / 100, left: 0 ),
                                        //margin: EdgeInsets.only(right: 0, left: 1200),
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
                                              Navigator.pushNamed( context, '/createresource' );
                                            },
                                            child: Text('Submit Resource'),
                                          )
                                    ),
                                  ),
                                  Expanded(
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
                                  Expanded(
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
                                return Text("Something went wrong");
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