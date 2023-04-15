//Import packages
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';

final now = DateTime.now();
final date = "${now.month}/${now.day}/${now.year}";
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

showAlertDialog( BuildContext context, String statement ) {

  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.pop( context );
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Alert"),
    content: Text( statement ),
    actions: [
      okButton,
    ],
  );

  //show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

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
  Text('Hotline')
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

  //Bool lists to indicate what box has been selected ( four options )
  final List<bool> _selectedResources = <bool>[ true, false, false, false ];

  final List<bool> _selectedPrivacy = <bool>[ true, false, false ];

  bool vertical = false;
  bool verified = false;

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
    else if( _selectedResources[ 3 ] )
    {
      text = "Please provide the phone number to the resource";
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
  void submitResource( resourceName, resourceLocation, resourceDescription, context )
  {
    User? user = FirebaseAuth.instance.currentUser;

    if( user != null )
    {
      CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');

      String resourceType = "", privacyType = "", culturalResponse = "";

      String? userEmail = user.email;

      if( _currentSliderValue >= 0 && _currentSliderValue <= 1 )
      {
        culturalResponse = "Low Cultural Responsivness";
      }
      else if( _currentSliderValue >= 2 && _currentSliderValue <= 3 )
      {
        culturalResponse = "Medium Cultural Responsivness";
      }
      else
      {
        culturalResponse = "High Cultural Responsivness";
      }

      //Check for resource type, required to convert to string( useful for db store )
      if( _selectedResources[ 0 ] )
      {
        resourceType = "Online";
      }
      else if( _selectedResources[ 1 ] )
      {
        resourceType = "In Person";
      }
      else if( _selectedResources[ 2 ] )
      {
        resourceType = "App";
      }
      else
      {
        resourceType = "Hotline";
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

      //TODO: Need better error handling here
      resourceCollection.add(
      {
            'name': resourceName,
            'location': resourceLocation,
            'description': resourceDescription,
            'agerange': _currentDropDownValue,
            'verified': verified, //Always false upon creation
            'resourceType': resourceType,
            'privacy': privacyType,
            'culturalResponse': culturalResponse,
            'culturalResponsivness': _currentSliderValue,
            'tagline': selectedTags,
            'dateAdded': date,
            'createdBy': userEmail
      }
      )
      .then( ( value ) => showAlertDialog( context, "Submitted resource for review" ) )
      .catchError( ( error ) => showAlertDialog( context, "Unable to submit. Please try again" ) );
    }
    else
    {
      showAlertDialog( context, "You need to login to submit a resource" );
    }
  }
  
  //Create resource UI
  @override
  Widget build( BuildContext context ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Resource'),
      ),
      body: LayoutBuilder( builder: ( context, windowSize ) {
        return new Container(
                    child: new Stack(
                        children: [
                            new Container(
                              margin: EdgeInsets.only( top: windowSize.maxHeight / 50, right: windowSize.maxWidth / 2, left: windowSize.maxWidth / 10 ),
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
                              margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 100, right: windowSize.maxWidth / 2, left: windowSize.maxWidth / 10 ),
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
                              margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 200, right: windowSize.maxWidth / 2, left: windowSize.maxWidth / 10 ),
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
                              margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 300, right: windowSize.maxWidth / 2, left: windowSize.maxWidth / 10 ),
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
                            new Container(
                            margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 375, left: windowSize.maxWidth / 10 ),
                            child: 
                              new Stack( 
                                children: [ 
                                  Text(
                                    "Your active tags. Click to remove",
                                    style: TextStyle(fontSize: 15.0),
                                  ),
                                  //Fix: Display under the tag zone
                                  Container(
                                    //margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 350, left: windowSize.maxWidth / 10 ),
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
                              ],
                             ),
                            ),
                              Padding(
                              padding: EdgeInsets.only( top: windowSize.maxHeight / 50, right: windowSize.maxWidth / 9, left: windowSize.maxWidth / 1.39 ),
                              child: Text(
                              "Resource Type",
                                  style: TextStyle( fontSize: 20.0 ),
                                ),
                            ),
                            new Container(
                              margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 25, left: windowSize.maxWidth / 1.45 ),
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
                            padding: EdgeInsets.only( top: windowSize.maxHeight / 50 + 100, right: windowSize.maxWidth / 9, left: windowSize.maxWidth / 1.43 ),
                            child: Text(
                            "Privacy Protections",
                                style: TextStyle(fontSize: 20.0),
                              ),
                          ),
                          new Container(
                              margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 125, left: windowSize.maxWidth / 1.5 ),
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
                            padding: EdgeInsets.only( top: windowSize.maxHeight / 50 + 200, right: windowSize.maxWidth / 9, left: windowSize.maxWidth / 1.43 ),
                            child: Text(
                            "Cultural Responsiveness",
                                style: TextStyle( fontSize: 20.0 ),
                            ),
                        ),    
                        new Container(
                          margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 225, left: windowSize.maxWidth / 1.60 ),
                          height: 50,
                          width: 500,
                              child:
                                  Slider(
                                    value: _currentSliderValue,
                                    max: 5,
                                    divisions: 5,
                                    label: _currentSliderValue.round().toString(),
                                    onChanged: ( double value ) {
                                    setState(() {
                                      _currentSliderValue = value;
                                    });
                                  },
                                ),
                            ),
                            Padding(
                            padding: EdgeInsets.only( top: windowSize.maxHeight / 50 + 300, right: windowSize.maxWidth / 9, left: windowSize.maxWidth / 1.43 ),
                            child: Text(
                            "Age Range of Resource",
                                style: TextStyle( fontSize: 20.0 ),
                              ),
                          ),
                           new Container(
                            margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 325, left: windowSize.maxWidth / 1.40 ),
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
                              margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 400, left: windowSize.maxWidth / 1.90 ),
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
                                    submitResource( resourceName, resourceLocation, resourceDescription, context );  
                                  },
                                  child: Text('Submit Resource'),
                                )
                            ),
                    ]
                  )
      );
     },
    ),
   );
  }
}