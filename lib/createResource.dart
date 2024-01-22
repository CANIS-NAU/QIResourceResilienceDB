/*
This page allows users to submit a resource for review by
entering resource information such as:
name, description, link, address (if in person),
phone number (if hotline or in person), type, privacy,
cost, cultural responsiveness, and age range.
*/

//Import packages
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'events/schedule.dart';
import 'events/schedule_form.dart';

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

showAlertDialog(BuildContext context, String statement) {
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
    content: Text(statement),
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
  CreateResource({super.key});

  //final String title;

  @override
  State<CreateResource> createState() => createResourceState();
}

//List of strings for resource type
const List<String> resourceTypeOptions = [
  'In Person',
  'Hotline',
  'Online',
  'Podcast',
  'App',
  'Event',
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
  String resourceCost = "";
  String resourceType = "";
  Schedule? resourceSchedule = null;

  //Specifies first value in dropdown to first in the list
  String _currentDropDownValue = ageItems.first;

  //Tags created stored in tag array
  List<dynamic> selectedTags = [];

  //For text deletion on textbox submit
  var _controller = TextEditingController();

  // used to store selected privacy options
  final List<bool> _selectedPrivacy =
      List<bool>.filled(resourcePrivacy.length, false);
  List<String> selectedPrivacyOptions = [];

  // boolean to track hotline and in person selection
  bool isHotlineSelected = false;
  bool isInPersonSelected = false;
  bool isEventSelected = false;

  bool vertical = false;
  bool verified = false;

  //Submit to DB
  void submitResource(
      resourceName, resourceLocation, resourceDescription, context) {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      CollectionReference resourceCollection =
          FirebaseFirestore.instance.collection('resources');

      String culturalResponse = "";
      if (_currentSliderValue >= 0 && _currentSliderValue <= 1) {
        culturalResponse = "Low Cultural Responsivness";
      } else if (_currentSliderValue >= 2 && _currentSliderValue <= 3) {
        culturalResponse = "Medium Cultural Responsivness";
      } else {
        culturalResponse = "High Cultural Responsivness";
      }

      //TODO: Need better error handling here
      resourceCollection
          .add({
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
            'isVisable': true,
            'verified': verified, //Always false upon creation
            'resourceType': resourceType,
            'privacy': selectedPrivacyOptions,
            'culturalResponse': culturalResponse,
            'culturalResponsivness': _currentSliderValue,
            'tagline': selectedTags,
            'dateAdded': date,
            'createdBy': user.email,
            'cost': resourceCost,
            if (resourceSchedule != null)
              'schedule': resourceSchedule!.toJson(),
          })
          .then((value) =>
              showAlertDialog(context, "Submitted resource for review"))
          .catchError((error) {
            debugPrint(error.toString());
            showAlertDialog(context, "Unable to submit. Please try again");
          });
    } else {
      showAlertDialog(context, "You need to login to submit a resource");
    }
  }

  // widget to build a text field based on name and if visible
  Widget buildTextFieldContainer(
      String label, bool isVisible, Function(String) onChangedCallback) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isVisible ? 8.0 : 0.0),
      child: Visibility(
        visible: isVisible,
        child: TextField(
          obscureText: false,
          decoration: InputDecoration(
            border: OutlineInputBorder(),
            labelText: label,
          ),
          onChanged: onChangedCallback,
        ),
      ),
    );
  }

  // widget for building resource option titles
  Widget buildTitles(String title) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: Text(
          title,
          style: TextStyle(fontSize: 20.0),
        ),
      ),
    );
  }

// Create resource UI
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Submit Resource'),
      ),
      body: LayoutBuilder(
        builder: (context, windowSize) {
          return Align(
              alignment: Alignment.topCenter,
              child: Container(
                  constraints: BoxConstraints(maxWidth: 600),
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                      child: ListView(
                    children: [
                      buildTextFieldContainer(
                        'Name of the Resource',
                        true,
                        (text) {
                          resourceName = text;
                        },
                      ),
                      buildTextFieldContainer(
                        'Link to the Resource',
                        true,
                        (text) {
                          resourceLocation = text;
                        },
                      ),
                      buildTextFieldContainer(
                        'Address',
                        isInPersonSelected,
                        (text) {
                          resourceAddress = text;
                        },
                      ),
                      buildTextFieldContainer(
                        'Apartment, building, floor, etc.',
                        isInPersonSelected,
                        (text) {
                          resourceBldg = text;
                        },
                      ),
                      buildTextFieldContainer(
                        'City',
                        isInPersonSelected,
                        (text) {
                          resourceCity = text;
                        },
                      ),
                      buildTextFieldContainer(
                        'State',
                        isInPersonSelected,
                        (text) {
                          resourceState = text;
                        },
                      ),
                      buildTextFieldContainer(
                        'Zip Code',
                        isInPersonSelected,
                        (text) {
                          resourceZip = text;
                        },
                      ),
                      buildTextFieldContainer(
                        'Phone Number',
                        isHotlineSelected || isInPersonSelected,
                        (text) {
                          resourcePhoneNumber = text;
                        },
                      ),
                      buildTextFieldContainer(
                        'Description of the Resource',
                        true,
                        (text) {
                          resourceDescription = text;
                        },
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
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
                      ),
                      Container(
                        child: new Stack(
                          children: [
                            Text(
                              "Your active tags. Click to remove",
                              style: TextStyle(fontSize: 14.0),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(vertical: 16.0),
                              child: Wrap(
                                spacing: 5.0,
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
                      Visibility(
                        visible: isEventSelected,
                        child: Column(children: [
                          buildTitles("Event Schedule"),
                          ScheduleFormFields(
                            onChanged: (schedule) {
                              setState(() {
                                resourceSchedule = schedule;
                              });
                            },
                          ),
                        ]),
                      ),
                      buildTitles("Resource Type"),
                      Container(
                        child: ListView(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          children: [
                            Column(
                              children: resourceTypeOptions.map((option) {
                                return ListTile(
                                  dense: true,
                                  leading: Radio(
                                    value: option,
                                    groupValue: resourceType,
                                    onChanged: (value) {
                                      setState(() {
                                        resourceType = value!;
                                        isHotlineSelected =
                                            (value == "Hotline");
                                        isInPersonSelected =
                                            (value == "In Person");
                                        isEventSelected = (value == "Event");
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
                      buildTitles("Privacy Protections"),
                      Container(
                        child: SizedBox(
                          child: ListView(
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
                                      controlAffinity:
                                          ListTileControlAffinity.leading,
                                      dense: true,
                                    )),
                          ),
                        ),
                      ),
                      buildTitles("Resource Cost"),
                      Center(
                        child: new Container(
                          child: SizedBox(
                            child: ListView(
                                padding: EdgeInsets.only(right: 30),
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                children: [
                                  Column(
                                    children: resourceCostOptions.map((option) {
                                      return ListTile(
                                        dense: true,
                                        leading: Radio(
                                          value: option,
                                          groupValue: resourceCost,
                                          onChanged: (value) {
                                            setState(() {
                                              resourceCost = value!;
                                            });
                                          },
                                        ),
                                        title: Text(option,
                                            style: TextStyle(fontSize: 16)),
                                      );
                                    }).toList(),
                                  ),
                                ]),
                          ),
                        ),
                      ),
                      buildTitles("Cultural Responsiveness"),
                      Center(
                        child: new Container(
                          child: Center(
                            child: Stack(
                              children: [
                                SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    valueIndicatorColor: Colors.blue,
                                    valueIndicatorTextStyle:
                                        TextStyle(color: Colors.white),
                                  ),
                                  child: Slider(
                                    value: _currentSliderValue,
                                    max: 5,
                                    divisions: 5,
                                    label:
                                        _currentSliderValue.round().toString(),
                                    onChanged: (double value) {
                                      setState(() {
                                        _currentSliderValue = value;
                                      });
                                    },
                                  ),
                                ),
                                // anchor descriptions for slider
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Tooltip(
                                        message:
                                            "Not culturally specific to Hopi or Indigenous communities",
                                        child: Text("Low ")),
                                    Spacer(),
                                    Tooltip(
                                        message:
                                            "Specific resource for Hopi community",
                                        child: Text("High")),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      buildTitles("Age Range of Resource"),
                      Center(
                        child: new Container(
                          child: DropdownButton(
                            value: _currentDropDownValue,
                            onChanged: (String? newValue) {
                              setState(() {
                                _currentDropDownValue = newValue!;
                              });
                            },
                            items: ageItems
                                .map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      Center(
                        child: new Container(
                            padding: EdgeInsets.symmetric(vertical: 20.0),
                            child: TextButton(
                              style: ButtonStyle(
                                  minimumSize: MaterialStateProperty.all<Size>(
                                      Size(150, 45)),
                                  foregroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.white),
                                  backgroundColor:
                                      MaterialStateProperty.all<Color>(
                                          Colors.blue),
                                  shape: MaterialStateProperty.all<
                                          RoundedRectangleBorder>(
                                      RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(18.0),
                                          side:
                                              BorderSide(color: Colors.blue)))),
                              onPressed: () {
                                // check if any of text boxes are empty based on the type of resource
                                if (resourceName == "" ||
                                    resourceDescription == "" ||
                                    resourceLocation == "" ||
                                    (isInPersonSelected &&
                                        (resourceAddress == "" ||
                                            resourceCity == "" ||
                                            resourceState == "" ||
                                            resourceZip == "")) ||
                                    ((isInPersonSelected ||
                                            isHotlineSelected) &&
                                        resourcePhoneNumber == "") ||
                                    (isEventSelected &&
                                        (resourceSchedule == null))) {
                                  showAlertDialog(
                                    context,
                                    "One or more of the mandatory fields are blank. Please fill out all of the fields before submitting.",
                                  );
                                }
                                // check if any of the type, privacy, or cost options are not selected
                                else if (resourceType == "" ||
                                    selectedPrivacyOptions.isEmpty ||
                                    resourceCost == "") {
                                  showAlertDialog(
                                    context,
                                    "Please select a resource type, privacy option, and cost before submitting.",
                                  );
                                }
                                // otherwise, all fields are filled out and submit the resource
                                else {
                                  submitResource(resourceName, resourceLocation,
                                      resourceDescription, context);
                                }
                              },
                              child: Text('Submit Resource'),
                            )),
                      )
                    ],
                  ))));
        },
      ),
    );
  }
}
