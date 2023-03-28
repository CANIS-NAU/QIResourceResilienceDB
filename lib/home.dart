//Package imports

import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final String category;

  //Class constructor
  filterItem({
    required this.id,
    required this.name,
    required this.category
  });
}
bool adminAccess = false;
bool managerAccess = false;

//Home Page state
class _MyHomePageState extends State<MyHomePage> {

  //Set booleans for filtering types
  bool ageFilter = false, responsivenessType = false, reportingType = false, locationType = false;

  //Static list of filter categories with corresponding filter items
  // more to be added. Added with constructor
  static List<filterItem> filterItems = [
    filterItem(id: 0, name: "Online", category: "Type"),
    filterItem(id: 1, name: "In Person", category: "Type"),
    filterItem(id: 2, name: "App", category: "Type"),
    filterItem(id: 3, name: "Hotline", category: "Type"),

    filterItem(id: 4, name: "Low Cultural Responsiveness", category: "Cultural Responsiveness"),
    filterItem(id: 5, name: "Medium Cultural Responsiveness", category: "Cultural Responsiveness"),
    filterItem(id: 6, name: "High Cultural Responsiveness", category: "Cultural Responsiveness"),

    filterItem(id: 7, name: "HIPAA Compliant", category: "Privacy"),
    filterItem(id: 8, name: "Anonymous", category: "Privacy"),
    filterItem(id: 9, name: "Mandatory Reporting", category: "Privacy"),

    filterItem(id: 10, name: "0-5", category: "Age Range"),
    filterItem(id: 11, name: "6-10", category: "Age Range"),
    filterItem(id: 12, name: "11-15", category: "Age Range"),
    filterItem(id: 13, name: "16-20", category: "Age Range"),
    filterItem(id: 14, name: "21-25", category: "Age Range"),
    filterItem(id: 15, name: "26-35", category: "Age Range"),
    filterItem(id: 16, name: "36-55", category: "Age Range"),
    filterItem(id: 17, name: "56-75", category: "Age Range"),
    filterItem(id: 18, name: "76+", category: "Age Range"),
  ];

  // for possibly grouping filter items by category
  Map<String, List<filterItem>> groupedFilterItems() {
    return {
      "Type": [
        filterItems[0],
        filterItems[1],
        filterItems[2],
        filterItems[3]
      ],
      "Cultural Responsiveness": [
        filterItems[4],
        filterItems[5],
        filterItems[6],
      ],
      "Privacy": [
        filterItems[7],
        filterItems[8],
        filterItems[9],
      ],
      "Age Range": [
        filterItems[10],
        filterItems[11],
        filterItems[12],
        filterItems[13],
        filterItems[14],
        filterItems[15],
        filterItems[16],
        filterItems[17],
        filterItems[18],
      ],
    };
  }

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
    String potentialLocationType = "", potentialResponsivenessType = "", potentialReportingType = "", potentialAgeType = "", potentialCostType ="";
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
          currentArrayItem == "App" || currentArrayItem == "Hotline" )
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
      else if( currentArrayItem == "Price" ||
          currentArrayItem == "Subscription" ||
          currentArrayItem == "Insurance" )
      {
        potentialCostType = currentArrayItem;
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

  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  //Home screen UI 
  @override
  Widget build( BuildContext context ) {
    final width = MediaQuery.of(context).size.width;
    final bool isLargeScreen = width > 800;
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: isLargeScreen
            ? null
            : IconButton(
          color: Colors.blue,
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/rrdb_logo.png',
                height: 55,
              ),
              if (isLargeScreen) Expanded(child: _navBarItems())
            ],
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(child: _ProfileIcon()),
          )
        ],
      ),
      drawer: isLargeScreen ? null : _drawer(),
      body: LayoutBuilder(builder: (context, windowSize) {
        return SingleChildScrollView(
          child: new Column(
            children:[
              // search bar
              new Container(
                padding: EdgeInsets.symmetric( vertical: windowSize.maxHeight / 100 ),
                margin: EdgeInsets.only( right: windowSize.maxWidth / 6, left: windowSize.maxWidth / 6 ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //SizedBox(height: 20.0,),
                    Container(
                      child: TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Color(0xFFEEEEEE),
                  border: OutlineInputBorder(),
                  labelText: "Enter a keyword for the resource",
                  suffixIcon: Icon(Icons.search),
                ),
                obscureText: false,
                onSubmitted: (text) {
                  setState(() {
                    resources = searchResource(text);
                  });
                }
                ),
                    ),
                    // filter items
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
                  ],
                ),
              ),
              new Container(
                  margin: EdgeInsets.only( right: windowSize.maxWidth /6, left: windowSize.maxWidth / 6 ),
                  padding: const EdgeInsets.symmetric( vertical: 20),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: resources,
                    builder: (
                    BuildContext context,
                        AsyncSnapshot<QuerySnapshot> snapshot,
                        ) {
                      //Check for firestore snapshot error
                      if(snapshot.hasError)
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

                      //Return a list of the data (resources)
                      if(data.size != 0)
                        {
                          return Container(
                            height: 500,
                            child: ListView.builder(
                              scrollDirection: Axis.vertical,
                              shrinkWrap: true,
                              itemCount: data.size,
                              itemBuilder: (context, index) {
                                return Container(
                                  height: 100,
                                  child: Card(
                                    color: Colors.white,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(0)),
                                    ),
                                // the format for each resource box
                                    child: ListTile(
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 10.0,
                                        horizontal: 30.0),
                                dense: false,
                                title: SizedBox( width: index == 0 ? 95 : 80,
                                child: Text('${data.docs[ index ][ 'name' ]}',
                                overflow: TextOverflow.visible,
                                softWrap: true,
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),)),
                                subtitle: SizedBox( width: 80,
                                    child: Text('Description: ${data.docs[ index ][ 'description' ]}',
                                        overflow: TextOverflow.visible,
                                        softWrap: true,
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                      trailing: GestureDetector(
                                        child: Icon(
                                          Icons.arrow_forward_rounded,
                                          color: Colors.black,
                                        ),
                                        // pop up for a resource with information
                                        onTap: () {
                                          showDialog(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                title: Text('${data.docs[ index ][ 'name' ]}',
                                                    style: TextStyle(fontSize: 25.0, fontWeight: FontWeight.bold)),
                                                content: Container(
                                                  child: SizedBox(
                                                    // include cost when there is data for it
                                                    child: Text(
                                                        'Type: ${data.docs[ index ][ 'resourceType' ]}\n\n'
                                                        'Privacy: ${data.docs[ index ][ 'privacy' ]}\n\n'
                                                        'Cultural Responsiveness: ${data.docs[ index ][ 'culturalResponsivness' ]} \n\n'
                                                        'Location: ${data.docs[ index ][ 'location' ]}\n\n'
                                                        'Description: ${data.docs[ index ][ 'description']}',
                                                        overflow: TextOverflow.visible, softWrap: true,
                                                        style: TextStyle(fontSize: 16.0)),
                                                  ),
                                                ),
                                                actions:[
                                                  TextButton(
                                                    child: Text('OK'),
                                                    onPressed: () => Navigator.pop(context),
                                                  )
                                                ]
                                              ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              }
                            )

                          );
                        }
                      else
                        {
                          return Text('No resources');
                        }
                    }
                  ),
              ),
            ]
          ),
        );
      }
      ),
    );
  }

  // creates menu items when screen size is small
  Widget _drawer() => Drawer(
    child: ListView(
      children: _menuItems
          .map((item) => ListTile(
        onTap: () {
          _scaffoldKey.currentState?.openEndDrawer();
          switch(item){
            case "Submit Resource":
              Navigator.pushNamed(context, '/createresource');
              break;
            case "Verify Resource":
              Navigator.pushNamed(context, '/verify');
              break;
            case "Dashboard":
              Navigator.pushNamed(context, '/dashboard');
          }
        },
        title: Text(item),
      ))
          .toList(),
    ),
  );

  // creates main menu navigation buttons
  Widget _navBarItems() => Row(
    mainAxisAlignment: MainAxisAlignment.end,
    crossAxisAlignment: CrossAxisAlignment.center,
    children: _menuItems
        .map(
          (item) => InkWell(
        onTap: () {
          switch(item){
            case "Submit Resource":
              Navigator.pushNamed(context, '/createresource');
              break;
            case "Verify Resource":
              Navigator.pushNamed(context, '/verify');
              break;
            case "Dashboard":
              Navigator.pushNamed(context, '/dashboard');
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 24.0, horizontal: 16),
          child: Text(
            item,
            style: const TextStyle(fontSize: 16, color: Colors.black),
          ),
        ),
      ),
    )
        .toList(),
  );
}

// list of navigation buttons
final List<String> _menuItems = <String>[
  'Submit Resource',
  'Verify Resource',
  'Dashboard',
];

enum Menu { itemOne, itemTwo, itemThree, itemFour }

void signoutUser() async
{
  await FirebaseAuth.instance.signOut();
}

// adds the menu items for the profile drop down
class _ProfileIcon extends StatelessWidget {
  const _ProfileIcon({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    User? user = FirebaseAuth.instance.currentUser;

    return FutureBuilder(
      future: user?.getIdTokenResult(),
      builder: ( BuildContext context, AsyncSnapshot<dynamic> snapshot ) {
        if( snapshot.hasData ) 
        {
          Map<String, dynamic>? claims = snapshot.data?.claims;

          if( claims != null ) 
          {
            if( claims['admin'] ) 
            {
              return PopupMenuButton<Menu>(
                  icon: const Icon(Icons.person),
                  offset: const Offset(0, 40),
                  onSelected: (Menu item) {},
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                    const PopupMenuItem<Menu>(
                      value: Menu.itemOne,
                      child: Text('Account'),
                    ),
                    const PopupMenuItem<Menu>(
                      value: Menu.itemTwo,
                      child: Text('Settings'),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.itemThree,
                      child: 
                        InkWell(
                          child: Text("Register User"),
                          onTap: () {
                            Navigator.pushNamed( context, '/register' );
                          },
                        )
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.itemFour,
                      child: 
                        InkWell(
                          child: Text("Sign Out"),
                          onTap: () {
                            signoutUser();
                            Navigator.pushNamed( context, '/home' );
                          },
                        )
                    ),
                  ]);
            } 
            else if( claims['manager'] ) 
            {
              return PopupMenuButton<Menu>(
                  icon: const Icon(Icons.person),
                  offset: const Offset(0, 40),
                  onSelected: (Menu item) {},
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                    const PopupMenuItem<Menu>(
                      value: Menu.itemOne,
                      child: Text('Account'),
                    ),
                    const PopupMenuItem<Menu>(
                      value: Menu.itemTwo,
                      child: Text('Settings'),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.itemFour,
                      child: 
                        InkWell(
                          child: Text("Sign Out"),
                          onTap: () {
                            signoutUser();
                            Navigator.pushNamed( context, '/home' );
                          },
                        )
                    ),
                  ]);
            }
          }
        }

        // build default menu for non-authenticated users
        return PopupMenuButton<Menu>(
            icon: const Icon(Icons.person),
            offset: const Offset(0, 40),
            onSelected: (Menu item) {},
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
              PopupMenuItem<Menu>(
                value: Menu.itemOne,
                child: 
                  InkWell(
                    child: Text("Login"),
                    onTap: () {
                      Navigator.pushNamed( context, '/login' );
                    },
                  )
              ),
            ]);
      },
    );
  }
}
