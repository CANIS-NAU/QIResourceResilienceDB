import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

const List<String> ageItems = [
    "Select age range",
    "0-5",
    "6-10",
    "11-15",
    "16-20",
    "21-25",
    "26-35",
    "36-55",
    "56-75",
    "76+"
  ];

// Main function
void main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform
  );
  runApp( const MyApp() );
}

class MyApp extends StatelessWidget {
  const MyApp( {super.key} );
  
  // This widget is the root of your application.
  @override
  Widget build( BuildContext context ) {
    return MaterialApp(
      title: "Resource Web Page",
      initialRoute: '/',
      routes: {
        '/home': ( context ) => const MyHomePage(),
        '/verify': ( context ) => SecondScreen(),
        '/createresource': ( context ) => CreateResource(),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}


class MyHomePage extends StatefulWidget {
  const MyHomePage( { super.key } );

  //final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class filterItem {
  final int id;
  final String name;

  filterItem({
    required this.id,
    required this.name,
  });
}

//Home Page state
class _MyHomePageState extends State<MyHomePage> {  

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

  List<dynamic> selectedFilter = [];

  String searchQuery = "";

  Stream<QuerySnapshot> resources = FirebaseFirestore.instance.collection('resources').where( 'verified', isEqualTo: true ).snapshots();
  CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');

  Stream<QuerySnapshot> filter( selectedFilter ){
    Stream<QuerySnapshot> filtered = FirebaseFirestore.instance.collection('resources').where('verified', isEqualTo: true).snapshots();

    return filtered;
  }


  Stream<QuerySnapshot> searchResource( searchQuery ){
    return FirebaseFirestore.instance.collection('resources').where('name', isEqualTo: "${ searchQuery }" ).where('verified', isEqualTo: true).snapshots();
  }

  @override
  Widget build( BuildContext context ) {
            return Scaffold(
                resizeToAvoidBottomInset : false,
                body: 
                  new SingleChildScrollView(
                    child: new Column(
                        children: [
                            new Container(
                              padding: const EdgeInsets.symmetric( vertical: 20),
                              margin: const EdgeInsets.only(right: 0, left: 1200),
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
                                    Navigator.pushNamed( context, '/createresource');
                                  },
                                  child: Text('Submit Resource'),
                                )
                            ),
                            new Container(
                              padding: const EdgeInsets.symmetric( vertical: 0),
                              margin: const EdgeInsets.only(right: 0, left: 1200),
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
                                     Navigator.pushNamed(context, '/verify');
                                  },
                                  child: Text('Verify New Resources'),
                                )
                            ),
                            new Container(
                              padding: const EdgeInsets.symmetric( vertical: 20),
                              margin: const EdgeInsets.only(right: 300, left: 300),
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
                                      onSubmitted: ( text ) {
                                          setState(() {
                                            resources = searchResource( text );
                                        });
                                      },
                                    ),
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
                                          //resources = filter( selectedFilter ); 
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
                                return Text("Loading Resources From Dataabse");
                              }
                              //Get the snapshot data
                              final data = snapshot.requireData;

                              //Return a list of the data
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
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

class SecondScreen extends StatelessWidget {
  SecondScreen( { super.key } );
  static const String route = '/verify';
  final Stream<QuerySnapshot> resources = FirebaseFirestore.instance.collection('resources').where('verified', isEqualTo: false ).snapshots();
  CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');

  Future<void> verifyResource( name ){
    return resourceCollection.doc( name.id ).update( {"verified": true } )
      .then( ( value ) => print( "Updated" ) )
      .catchError( (error) => print("Failed to update resource: $error" ) );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Resource'),
      ),
      body: 
          new Container(
              child: new Column(
                children: [
                  new Container(
                     padding: const EdgeInsets.symmetric( vertical: 10),
                     child: StreamBuilder<QuerySnapshot>(
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
                      return Text("Loading Resources From Dataabse");
                    }
                    //Get the snapshot data
                    final data = snapshot.requireData;

                    //Return a list of the data
                    return ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      itemCount: data.size,
                      itemBuilder: ( context, index ) {
                      return Container( 
                        padding: const EdgeInsets.symmetric( vertical: 20 ),
                        margin: const EdgeInsets.only(top: 30, right: 0, left: 0),
                        decoration: BoxDecoration(
                                    color: Colors.blue,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey,
                                        spreadRadius: 5,
                                        blurRadius: 7,
                                        offset: Offset(10.0, 10.0),
                                      )
                                    ]
                                  ),
                        child: 
                          new Stack(
                            
                            children: [
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 10),
                                margin: const EdgeInsets.only(top: 0, right: 0, left: 100),
                                child: 
                                  Text("Title",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 10),
                                margin: const EdgeInsets.only(top: 0, right: 0, left: 250),
                                child: 
                                  Text("Type",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 10),
                                margin: const EdgeInsets.only(top: 0, right: 0, left: 450),
                                child: 
                                  Text("Reporting",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 10),
                                margin: const EdgeInsets.only(top: 0, right: 0, left: 650),
                                child: 
                                  Text("Responsiveness",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 10),
                                margin: const EdgeInsets.only(top: 0, right: 0, left: 900),
                                child: 
                                  Text("Location",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 10),
                                margin: const EdgeInsets.only(top: 0, right: 0, left: 1100),
                                child: 
                                  Text("Description",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 10),
                                margin: const EdgeInsets.only(top: 0, right: 0, left: 1270),
                                child: 
                                  Text("Date Added",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 0),
                                margin: const EdgeInsets.only(top: 50, right: 0, left: 100),
                                child: 
                                  Text( "${data.docs[ index ][ 'name' ]}",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 0),
                                margin: const EdgeInsets.only(top: 50, right: 0, left: 250),
                                child: 
                                  Text( "${data.docs[ index ][ 'name' ]}",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 0),
                                margin: const EdgeInsets.only(top: 50, right: 0, left: 450),
                                child: 
                                  Text( "${data.docs[ index ][ 'name' ]}",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 0),
                                margin: const EdgeInsets.only(top: 50, right: 0, left: 650),
                                child: 
                                  Text( "${data.docs[ index ][ 'name' ]}",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 0),
                                margin: const EdgeInsets.only(top: 50, right: 0, left: 900),
                                child: 
                                  Text( "${data.docs[ index ][ 'name' ]}",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 0),
                                margin: const EdgeInsets.only(top: 50, right: 0, left: 1100),
                                child: 
                                  Text( "${data.docs[ index ][ 'name' ]}",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  
                              ),
                              new Container(
                                padding: const EdgeInsets.symmetric( vertical: 0),
                                margin: const EdgeInsets.only(top: 50, right: 0, left: 1270),
                                child: 
                                  Text( "${data.docs[ index ][ 'name' ]}",
                                  textAlign: TextAlign.left,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  
                              ),
                              
                              new Container(
                                margin: const EdgeInsets.only(top: 20, right: 0, left: 5),
                                child: 
                                  TextButton(
                                    style: ButtonStyle(
                                      shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(18.0),
                                        side: BorderSide(color: Colors.white)
                                      )
                                    ),
                                    foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                                    ),
                                    onPressed: () { 
                                      verifyResource( data.docs[ index ]);
                                    },
                                    child: Text('Verify',
                                     style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    ),
                                ),                            
                              ),
                            ],
                          ),
                      );
                    }
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CreateResource extends StatefulWidget {
  CreateResource( { super.key } );

  //final String title;

  @override
  State<CreateResource> createState() => createResourceState();
}

const List<Widget> resourceType = <Widget>[
  Text('Online'),
  Text('In Person'),
  Text('App'),
];

const List<Widget> resourcePrivacy = <Widget>[
  Text('HIPAA Compliant'),
  Text('Anonymous'),
  Text('Mandatory Reporting')
];

class createResourceState extends State<CreateResource> {
  static const String route = '/createresource';

  String resourceName = "";
  String resourceLocation = "";
  String resourceDescription = "";
  String resourceLocationBoxText = "Link to the resource";
  double _currentSliderValue = 0;
  String _currentDropDownValue = ageItems.first;
  List<dynamic> selectedTags = [];
  var _controller = TextEditingController();

  final List<bool> _selectedResources = <bool>[ true, false, false ];
  final List<bool> _selectedPrivacy = <bool>[ true, false, false ];

  //Booleans for vertical align and a created verification
  bool vertical = false;
  bool verified = false;

  CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');
  final Stream<QuerySnapshot> resources = FirebaseFirestore.instance.collection('resources').where('verified', isEqualTo: true ).snapshots();

  String changeLocationText(){
    String text = "";
    if( _selectedResources[ 0 ] )
    {
      text = "Link to the resource";
    }
    else if( _selectedResources[ 1 ] )
    {
      text = "Please provide the address to the resource";
    }
    else
    {
      text = "Please provide the link to the app store where the resource is found";
    }
    return text;
  }

  Future<void> submitResource( resourceName, resourceLocation, resourceDescription ){
    String resourceType = "", privacyType = "";

    if( _selectedResources[ 0 ] )
    {
      resourceType = "Online";
    }
    else if( _selectedResources[ 1 ] )
    {
      resourceType = "In Person";
    }
    else
    {
      resourceType = "App";
    }
    if( _selectedPrivacy[ 0 ] )
    {
      privacyType = "HIPAA Compliant";
    }
    else if( _selectedPrivacy[ 1 ] )
    {
      privacyType = "Anonymous";
    }
    else
    {
      privacyType = "Mandatory Reporting";
    }
    return resourceCollection.add(
      {
        'name': resourceName,
        'location': resourceLocation,
        'description': resourceDescription,
        'agerange': _currentDropDownValue,
        'verified': verified,
        'resourceType': resourceType,
        'privacy': privacyType,
        'culturalResponsivness': _currentSliderValue,
        'tagline': selectedTags
      }
    ).then(( value ) => print("Doc Added" ) )
    .catchError((error) => print("Failed to add doc: $error"));
  }
  
  @override
  Widget build( BuildContext context ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Resource'),
      ),
      body: new Container(
                    child: new Column(
                        children: [
                            new Container(
                              padding: const EdgeInsets.symmetric( vertical: 20),
                              margin: const EdgeInsets.only(right: 1000, left: 100),
                              child: 
                                TextField(
                                    obscureText: false,
                                    decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Name of the Resource',
                                  ),
                                  onChanged: ( text ) {
                                    resourceName = text;
                                  },
                                ),
                            ),
                            new Container(
                              padding: const EdgeInsets.symmetric( vertical: 20),
                              margin: const EdgeInsets.only(right: 1000, left: 100),
                              child: 
                                TextField(
                                    obscureText: false,
                                    decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: resourceLocationBoxText,
                                  ),
                                  onChanged: ( text ) {
                                    resourceLocation = text;
                                  },
                                ),
                            ),
                            new Container(
                              padding: const EdgeInsets.symmetric( vertical: 20),
                              margin: const EdgeInsets.only(right: 1000, left: 100),
                              child: 
                                TextField(
                                    obscureText: false,
                                    decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Description of the Resource',
                                  ),
                                  onChanged: ( text ) {
                                    resourceDescription = text;
                                  },
                                ),
                            ),
                            new Container(
                              padding: const EdgeInsets.symmetric( vertical: 20),
                              margin: const EdgeInsets.only(right: 1000, left: 100),
                              child: 
                                TextField(
                                    obscureText: false,
                                    controller: _controller,
                                    decoration: InputDecoration(
                                    border: OutlineInputBorder(),
                                    labelText: 'Please provide tags for the resource',
                                  ),
                                  onSubmitted: ( text ) {
                                    if( text != "" )
                                    {
                                      setState(() {
                                        _controller.clear();
                                        selectedTags.add( text );
                                      });
                                    }
                                  },
                                ),
                            ),
                            Text("Your active tags. Click to remove"),
                            Text("Resource Type"),
                            new ToggleButtons(
                              direction: vertical ? Axis.vertical : Axis.horizontal,
                              onPressed: ( int index ) {
                                setState(() {
                                  for(int i = 0; i < _selectedResources.length; i++) {
                                    _selectedResources[i] = i == index;
                                  }
                                  resourceLocationBoxText = changeLocationText();
                                });
                              },
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                              selectedBorderColor: Colors.blue[700],
                              selectedColor: Colors.white,
                              fillColor: Colors.blue[200],
                              color: Colors.blue[400],
                              constraints: const BoxConstraints(
                                minHeight: 40.0,
                                minWidth: 80.0,
                              ),
                              isSelected: _selectedResources,
                              children: resourceType,
                            ),
                            SizedBox(height: 20 ),
                            Text("Privacy Protections"),
                            new ToggleButtons(
                              direction: vertical ? Axis.vertical : Axis.horizontal,
                              onPressed: ( int index ) {
                                setState(() {
                                  for(int i = 0; i < _selectedPrivacy.length; i++) {
                                    _selectedPrivacy[i] = i == index;
                                  }
                                });
                              },
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                              selectedBorderColor: Colors.blue[700],
                              selectedColor: Colors.white,
                              fillColor: Colors.blue[200],
                              color: Colors.blue[400],
                              constraints: const BoxConstraints(
                                minHeight: 40.0,
                                minWidth: 80.0,
                              ),
                              isSelected: _selectedPrivacy,
                              children: resourcePrivacy,
                            ),
                            SizedBox(height: 20 ),
                            Text("Cultural Responsiveness"),
                            new Container(
                              width: 500,
                              child:
                                  Slider(
                                    value: _currentSliderValue,
                                    max: 5,
                                    divisions: 5,
                                    label: _currentSliderValue.round().toString(),
                                    onChanged: (double value) {
                                    setState(() {
                                      _currentSliderValue = value;
                                    });
                                  },
                                ),
                            ),
                            Text("Age range of resource"),
                            DropdownButton(
                              value: _currentDropDownValue,
                              onChanged: (String? newValue){
                              setState(() {
                                _currentDropDownValue = newValue!;
                              });
                            },
                            items: ageItems.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                               );
                              }).toList(),
                            ),
                            
                            new Container(
                              margin: const EdgeInsets.only(right: 600, left: 550),
                              child:
                                MultiSelectChipDisplay(                              
                                  items: selectedTags.map( (e) => MultiSelectItem( e, e ) ).toList(),
                                  onTap: (value) {
                                  setState(() {
                                    selectedTags.remove( value );
                                  });
                                },
                              ),
                            ),
                            new Container(
                              padding: const EdgeInsets.symmetric( vertical: 20),
                              margin: const EdgeInsets.only(right: 200, left: 150),
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
                                    submitResource( resourceName, resourceLocation, resourceDescription );
                                  },
                                  child: Text('Submit Resource'),
                                )
                            ),
                    ]
                  )
      )
    );
  }
}