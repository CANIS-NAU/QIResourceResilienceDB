/*
This page is the homepage that displays the verified resources to users.
When the user is not logged in, they can only view the resources or log in.
Once a user is logged in, the homepage displays options for submitting a resource,
verifying a resource, and a dashboard.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:web_app/view_resource/resource_summary.dart';
import 'package:web_app/view_resource/filter.dart';
import 'package:web_app/pdfDownload.dart';
import 'package:web_app/util.dart';
import 'package:web_app/Analytics.dart';

/// The home page main widget
class MyHomePage extends StatefulWidget {
  const MyHomePage( { super.key } );

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  /// The currently displayed resource query.
  Stream<QuerySnapshot> resources = FirebaseFirestore.instance
    .collection('resources')
    .where('verified', isEqualTo: true)
    .snapshots();

  final searchFieldController = TextEditingController();
  ResourceFilter filter = ResourceFilter.empty();

  HomeAnalytics analytics = HomeAnalytics();

  void onFilterChange() {
    // TODO: only change the query if filter *actually* changed.
    searchFieldController.text = filter.textual ?? "";
    resources = buildQuery(filter);
  }

  //Home screen UI 
  @override
  Widget build( BuildContext context ) {
    final screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 800;
    final bool isSmallScreen = !isLargeScreen;
    _menuItems = menuItems(isSmallScreen);
    PdfDownload pdfDownload = PdfDownload();

    bool Function(QueryDocumentSnapshot) filterFunction =
        clientSideFilter(filter);

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        leading: isLargeScreen
            ? null
            : IconButton(
           color: Theme.of(context).primaryColor,
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Focus(child: Builder(builder: (context) {
                final bool hasFocus = Focus.of(context).hasFocus;
                return Container(
                  decoration: BoxDecoration(
                    border: hasFocus
                        ? Border.all(
                            // color: Colors.black,
                        style: BorderStyle.solid)
                        : null,
                  ),
                  child: Image.asset(
                    'assets/rrdb_logo.png',
                    height: 55,
                    semanticLabel: "Resilience Resource Database Logo",
                  ),
                );
              })),
              if (isLargeScreen) Expanded(child: _navBarItems())
            ],
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: CircleAvatar(child: ProfileIcon()),
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
              padding:
                  EdgeInsets.symmetric(vertical: windowSize.maxHeight / 100),
              margin: EdgeInsets.only(
                  right: windowSize.maxWidth / 6,
                  left: windowSize.maxWidth / 6),
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
                        controller: searchFieldController,
                        onSubmitted: (text) {
                          setState(() {
                            final t = text.isNotEmpty ? text : null;
                            if(t != null) {
                              analytics.submitTextSearch(t);
                            }
                            filter.setTextSearch(t);
                            onFilterChange();
                          });
                        }),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  // filter items
                  Container(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: ElevatedButton(
                            child: Text('Filter'),
                            onPressed: () {
                              // show the filter pop-up
                              showDialog(
                                context: context, 
                                builder: (context) => CategoryFilterDialog(
                                  filter: filter,
                                  onChanged: (updatedFilter) => setState(() {
                                    filter = updatedFilter;
                                    onFilterChange();
                                  }),
                                ),
                              ).then((value) => 
                                analytics.submitFilterSearch(filter.categorical)
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(context).primaryColor
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        SizedBox(
                          child: ElevatedButton(
                            onPressed: () {
                              setState(() {
                                filter.clear();
                                onFilterChange();
                              });
                            },
                            child: Text("Reset Filters"),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor)
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 10),
                  MultiSelectChipDisplay(
                    items: filter
                        .categorical
                        .map((e) => MultiSelectItem(e, e.value))
                        .toList(),
                    onTap: (value) {
                      setState(() {
                        filter.removeFilter(value);
                        onFilterChange();
                      });
                    },
                  ),
                ],
              ),
            ),
            new Container(
                  margin: EdgeInsets.only( right: windowSize.maxWidth /6,
                                                left: windowSize.maxWidth / 6 ),
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

                      //Get the snapshot data and filter
                      final data = snapshot.requireData;
                      final docs = data.docs.where(filterFunction).toList();

                      //Return a list of the data (resources)
                      if (data.size == 0) {
                        return Text('No resources');
                      } else {
                        return Column(
                          children: [
                            Container(
                            height: 500,
                            child: FocusTraversalGroup(
                              policy: OrderedTraversalPolicy(),
                              child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  return ResourceSummary(
                                    resource: docs[index],
                                    isSmallScreen: isSmallScreen,
                                    analytics: analytics,
                                  );
                                }
                              ),
                            )
                          ),
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Align(
                                alignment: Alignment.bottomRight,
                                // button to download currently filtered resources
                                child: ElevatedButton(
                                    onPressed: () async {
                                      // get only resources that are visible 
                                      List<QueryDocumentSnapshot> unarchivedDocs = docs.where((doc) => doc['isVisable'] ?? true).toList();
                                      if(unarchivedDocs.isNotEmpty)
                                      {
                                        // create pdf of visible resources currently being filtered
                                        await pdfDownload.generateFilteredResourcesPdf(unarchivedDocs);
                                      }
                                      else
                                      {
                                        // show message that there are no visible resources to download
                                        showAlertDialog(context, "There are no resources available to download");
                                      }
                                    },
                                    child: Text("Download List")),
                              ),
                            ),
                          ]
                        );
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
            case "Login":
              Navigator.pushNamed(context, '/login');
              break;
            case "Submit Resource":
              Navigator.pushNamed(context, '/createresource');
              break;
            case "Verify Resource":
              Navigator.pushNamed(context, '/verify');
              break;
            case "Dashboard":
              Navigator.pushNamed(context, '/dashboard');
              break;
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
          switch( item ){
            case "Login":
              Navigator.pushNamed(context, '/login');
              break;
            case "Submit Resource":
              Navigator.pushNamed( context, '/createresource' );
              break;
            case "Verify Resource":
              Navigator.pushNamed( context, '/verify' );
              break;
            case "Dashboard":
              Navigator.pushNamed( context, '/dashboard' );
              break;
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

List<String> menuItems(bool isSmallScreen)
{
  List<String> _menuItems = <String>[];
  User? user = FirebaseAuth.instance.currentUser;

  if( user != null )
  {
    _menuItems = <String>[
      'Submit Resource',
      'Verify Resource',
      'Dashboard',
    ];
  }
    if (user == null && isSmallScreen)
    {
      _menuItems = <String>[
      'Login'
      ];
  }

  return _menuItems;
}

List<String> _menuItems = [];

enum Menu { itemOne, itemTwo, itemThree, itemFour, itemFive }

void signoutUser() async
{
  await FirebaseAuth.instance.signOut();
}

class _ClickablePopupMenuItem extends StatefulWidget{
  final Widget child;
  final VoidCallback onTap;

  const _ClickablePopupMenuItem({required this.child, required this.onTap});

  @override
    Widget build(BuildContext context) {
      return InkWell(
        onTap: onTap,
        child: Container(
          alignment: Alignment.centerLeft,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: child,
        ),
      );
    }

  @override
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }
}

// adds the menu items for the profile drop down
class ProfileIcon extends StatelessWidget {
  const ProfileIcon({Key? key}) : super(key: key);
  
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
                  icon: Icon(Icons.person),
                  offset: const Offset(0, 40),
                  onSelected: (Menu item) {
                    if(item == Menu.itemOne)
                    {
                      Navigator.pushNamed(context, '/account');
                    }
                    if (item == Menu.itemTwo)
                      {
                        Navigator.pushNamed( context, '/inbox' );
                      }
                    if(item == Menu.itemThree)
                      {
                        Navigator.pushNamed( context, '/register' );
                      }
                    if(item == Menu.itemFour )
                      {
                        Navigator.pushNamed( context, '/usermanagement' );
                      }
                    if(item == Menu.itemFive)
                      {
                        signoutUser();
                        Navigator.pushNamedAndRemoveUntil( context, '/home', (route) => false );
                      }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                   PopupMenuItem<Menu>(
                      value: Menu.itemOne,
                      child: Text("Account"),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.itemTwo,
                      child: Text("Inbox"),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.itemThree,
                      child: Text("Register User"),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.itemFour,
                      child: Text("Manage Users"),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.itemFive,
                      child: Text("Sign Out"),
                    ),
                  ]);
            }
            else if( claims['manager'] ) 
            {
              return PopupMenuButton<Menu>(
                  icon: Icon(Icons.person),
                  offset: const Offset(0, 40),
                  onSelected: (Menu item) {
                    if(item == Menu.itemOne)
                      {
                        Navigator.pushNamed(context, '/account');
                      }
                    if(item == Menu.itemTwo)
                      {
                        Navigator.pushNamed( context, '/inbox' );
                      }
                    if(item == Menu.itemThree)
                      {
                        // do nothing since we don't have a settings page yet
                      }
                    if(item == Menu.itemFour)
                      {
                        signoutUser();
                        Navigator.pushNamedAndRemoveUntil( context, '/home', (route) => false );
                      }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
                    PopupMenuItem<Menu>(
                      value: Menu.itemOne,
                      child: Text("Account"),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.itemTwo,
                      child: Text("Inbox"),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.itemThree,
                      child: Text('Settings'),
                    ),
                    PopupMenuItem<Menu>(
                      value: Menu.itemFour,
                      child: Text("Sign Out"),
                    ),
                  ]
               );
            }
          }
        }

        // build default menu for non-authenticated users
        return PopupMenuButton<Menu>(
            icon: Icon(Icons.person),
            offset: const Offset(0, 40),
            onSelected: (Menu item) { Navigator.pushNamed( context, '/login' );},
            itemBuilder: (BuildContext context) => <PopupMenuEntry<Menu>>[
              PopupMenuItem<Menu>(
                value: Menu.itemOne,
                child: Text("Login"),
              ),
            ]);
      },
    );
  }
}
