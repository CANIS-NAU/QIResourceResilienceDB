//Import packages
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

//List of ages for dropdown
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

//Specify page that has state
class CreateResource extends StatefulWidget {
  CreateResource( { super.key } );

  //final String title;

  @override
  State<CreateResource> createState() => createResourceState();
}

//List of widgets for dropdown
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

//Create resource page
class createResourceState extends State<CreateResource> {
  
  //Specify route
  static const String route = '/createresource';

  //Varible initalizaton
  String resourceName = "";
  String resourceLocation = "";
  String resourceDescription = "";
  String resourceLocationBoxText = "Link to the resource";
  double _currentSliderValue = 0;
  
  //Specifies first value in dropdown to first in the list
  String _currentDropDownValue = ageItems.first;

  //Tags created stored in tag array
  List<dynamic> selectedTags = [];

  //For text deletion on textbox submit 
  var _controller = TextEditingController();

  //Bool lists to indicate what box has been selected ( three options ) 
  final List<bool> _selectedResources = <bool>[ true, false, false ];
  final List<bool> _selectedPrivacy = <bool>[ true, false, false ];

  bool vertical = false;
  bool verified = false;

  //Init collection from db
  CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');
  //final Stream<QuerySnapshot> resources = FirebaseFirestore.instance.collection('resources').where('verified', isEqualTo: true ).snapshots();

  //Change corresponding textbox text based on resource type 
  String changeLocationText(){
    String text = "";

    //First bool in List corresponds to "Online", check if selected
    if( _selectedResources[ 0 ] )
    {
      text = "Link to the resource";
    }
    //Second bool in List corresponds to In Person, check if selcted
    else if( _selectedResources[ 1 ] )
    {
      text = "Please provide the address to the resource";
    }
    //Third option must be app if prev two not selected
    else
    {
      text = "Please provide the link to the app store where the resource is found";
    }
    //Return new box text
    return text;
  }

  //Submit to DB
  Future<void> submitResource( resourceName, resourceLocation, resourceDescription )
  {
    String resourceType = "", privacyType = "";

    //Check for resource type, required to convert to string( useful for db store )
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

    //Check for privacy options in Bool array, required to convert to string
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

    //Add resource to db with provided values
    //TODO: Need better error handling here
    return resourceCollection.add(
      {
        'name': resourceName,
        'location': resourceLocation,
        'description': resourceDescription,
        'agerange': _currentDropDownValue,
        'verified': verified, //Always false upon creation
        'resourceType': resourceType,
        'privacy': privacyType,
        'culturalResponsivness': _currentSliderValue,
        'tagline': selectedTags
      }
    ).then(( value ) => print("Doc Added" ) )
     .catchError((error) => print("Failed to add doc: $error") );
  }
  
  //Create resource UI
  @override
  Widget build( BuildContext context ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Resource'),
      ),
      body: new Container(
                    child: new Stack(
                        children: [
                            new Container(
                              padding: const EdgeInsets.symmetric( vertical: 20),
                              margin: const EdgeInsets.only(top: 50, right: 800, left: 300),
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
                              margin: const EdgeInsets.only(top: 150, right: 800, left: 300),
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
                              margin: const EdgeInsets.only(top: 250, right: 800, left: 300),
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
                              margin: const EdgeInsets.only(top: 350, right: 800, left: 300),
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
                            Padding(
                            padding: const EdgeInsets.only(top: 450, left: 325 ),
                            child: Text(
                            "Your active tags. Click to remove",
                                style: TextStyle(fontSize: 15.0),
                              ),
                          ),
                            Padding(
                            padding: const EdgeInsets.only(top: 70, left: 970 ),
                            child: Text(
                            "Resource Type",
                                style: TextStyle(fontSize: 20.0),
                              ),
                          ),
                            new Container(
                              margin: const EdgeInsets.only(top: 100, right: 0, left: 920),
                              child:
                              ToggleButtons(
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
                            ),),
                            SizedBox(height: 20 ),
                            Padding(
                            padding: const EdgeInsets.only(top: 250, left: 960 ),
                            child: Text(
                            "Privacy Protections",
                                style: TextStyle(fontSize: 20.0),
                              ),
                          ),  
                        new Container(
                              margin: const EdgeInsets.only(top: 290, right: 0, left: 900),
                              child: 
                              ToggleButtons(
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
                            ),),
                            SizedBox(height: 20 ),
                            Padding(
                            padding: const EdgeInsets.only(top: 350, left: 950 ),
                            child: Text(
                            "Cultural Responsiveness",
                                style: TextStyle(fontSize: 20.0),
                            ),
                        ),    
                        new Container(
                          margin: const EdgeInsets.only(top: 380, right: 0, left: 850),
                          height: 50,
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
                            Padding(
                            padding: const EdgeInsets.only(top: 160, left: 950 ),
                            child: Text(
                            "Age Range of Resource",
                                style: TextStyle(fontSize: 20.0),
                              ),
                          ),
                           new Container(
                            margin: const EdgeInsets.only(top: 190, right: 0, left: 975),
                            child:
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
                            ),),
                            new Container(
                              margin: const EdgeInsets.only(top: 100, right: 0, left: 800),
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
                              margin: const EdgeInsets.only(top: 450, right: 0, left: 700),
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