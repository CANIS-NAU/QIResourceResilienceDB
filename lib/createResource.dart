//Import packages
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

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

showAlertDialog(BuildContext context) {

  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Alert"),
    content: Text("Your resource has successfully been submitted"),
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

  //Init collection from db
  CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');
  //final Stream<QuerySnapshot> resources = FirebaseFirestore.instance.collection('resources').where('verified', isEqualTo: true ).snapshots();

  //Submit to DB
  Future<void> submitResource( resourceName, resourceLocation, resourceDescription, context )
  {
    String resourceType = "", privacyType = "",
        culturalResponse = "", costType = "";

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

    //Check for privacy options in Bool array, required to convert to string
    if( _selectedPrivacy[ 0 ] )
    {
      privacyType = "HIPAA Compliant";
    }
    else if( _selectedPrivacy[ 1 ] )
    {
      privacyType = "Anonymous";
    }
    else if(_selectedPrivacy [2])
    {
      privacyType = "Mandatory Reporting";
    }
    else
    {
      privacyType = "None Stated";
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

    //Add resource to db with provided values
    //TODO: Need better error handling here
    return resourceCollection.add(
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
	'cost': costType
      }
    ).then(( value ) => showAlertDialog( context ) )
     .catchError((error) => print("Failed to add doc: $error") );
  }

  // widget that creates the input field for resource name
  Widget buildNameField(windowSize) {
    return Container(
      margin: EdgeInsets.only(
          top: windowSize.maxHeight / 50,
          right: windowSize.maxWidth / 2,
          left: windowSize.maxWidth / 10),
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
  Widget buildLinkField(windowSize) {
    return Container(
      margin: EdgeInsets.only(
          top: windowSize.maxHeight / 50 + 75,
          right: windowSize.maxWidth / 2,
          left: windowSize.maxWidth / 10 ),
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
  Widget buildAddressField(windowSize){
    return Container(
      margin: EdgeInsets.only(
          right: windowSize.maxWidth / 2,
          left: windowSize.maxWidth / 10,
          top: isInPersonSelected
              ? windowSize.maxHeight / 50 + 150
              : windowSize.maxWidth / 50 + 50
      ),
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
  Widget buildBldgNumField(windowSize){
    return Container(
      margin: EdgeInsets.only(
          right: windowSize.maxWidth / 2,
          left: windowSize.maxWidth / 10,
          top: isInPersonSelected
              ? windowSize.maxHeight / 50 + 210
              : windowSize.maxWidth / 50 + 50
      ),
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
  Widget buildCityField(windowSize){
    return Container(
      margin: EdgeInsets.only(
          right: windowSize.maxWidth / 2,
          left: windowSize.maxWidth / 10,
          top: isInPersonSelected
              ? windowSize.maxHeight / 50 + 270
              : windowSize.maxWidth / 50 + 50
      ),
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
  Widget buildStateField(windowSize){
    return Container(
      width: windowSize.maxWidth / 6,
      margin: EdgeInsets.only(
          right: windowSize.maxWidth / 2,
          left: windowSize.maxWidth / 10,
          top: isInPersonSelected
              ? windowSize.maxHeight / 50 + 330
              : windowSize.maxWidth / 50 + 50
      ),
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
  Widget buildZipCodeField(windowSize){
    return Container(
      width: windowSize.maxWidth / 6,
      margin: EdgeInsets.only(
          left: windowSize.maxWidth / 3,
          top: isInPersonSelected
              ? windowSize.maxHeight / 50 + 330
              : windowSize.maxWidth / 50 + 50
      ),
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
  Widget buildPhoneNumField(windowSize){
    return Container(
      margin: EdgeInsets.only(
        right: windowSize.maxWidth / 2,
        left: windowSize.maxWidth / 10,
        top: isInPersonSelected
            ? windowSize.maxHeight / 50 + 405
            : windowSize.maxHeight / 50 + 150,
      ),
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
  Widget buildDescriptionField(windowSize){
    return Container(
      margin: EdgeInsets.only(
        right: windowSize.maxWidth / 2,
        left: windowSize.maxWidth / 10,
        top: isHotlineSelected
            ? windowSize.maxHeight / 50 + 225
            : (isInPersonSelected
            ? windowSize.maxHeight / 50 + 480
            : windowSize.maxHeight / 50 + 150),
      ),
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
    );
  }

  //Create resource UI
  @override
  Widget build( BuildContext context ) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Resource'),
      ),
      body: LayoutBuilder( builder: ( context, windowSize ) {
        return Container(
                    child: new Stack( children: [
                      // container for resource name input
                      buildNameField(windowSize),
                      // container for the resource link input
                      buildLinkField(windowSize),
                      // container for in-person address input
                      buildAddressField(windowSize),
                      // use a container for in-person building input
                      buildBldgNumField(windowSize),
                      // use a container for in-person city input
                      buildCityField(windowSize),
                      // container for in-person state input
                      buildStateField(windowSize),
                      // container for in-person zipcode input
                      buildZipCodeField(windowSize),
                      // input box for phone number for in person or hotline
                      buildPhoneNumField(windowSize),
                      // container for resource description
                      buildDescriptionField(windowSize),

                      // container to display tags input field
                      new Container(
                        margin: EdgeInsets.only(
                          right: windowSize.maxWidth / 2,
                          left: windowSize.maxWidth / 10,
                          top: isHotlineSelected
                              ? windowSize.maxHeight / 50 + 300
                              : (isInPersonSelected
                              ? windowSize.maxHeight / 50 + 555
                              : windowSize.maxHeight / 50 + 225),
                        ),
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
                      // displays the active tags
                      new Container(
                        margin: EdgeInsets.only(
                          right: windowSize.maxWidth / 2,
                          left: windowSize.maxWidth / 10,
                          top: isHotlineSelected
                              ? windowSize.maxHeight / 50 + 355
                              : (isInPersonSelected
                              ? windowSize.maxHeight / 50 + 605
                              : windowSize.maxHeight / 50 + 280),
                        ),
                        child:
                        new Stack(
                          children: [
                            Text(
                              "Your active tags. Click to remove",
                              style: TextStyle(fontSize: 15.0),
                            ),
                            Container(
                              child: Wrap(
                                spacing: 5.0,
                                runSpacing: 5.0,
                                children: selectedTags.map((tag) {
                                  return Padding(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 4.0, vertical: 20.0),
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
                      ),

                      // resource type title
                          Padding(
                            padding: EdgeInsets.only(
                                top: windowSize.maxHeight / 50,
                                right: windowSize.maxWidth / 9,
                                left: windowSize.maxWidth / 1.6 ),
                            child: Text("Resource Type",
                              style: TextStyle( fontSize: 20.0 ),
                            ),
                          ),
                            //  container of radio buttons for resource type
                            new Container(
                                margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 25,
                                    left: windowSize.maxWidth / 1.65 ),
                                child: SizedBox(
                                  child: ListView(
                                    padding: EdgeInsets.only(right: 30.0),
                                    scrollDirection: Axis.vertical,
                                    shrinkWrap: true,
                                    children: [
                                      Column(
                                        children:
                                        resourceTypeOptions.map((option) {
                                          int index = resourceTypeOptions.indexOf(option);
                                          return ListTile(
                                            dense: true,
                                            leading: Radio(
                                              value: index,
                                              groupValue: resourceTypeIndex,
                                              onChanged: (value) {
                                                setState(() {
                                                  resourceTypeIndex = value!;
                                                  isHotlineSelected = (resourceTypeOptions[value] == "Hotline");
                                                  isInPersonSelected = (resourceTypeOptions[value] == "In Person");
                                                });
                                              },
                                            ),
                                            title: Text(option, style: TextStyle(fontSize: 16),),
                                          );
                                        }).toList(),
                                      ),
                                    ],
                                  ),
                                ),

                            ),
                            SizedBox(height: 20 ),
                            Padding(
                            padding: EdgeInsets.only( top: windowSize.maxHeight / 50 ,
                                right: windowSize.maxWidth / 12,
                                left: windowSize.maxWidth / 1.27 ),
                            child: Text("Privacy Protections",
                                  style: TextStyle(fontSize: 20.0),
                                ),
                          ),
                          // container of checkboxes for privacy options
                          new Container(
                                margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 25,
                                    left: windowSize.maxWidth / 1.3 ),
                                child: SizedBox(
                                  child: ListView(
                                  padding: EdgeInsets.only(right: 30.0),
                                  shrinkWrap: true,
                                    children: [
                                      Column(
                                      children: List<CheckboxListTile>.generate(
                                        _selectedPrivacy.length,
                                          (int index) => CheckboxListTile(
                                            title: Text(resourcePrivacy[index], style: TextStyle(fontSize: 16)),
                                            value: _selectedPrivacy[index],
                                            onChanged: (value) {
                                              setState(() {
                                                _selectedPrivacy[index] = value!;
                                                if(value) {
                                                  selectedPrivacyOptions.add(resourcePrivacy[index]);
                                                } else {
                                                  selectedPrivacyOptions.remove(resourcePrivacy[index]);
                                                }
                                              });
                                            },
                                            controlAffinity: ListTileControlAffinity.leading,
                                            dense: true,
                                              )
                                      ),
                                    ),
                                    ],
                                  ),
                                ),
                          ),
                            // cost of resource title
                          SizedBox(height: 20 ),
                          Padding(
                            padding: EdgeInsets.only( top: windowSize.maxHeight / 50 + 225,
                                right: windowSize.maxWidth / 9,
                                left: windowSize.maxWidth / 1.40 ),
                            child: Text("Resource Cost",
                                style: TextStyle(fontSize: 20.0),
                            ),
                          ),
                          // list of cost radio buttons
                          new Container(
                            margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 250,
                                left: windowSize.maxWidth / 1.65 ),
                                child: SizedBox(
                                  child: GridView.count(
                                    crossAxisCount: 2, // number of columns
                                    padding: EdgeInsets.only(right: 30.0),
                                    childAspectRatio: 7,
                                    shrinkWrap: true,
                                      children:
                                      resourceCostOptions.getRange(0, 4).map((option) {
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

                            SizedBox(height: 20 ),
                            Padding(
                            padding: EdgeInsets.only( top: windowSize.maxHeight / 50 + 375,
                                right: windowSize.maxWidth / 9,
                                left: windowSize.maxWidth / 1.43 ),
                            child: Text("Cultural Responsiveness",
                                  style: TextStyle( fontSize: 20.0 ),
                            ),
                        ),
                        // cultural responsiveness slider with anchors
                          new Container(
                          margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 400,
                              left: windowSize.maxWidth / 1.63 ),
                          height: 50,
                          width: windowSize.maxWidth/ 50 + 450,
                                child:
                                    Center( child: Stack(
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
                                              onChanged: ( double value ) {
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
                                            Tooltip(message:"Not culturally specific to Hopi or Indigenous communities",
                                                child: Text("Low ")),
                                            Spacer(),
                                            Tooltip(message: "Specific resource for Hopi community",
                                                child: Text("High")),
                                          ],
                                          ),
                                      ],
                                      ),
                                    ),
                            ),
                            Padding(
                            padding: EdgeInsets.only( top: windowSize.maxHeight / 50 + 475,
                                right: windowSize.maxWidth / 9,
                                left: windowSize.maxWidth / 1.43 ),
                            child: Text("Age Range of Resource",
                                  style: TextStyle( fontSize: 20.0 ),
                                ),
                          ),
                           // age selection drop down
                           new Container(
                            margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 500,
                                left: windowSize.maxWidth / 1.35 ),
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
                            Center( child: new Container(
                                margin: EdgeInsets.only( top: windowSize.maxHeight / 50 + 600,),
                                child:
                                  TextButton(
                                    style: ButtonStyle(
                                      minimumSize: MaterialStateProperty.all<Size>(Size(150, 45)),
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
                            ),
                    ]
                  )
      );
     },
    ),
   );
  }
}
