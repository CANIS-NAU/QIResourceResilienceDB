/*
This page allows users to submit a resource for review by
entering resource information such as:
name, description, link, address (if in person),
phone number (if hotline or in person), type, privacy,
cost, cultural responsiveness, and age range.
*/


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
    "All ages",
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

//List of strings for resource type
const List<String> resourceTypeOptions = [
  'In Person',
  'Hotline',
  'Online',
  'App'
];

// list of privacy options
const List<String> resourcePrivacy = <String>[
  'HIPAA Compliant',
  'Anonymous',
  'Mandatory Reporting',
  'None Stated',
];

// list of strings for resource cost
const List<String> resourceCostOptions = [
  'Free',
  'Covered by Insurance',
  'Subscription',
  'Fees associated'
];

//Create resource page
class createResourceState extends State<CreateResource> {
  
  //Specify route
  static const String route = '/createresource';

  //Varible initalizaton
  String resourceName = "";
  String resourceLocation = "";
  String resourceAddress = "";
  String resourceBldg = "";
  String resourceCity = "";
  String resourceState = "";
  String resourceZip = "";
  String resourcePhoneNumber = "";
  String resourceDescription = "";
  String resourceLocationBoxText = "Link to the resource";
  double _currentSliderValue = 0;
  int resourceCost = -1;
  int resourceTypeIndex = -1;
  
  //Specifies first value in dropdown to first in the list
  String _currentDropDownValue = ageItems.first;

  //Tags created stored in tag array
  List<dynamic> selectedTags = [];

  //For text deletion on textbox submit 
  var _controller = TextEditingController();

  // used to store selected privacy options
  final List<bool> _selectedPrivacy = List<bool>.filled(resourcePrivacy.length, false);
  List<String> selectedPrivacyOptions = [];

  // boolean to track hotline and in person selection
  bool isHotlineSelected = false;
  bool isInPersonSelected = false;

  bool vertical = false;
  bool verified = false;

  //Submit to DB
  void submitResource( resourceName, resourceLocation, resourceDescription, context )
  {
    User? user = FirebaseAuth.instance.currentUser;

    if( user != null )
    {
      CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');

      String resourceType = "", culturalResponse = "";
      String costType = "";

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

      //Check for resource type, required to convert to string(useful for db store)
      if( resourceTypeIndex == 0 )
      {
        resourceType = "In Person";
      }
      else if(resourceTypeIndex == 1 )
      {
        resourceType = "Hotline";
      }
      else if( resourceTypeIndex == 2 )
      {
        resourceType = "Online";
      }
      else
      {
        resourceType = "App";
      }


      // check for cost options
      if( resourceCost == 0  )
      {
        costType = "Free";
      }
      else if( resourceCost == 1  )
      {
        costType = "Covered by Insurance";
      }
      else if(resourceCost == 2)
      {
        costType = "Subscription";
      }
      else
      {
        costType = "Fees associated";
      }

      //TODO: Need better error handling here
      resourceCollection.add(
      {
            'name': resourceName,
            'location': resourceLocation,
            'address': resourceAddress,
            'building': resourceBldg,
            'city': resourceCity,
            'state': resourceState,
            'zipcode': resourceZip,
            'phoneNumber': resourcePhoneNumber,
            'description': resourceDescription,
            'agerange': _currentDropDownValue,
            'verified': verified, //Always false upon creation
            'resourceType': resourceType,
            'privacy': selectedPrivacyOptions,
            'culturalResponse': culturalResponse,
            'culturalResponsivness': _currentSliderValue,
            'tagline': selectedTags,
            'dateAdded': date,
            'createdBy': userEmail,
	          'cost': costType
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

  // widget that creates the input field for resource name
  Widget buildNameField(windowSize, bool isSmallScreen) {
    return Container(
      margin: isSmallScreen
      ? EdgeInsets.symmetric(
          horizontal: windowSize.maxWidth / 20,
          vertical: windowSize.maxHeight / 20)
      : EdgeInsets.only(
          top: windowSize.maxHeight / 50,
          right: windowSize.maxWidth / 1.7,
          left: windowSize.maxWidth / 20),
      child: TextField(
        obscureText: false,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Name of the Resource',
        ),
        onChanged: ( text ) {
          resourceName = text;
        },
      ),
    );
  }

  // widget that creates the input field for resource link
  Widget buildLinkField(windowSize, bool isSmallScreen) {
    return Container(
      margin: isSmallScreen
          ? EdgeInsets.symmetric(
          horizontal: windowSize.maxWidth / 20,
          vertical: windowSize.maxHeight / 20 + 75)
      : EdgeInsets.only(
          top: windowSize.maxHeight / 50 + 75,
          right: windowSize.maxWidth / 1.7,
          left: windowSize.maxWidth / 20 ),
      child: TextField(
        obscureText: false,
        decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: "Link to the Resource"
        ),
        onChanged: ( text ) {
          resourceLocation = text;
        },
      ),
    );
  }

  // widget that creates the input field for in person address (line one)
  Widget buildAddressField(windowSize, bool isSmallScreen) {
    return Container(
      margin: isInPersonSelected
          ? (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20 + 150,
                )
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxHeight / 50 + 150))
          : (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20,
                )
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxWidth / 50 + 50)),
      child: Visibility(
        visible: isInPersonSelected,
        child: TextField(
          obscureText: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Address',
          ),
          onChanged: (text) {
            resourceAddress = text;
          },
        ),
      ),
    );
  }

  // widget that creates the input field for in person address (apt num, bldg num)
  Widget buildBldgNumField(windowSize, bool isSmallScreen) {
    return Container(
      margin: isInPersonSelected
          ? (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20 + 210)
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxHeight / 50 + 210))
          : (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20,
                )
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxWidth / 50 + 50,
                )),
      child: Visibility(
        visible: isInPersonSelected,
        child: TextField(
          obscureText: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Apartment, building, floor, etc.',
          ),
          onChanged: (text) {
            resourceBldg = text;
          },
        ),
      ),
    );
  }

  // widget that creates the inout field for in person address (city)
  Widget buildCityField(windowSize, bool isSmallScreen) {
    return Container(
      margin: isInPersonSelected
          ? (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20 + 270)
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxHeight / 50 + 270))
          : (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20,
                )
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxWidth / 50 + 50,
                )),
      child: Visibility(
        visible: isInPersonSelected,
        child: TextField(
          obscureText: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'City',
          ),
          onChanged: (text) {
            resourceCity = text;
          },
        ),
      ),
    );
  }

  // widget that creates the input field for in person address (state)
  Widget buildStateField(windowSize, bool isSmallScreen) {
    return Container(
      width: windowSize.maxWidth / 6,
      margin: isInPersonSelected
          ? (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20 + 330)
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxHeight / 50 + 330))
          : (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20,
                )
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxWidth / 50 + 50,
                )),
      child: Visibility(
        visible: isInPersonSelected,
        child: TextField(
          obscureText: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'State',
          ),
          onChanged: (text) {
            resourceState = text;
          },
        ),
      ),
    );
  }

  // widget that creates the input field for in person address (zipcode)
  Widget buildZipCodeField(windowSize, bool isSmallScreen) {
    return Container(
      width: windowSize.maxWidth / 6,
      margin: isInPersonSelected
          ? (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20 + 150,
                  vertical: windowSize.maxHeight / 20 + 330,
                )
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 4.10,
                  top: windowSize.maxHeight / 50 + 330,
                ))
          : (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20,
                )
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxWidth / 50 + 50,
                )),
      child: Visibility(
        visible: isInPersonSelected,
        child: TextField(
          obscureText: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Zip Code',
          ),
          onChanged: (text) {
            resourceZip = text;
          },
        ),
      ),
    );
  }

  // widget that creates the input field for phone number for hotline and in-person
  Widget buildPhoneNumField(windowSize, bool isSmallScreen) {
    return Container(
      margin: isHotlineSelected || isInPersonSelected
          ? (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: isHotlineSelected
                      ? windowSize.maxHeight / 20 + 150
                      : windowSize.maxHeight / 20 + 405,
                )
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: isInPersonSelected
                      ? windowSize.maxHeight / 50 + 405
                      : windowSize.maxHeight / 50 + 150,
                ))
          : (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20,
                )
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxHeight / 50 + 150,
                )),
      child: Visibility(
        visible: isHotlineSelected || isInPersonSelected,
        child: TextField(
          obscureText: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: 'Phone Number',
          ),
          onChanged: (text) {
            resourcePhoneNumber = text;
          },
        ),
      ),
    );
  }

  // widget that creates the input field for resource description
  Widget buildDescriptionField(windowSize, bool isSmallScreen) {
    return Container(
      margin: isHotlineSelected
          ? (isSmallScreen
              ? EdgeInsets.symmetric(
                  horizontal: windowSize.maxWidth / 20,
                  vertical: windowSize.maxHeight / 20 + 225,
                )
              : EdgeInsets.only(
                  right: windowSize.maxWidth / 1.7,
                  left: windowSize.maxWidth / 20,
                  top: windowSize.maxHeight / 50 + 225,
                ))
          : (isInPersonSelected
              ? (isSmallScreen
                  ? EdgeInsets.symmetric(
                      horizontal: windowSize.maxWidth / 20,
                      vertical: windowSize.maxHeight / 20 + 480,
                    )
                  : EdgeInsets.only(
                      right: windowSize.maxWidth / 1.7,
                      left: windowSize.maxWidth / 20,
                      top: windowSize.maxHeight / 50 + 480,
                    ))
              : (isSmallScreen
                  ? EdgeInsets.symmetric(
                      horizontal: windowSize.maxWidth / 20,
                      vertical: windowSize.maxHeight / 20 + 150,
                    )
                  : EdgeInsets.only(
                      right: windowSize.maxWidth / 1.7,
                      left: windowSize.maxWidth / 20,
                      top: windowSize.maxHeight / 50 + 150,
                    ))),
      child: TextField(
        obscureText: false,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Description of the Resource',
        ),
        onChanged: (text) {
          resourceDescription = text;
        },
      ),
    );
  }

  // widget that builds all the text input fields
  Widget buildInputFields (windowSize, bool isSmallScreen)
  {
    return Stack (
      children:[
        // container for resource name input
        buildNameField(windowSize, isSmallScreen),
        // container for the resource link input
        buildLinkField(windowSize, isSmallScreen),
        // container for in-person address input
        buildAddressField(windowSize, isSmallScreen),
        // use a container for in-person building input
        buildBldgNumField(windowSize, isSmallScreen),
        // use a container for in-person city input
        buildCityField(windowSize, isSmallScreen),
        // container for in-person state input
        buildStateField(windowSize, isSmallScreen),
        // container for in-person zipcode input
        buildZipCodeField(windowSize, isSmallScreen),
        // input box for phone number for in person or hotline
        buildPhoneNumField(windowSize, isSmallScreen),
        // container for resource description
        buildDescriptionField(windowSize, isSmallScreen),
      ]
    );
  }

  // widget for building the input box for tags
  Widget buildTagsInput(windowSize, topDivisor, rightDivisor) {
    return // container to display tags input field
        new Container(
      margin: EdgeInsets.only(
        right: windowSize.maxWidth / rightDivisor,
        left: windowSize.maxWidth / 20,
        top: isHotlineSelected
            ? windowSize.maxHeight / topDivisor + 300
            : (isInPersonSelected
                ? windowSize.maxHeight / topDivisor + 555
                : windowSize.maxHeight / topDivisor + 225),
      ),
      child: TextField(
        obscureText: false,
        controller: _controller,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: 'Please provide tags for the resource',
        ),
        onSubmitted: (text) {
          if (text != "") {
            setState(() {
              _controller.clear();
              selectedTags.add(text);
            });
          }
        },
      ),
    );
  }

  // widget for displaying active tags
  Widget buildActiveTagsDisplay(windowSize, topDivisor, rightDivisor) {
    return new Container(
      margin: EdgeInsets.only(
        right: windowSize.maxWidth / rightDivisor,
        left: windowSize.maxWidth / 20,
        top: isHotlineSelected
            ? windowSize.maxHeight / topDivisor + 355
            : (isInPersonSelected
                ? windowSize.maxHeight / topDivisor + 610
                : windowSize.maxHeight / topDivisor + 280),
      ),
      child: new Stack(
        children: [
          Text(
            "Your active tags. Click to remove",
            style: TextStyle(fontSize: 15.0),
          ),
          Container(
            child: Wrap(
              spacing: 5.0,
              children: selectedTags.map((tag) {
                return Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 4.0, vertical: 20.0),
                  child: InputChip(
                    label: Text(tag),
                    backgroundColor: Colors.blue[200],
                    onDeleted: () {
                      setState(() {
                        selectedTags.remove(tag);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildResourceTypeTitle(windowSize, isSmallScreen){
    // resource type title
    return Padding(
      padding: EdgeInsets.only(
          top: isSmallScreen ?
          isHotlineSelected
              ? windowSize.maxHeight / 20 + 415
              : (isInPersonSelected
              ? windowSize.maxHeight / 20 + 670
              : windowSize.maxHeight / 20 + 340)
          : windowSize.maxHeight / 50,
          left: isSmallScreen ? windowSize.maxWidth / 20 : windowSize.maxWidth / 1.9,
          right: isSmallScreen ? windowSize.maxWidth / 20 : 0),
      child: Text(
        "Resource Type",
        style: TextStyle(fontSize: 20.0),
      ),
    );
  }

  // widget for building the resource type selection (radio buttons)
  Widget buildResourceTypeOptions(windowSize, isSmallScreen, leftDivisor) {
    //  container of radio buttons for resource type
    return
      Container(
      margin: EdgeInsets.only(
          top: isSmallScreen
              ? isHotlineSelected
                  ? windowSize.maxHeight / 20 + 440
                  : (isInPersonSelected
                      ? windowSize.maxHeight / 20 + 695
                      : windowSize.maxHeight / 20 + 365)
              : windowSize.maxHeight / 50 + 50,
          left: windowSize.maxWidth / leftDivisor),
      child: SizedBox(
        child: ListView(
          padding: EdgeInsets.only(right: 30.0),
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          children: [
            Column(
              children: resourceTypeOptions.map((option) {
                int index = resourceTypeOptions.indexOf(option);
                return ListTile(
                  dense: true,
                  leading: Radio(
                    value: index,
                    groupValue: resourceTypeIndex,
                    onChanged: (value) {
                      setState(() {
                        resourceTypeIndex = value!;
                        isHotlineSelected =
                            (resourceTypeOptions[value] == "Hotline");
                        isInPersonSelected =
                            (resourceTypeOptions[value] == "In Person");
                      });
                    },
                  ),
                  title: Text(
                    option,
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildPrivacyTitle(windowSize, isSmallScreen)
  {
    return Padding(
      padding: EdgeInsets.only(
          top: isSmallScreen ?
          isHotlineSelected
          ? windowSize.maxHeight / 20 + 415
              : (isInPersonSelected
          ? windowSize.maxHeight / 20 + 670
              : windowSize.maxHeight / 20 + 340)
          : windowSize.maxHeight / 50,
          right: isSmallScreen ? windowSize.maxWidth / 20 : windowSize.maxWidth / 15,
          left: isSmallScreen ? windowSize.maxWidth / 1.8 : windowSize.maxWidth / 1.27),
      child: Text(
        "Privacy Protections",
        style: TextStyle(fontSize: 20.0),
      ),
    );
  }

  // widget for building the privacy option selection (check boxes)
  Widget buildPrivacyOptions(windowSize, isSmallScreen, leftDivisor) {
    return Container(
      margin: EdgeInsets.only(
          top: isSmallScreen
              ? isHotlineSelected
                  ? windowSize.maxHeight / 20 + 440
                  : (isInPersonSelected
                      ? windowSize.maxHeight / 20 + 695
                      : windowSize.maxHeight / 20 + 365)
              : windowSize.maxHeight / 50 + 50,
          left: windowSize.maxWidth / leftDivisor),
      child: SizedBox(
        child: ListView(
          padding: EdgeInsets.only(right: 30.0),
          shrinkWrap: true,
          children: List<Widget>.generate(
                  _selectedPrivacy.length,
                  (int index) => CheckboxListTile(
                        title: Text(resourcePrivacy[index],
                            style: TextStyle(fontSize: 16)),
                        value: _selectedPrivacy[index],
                        onChanged: (value) {
                          setState(() {
                            _selectedPrivacy[index] = value!;
                            if (value) {
                              selectedPrivacyOptions
                                  .add(resourcePrivacy[index]);
                            } else {
                              selectedPrivacyOptions
                                  .remove(resourcePrivacy[index]);
                            }
                          });
                        },
                        controlAffinity: ListTileControlAffinity.leading,
                        dense: true,
                      )),
            ),
      ),
    );
  }

  Widget buildCostTitle(windowSize, isSmallScreen)
  {
    return Center(
      child: Container(
        child: Padding(
          padding: EdgeInsets.only(
              top: isSmallScreen ?
              isHotlineSelected
              ? windowSize.maxHeight / 20 + 640
                  : (isInPersonSelected
              ? windowSize.maxHeight / 20 + 895
                  : windowSize.maxHeight / 20 + 565)
              : windowSize.maxHeight / 50 + 250,
              left: isSmallScreen ? 0 : windowSize.maxWidth / 2.5),
          child: Text(
            "Resource Cost",
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      ),
    );
  }

  // widget for building the resource cost option selection ( radio buttons)
  Widget buildCostOptions(windowSize, isSmallScreen, leftDivisor, leftPadding) {
    return Center(
      child: new Container(
        margin: EdgeInsets.only(
            top: isSmallScreen
                ? isHotlineSelected
                    ? windowSize.maxHeight / 20 + 665
                    : (isInPersonSelected
                        ? windowSize.maxHeight / 20 + 920
                        : windowSize.maxHeight / 20 + 590)
                : windowSize.maxHeight / 50 + 275,
            left: windowSize.maxWidth / leftDivisor),
        child: SizedBox(
          child: GridView.count(
            crossAxisCount: 2,
            // number of columns
            padding: EdgeInsets.only(right: 40.0, left: leftPadding),
            childAspectRatio: !isSmallScreen
                ? windowSize.maxWidth >= 1200
                    ? 8
                    : (windowSize.maxWidth >= 900 &&
                            windowSize.maxWidth <= 1000)
                        ? 5
                        : 6
                : windowSize.maxWidth > 600
                    ? 8
                    : 5.5,
            shrinkWrap: true,
            children: resourceCostOptions.getRange(0, 4).map((option) {
              int index = resourceCostOptions.indexOf(option);
              return ListTile(
                dense: true,
                leading: Radio(
                  value: index,
                  groupValue: resourceCost,
                  onChanged: (value) {
                    setState(() {
                      resourceCost = value!;
                    });
                  },
                ),
                title: Text(option, style: TextStyle(fontSize: 16)),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // widget to display cultural responsiveness title
  Widget buildCulturalResponTitle (windowSize, isSmallScreen)
  {
    return Center(
      child: Container(
        child: Padding(
          padding: EdgeInsets.only(
              top: isSmallScreen ?
              isHotlineSelected
              ? windowSize.maxHeight / 20 + 780
                  : (isInPersonSelected
              ? windowSize.maxHeight / 20 + 1045
                  : windowSize.maxHeight / 20 + 715)
              : windowSize.maxHeight / 50 + 400,
              left: isSmallScreen ? 0 : windowSize.maxWidth / 2.5),
          child: Text(
            "Cultural Responsiveness",
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      ),
    );
  }

  // widget for building the cultural responsiveness slider
  Widget buildCulturalResponSlider(windowSize, isSmallScreen) {
    return Center(
      child: new Container(
        margin: EdgeInsets.only(
            top: isSmallScreen
                ? isHotlineSelected
                    ? windowSize.maxHeight / 20 + 805
                    : (isInPersonSelected
                        ? windowSize.maxHeight / 20 + 1070
                        : windowSize.maxHeight / 20 + 740)
                : windowSize.maxHeight / 50 + 435,
            left: isSmallScreen ? 0 : windowSize.maxWidth / 2.5),
        height: 50,
        width: windowSize.maxWidth / 50 + 450,
        child: Center(
          child: Stack(
            children: [
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  valueIndicatorColor: Colors.blue,
                  valueIndicatorTextStyle: TextStyle(color: Colors.white),
                ),
                child: Slider(
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
              // anchor descriptions for slider
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Tooltip(
                      message:
                          "Not culturally specific to Hopi or Indigenous communities",
                      child: Text("Low ")),
                  Spacer(),
                  Tooltip(
                      message: "Specific resource for Hopi community",
                      child: Text("High")),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // widget for displaying the age range title
  Widget buildAgeRangeTitle(windowSize, isSmallScreen) {
    return Center(
      child: Container(
        child: Padding(
          padding: EdgeInsets.only(
              top: isSmallScreen ?
              isHotlineSelected
              ? windowSize.maxHeight / 20 + 880
                  : (isInPersonSelected
              ? windowSize.maxHeight / 20 + 1145
                  : windowSize.maxHeight / 20 + 815)
                  : windowSize.maxHeight / 50 + 500,
              left: isSmallScreen ? 0 : windowSize.maxWidth / 2.5),
          child: Text(
            "Age Range of Resource",
            style: TextStyle(fontSize: 20.0),
          ),
        ),
      ),
    );
  }

  // widget for building the age range selector
  Widget buildAgeSelector(windowSize, isSmallScreen) {
    return Center(
      child: new Container(
        margin: EdgeInsets.only(
            top: isSmallScreen
                ? isHotlineSelected
                    ? windowSize.maxHeight / 20 + 905
                    : (isInPersonSelected
                        ? windowSize.maxHeight / 20 + 1170
                        : windowSize.maxHeight / 20 + 840)
                : windowSize.maxHeight / 50 + 525,
            left: isSmallScreen ? 0 : windowSize.maxWidth / 2.5),
        child: DropdownButton(
          value: _currentDropDownValue,
          onChanged: (String? newValue) {
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
      ),
    );
  }

  // widget for building the submit button to submit the resource for verification
  Widget buildSubmitButton(
      windowSize, int divisor, bool isSmallScreen, int height) {
    return Center(
      child: new Container(
          margin: EdgeInsets.only(
            top: windowSize.maxHeight / divisor + height,
          ),
          child: TextButton(
            style: ButtonStyle(
                minimumSize: MaterialStateProperty.all<Size>(Size(150, 45)),
                foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
                backgroundColor: MaterialStateProperty.all<Color>(Colors.blue),
                shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                    RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18.0),
                        side: BorderSide(color: Colors.blue)))),
            onPressed: () {
              submitResource(
                  resourceName, resourceLocation, resourceDescription, context);
            },
            child: Text('Submit Resource'),
          )),
    );
  }

  // widget to build screen layout if the screen is large
  Widget buildLargeScreenLayout(windowSize, isSmallScreen) {
    return SingleChildScrollView(
      child: Container(
          child: new Stack(children: [
        // displays the resource text input fields
        buildInputFields(windowSize, isSmallScreen),
        // displays the tag input field
        buildTagsInput(windowSize, 50, 1.7),
        // displays the active tags
        buildActiveTagsDisplay(windowSize, 50, 1.7),
        // resource type title
        buildResourceTypeTitle(windowSize, isSmallScreen),
        // resource type selection
        buildResourceTypeOptions(windowSize, isSmallScreen, 1.95),
        SizedBox(height: 20),
        // privacy protection title
        buildPrivacyTitle(windowSize, isSmallScreen),
        // container of checkboxes for privacy options
        buildPrivacyOptions(windowSize, isSmallScreen, 1.3),
        SizedBox(height: 20),
        // cost of resource title
        buildCostTitle(windowSize, isSmallScreen),
        // list of cost radio buttons
        buildCostOptions(windowSize, isSmallScreen, 1.9, 0),
        SizedBox(height: 20),
        // cultural responsiveness title
        buildCulturalResponTitle(windowSize, isSmallScreen),
        // cultural responsiveness slider with anchors
        buildCulturalResponSlider(windowSize, isSmallScreen),
        // age range title
        buildAgeRangeTitle(windowSize, isSmallScreen),
        // age selection drop down
        buildAgeSelector(windowSize, isSmallScreen),

        // create the submit button and display relative to screen size
        buildSubmitButton(windowSize, 50, isSmallScreen, 650),
      ])),
    );
  }

  // widget to build the screen layout if the screen is small
  Widget buildSmallScreenLayout(windowSize, isSmallScreen) {
    return SingleChildScrollView(
        child: Container(
            child: Stack(children: [
      // display all text input fields for a resource
      buildInputFields(windowSize, isSmallScreen),
      // display the tag input field
      buildTagsInput(windowSize, 20, 20),
      // display active tags
      buildActiveTagsDisplay(windowSize, 20, 20),
      // resource type title
      buildResourceTypeTitle(windowSize, isSmallScreen),
      //  container of radio buttons for resource type
      buildResourceTypeOptions(windowSize, isSmallScreen, 30),
      SizedBox(height: 20),
      buildPrivacyTitle(windowSize, isSmallScreen),
      // container of checkboxes for privacy options
      buildPrivacyOptions(windowSize, isSmallScreen, 1.8),
      SizedBox(height: 20),
      // cost of resource title
      buildCostTitle(windowSize, isSmallScreen),
      // list of cost radio buttons
      buildCostOptions(windowSize, isSmallScreen, 15, 40),
      SizedBox(height: 20),
      // cultural responsiveness title
      buildCulturalResponTitle(windowSize, isSmallScreen),
      // cultural responsiveness slider with anchors
      buildCulturalResponSlider(windowSize, isSmallScreen),
      // age range title
      buildAgeRangeTitle(windowSize, isSmallScreen),
      // age selection drop down
      buildAgeSelector(windowSize, isSmallScreen),

      // create the submit button and display relative to screen size
      buildSubmitButton(windowSize, 20, isSmallScreen,
          isHotlineSelected ? 980 : (isInPersonSelected ? 1245 : 915)),
    ])));
  }

  //Create resource UI depending on screen size
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Resource'),
      ),
      body: LayoutBuilder(
        builder: (context, windowSize) {
          // get the screen size
          bool isSmallScreen = windowSize.maxWidth < 900;
          // check if the screen is large
          if (!isSmallScreen) {
            return buildLargeScreenLayout(windowSize, isSmallScreen);
          }
          // otherwise, screen is small
          else {
            return buildSmallScreenLayout(windowSize, isSmallScreen);
          }
        },
      ),
    );
  }
}