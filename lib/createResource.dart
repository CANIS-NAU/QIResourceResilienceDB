/*
This page allows users to submit a resource for review by
entering resource information such as:
name, description, link, address (if in person),
phone number (if hotline or in person), type, privacy,
cost, cultural responsiveness, and age range.
*/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:web_app/events/schedule.dart';
import 'package:web_app/events/schedule_form.dart';
import 'package:web_app/file_attachments.dart';
import 'package:web_app/util.dart';
import 'package:web_app/Analytics.dart';

//List of ages for dropdown
const List<String> ageItems = [
    'Under 18',
    '18-24',
    '24-65',
    '65+',
    'All ages'
];

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
const List<String> resourcePrivacy = [
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

const List<String>healthFocusOptions = [
  'Anxiety',
  'Depression',
  'Stress Management',
  'Substance Abuse',
  'Grief and Loss',
  'Trama and PTSD',
  'Suicide Prevention',
];

String culturalResponseScoreToText(double sliderValue) {
  if (sliderValue <= 1) {
    return "Low Cultural Responsivness";
  } else if (sliderValue <= 3) {
    return "Medium Cultural Responsivness";
  } else {
    return "High Cultural Responsivness";
  }
}

// Create resource page
class CreateResource extends StatefulWidget {
  @override
  State<CreateResource> createState() => _CreateResourceState();
}

class _CreateResourceState extends State<CreateResource> {
  CollectionReference resourceCollection =
      FirebaseFirestore.instance.collection('resources');

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
  String resourceCost = "";
  String resourceType = "";
  double _culturalResponseSliderValue = 0;
  String _ageRange = ageItems.first;
  Schedule? resourceSchedule = null;
  List<FileUpload> _attachments = [];

  // Tags created stored in tag array
  List<dynamic> selectedTags = [];

  // For tags text input.
  final _tagsController = TextEditingController();

  // Used to store selected privacy options
  final List<bool> _selectedPrivacy =
      List<bool>.filled(resourcePrivacy.length, false);
  List<String> selectedPrivacyOptions = [];

  // used to store health focus options
  final List<bool> _selectedHealthFocus =
      List<bool>.filled(healthFocusOptions.length, false);
  List<String> selectedHealthFocusOptions = [];

  // boolean to track hotline and in person selection
  bool isHotlineSelected = false;
  bool isInPersonSelected = false;
  bool isEventSelected = false;

  // Form submission status/progress.
  var _isSubmitted = false;
  var _uploadProgress = 0.0;

  // Get the current user
  static User? currentUser = FirebaseAuth.instance.currentUser;   
  // If the current user is not null then initalize the class
  UserResourceSubmission? userSubmission = currentUser != null ? 
                                    UserResourceSubmission(currentUser) : null;

  // Submit to DB
  void trySubmitResource() async {
    try {
      setState(() {
        _isSubmitted = true;
        _uploadProgress = 0.0;
      });

      // Form authorization:
      // User must be logged in (preferably they wouldn't even get to this page...)
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        await showMessageDialog(
          context,
          title: "Error",
          message: "You need to log in to submit a resource.",
        );
        return;
      }

      // Form validation:
      // Check if any of text boxes are empty based on the type of resource
      if (resourceName == "" ||
          resourceDescription == "" ||
          resourceLocation == "" ||
          (isInPersonSelected &&
              (resourceAddress == "" ||
                  resourceCity == "" ||
                  resourceState == "" ||
                  resourceZip == "")) ||
          ((isInPersonSelected || isHotlineSelected) &&
              resourcePhoneNumber == "") ||
          (isEventSelected && (resourceSchedule == null))) {
        await showMessageDialog(
          context,
          title: "Alert",
          message:
              "One or more of the mandatory fields are blank. Please fill out all of the fields before submitting.",
        );
        return;
      }

      // Check if any of the type, privacy, or cost options are not selected.
      if (resourceType == "" ||
          selectedPrivacyOptions.isEmpty ||
          selectedHealthFocusOptions.isEmpty ||
          resourceCost == "") {
        await showMessageDialog(
          context,
          title: "Alert",
          message:
              "Please select a resource type, privacy option, and cost before submitting.",
        );
        return;
      }

      // Otherwise, all fields are filled out correctly: continue.
      // Get a newly generated ID for this resource.
      final resourceRef = resourceCollection.doc();
      final resourceId = resourceRef.id;

      // Upload attachments
      List<Attachment> attachments = _attachments.isEmpty
          ? []
          : await uploadAttachments(
              resourceId, // use resource document ID as the file path
              _attachments,
              onProgress: (ratio) {
                setState(() {
                  _uploadProgress = ratio;
                });
              },
            );

      // Create the resource document JSON.
      final now = DateTime.now();
      final date = "${now.month}/${now.day}/${now.year}";
      final resource = {
        'name': resourceName,
        'location': resourceLocation,
        'address': resourceAddress,
        'building': resourceBldg,
        'city': resourceCity,
        'state': resourceState,
        'zipcode': resourceZip,
        'phoneNumber': resourcePhoneNumber,
        'description': resourceDescription,
        'agerange': _ageRange,
        'isVisable': true,
        'verified': false, // Always false upon creation.
        'resourceType': resourceType,
        'privacy': selectedPrivacyOptions,
        'culturalResponse':
            culturalResponseScoreToText(_culturalResponseSliderValue),
        'culturalResponsivness': _culturalResponseSliderValue,
        'cost': resourceCost,
        'healthFocus': selectedHealthFocusOptions,
        'tagline': selectedTags,
        if (resourceSchedule != null) 'schedule': resourceSchedule!.toJson(),
        'attachments': attachments.map((x) => x.toJson()),
        'dateAdded': date,
        'createdBy': user.email,
        'createdTime': FieldValue.serverTimestamp(),
      };

      // Submit to admin submission if object not null
      userSubmission?.submittedResource(resourceName, resourceType);

      // Set the data of the document.
      await resourceRef.set(resource);

      setState(() {
        // Just to make sure the progress bar shows full,
        // regardless of whether or not there were any attachments.
        _uploadProgress = 1.0;
      });

      debugPrint("Created resource ${resourceId}");
      await showMessageDialog(
        context,
        title: "Success",
        message: "Submitted resource for review.",
      );

      // Return to origin page after successful document creation.
      // This avoid issues with stale form values from previous submissions.
      Navigator.pop(context);
    } on Exception catch (error) {
      debugPrint(error.toString());
      await showMessageDialog(
        context,
        title: "Error",
        message: "Unable to submit. Please try again.",
      );
    } finally {
      setState(() {
        _isSubmitted = false;
      });
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          splashRadius: 20.0,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Container(
          constraints: BoxConstraints(
            minWidth: 600,
            maxWidth: 600,
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Form(
            child: ListView(
              // Some padding to keep the scroll bar from overlapping form fields.
              padding: EdgeInsets.only(right: 16.0),
              children: [
                buildTitles("Resource Type"),
                ListView(
                  shrinkWrap: true,
                  children: resourceTypeOptions.map((option) {
                    return RadioListTile(
                      title: Text(
                        option,
                        style: TextStyle(fontSize: 16),
                      ),
                      value: option,
                      groupValue: resourceType,
                      onChanged: (value) => setState(() {
                        resourceType = value!;
                        isHotlineSelected = (value == "Hotline");
                        isInPersonSelected = (value == "In Person");
                        isEventSelected = (value == "Event");
                      }),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      // focus only on the radio buttons within the list tile, not the entire tile
                      focusNode: FocusNode(skipTraversal: true),
                    );
                  }).toList(),
                ),
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
                    controller: _tagsController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Please provide tags for the resource',
                    ),
                    onSubmitted: (text) {
                      if (text != "") {
                        setState(() {
                          _tagsController.clear();
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
                                label: Text(
                                  tag,
                                  style: TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                                deleteIconColor: Colors.white,
                                backgroundColor: Theme.of(context).primaryColor,
                                side: MaterialStateBorderSide.resolveWith((Set<MaterialState> states) {
                                  if (states.contains(MaterialState.focused)) {
                                    return BorderSide(
                                        color: Colors.grey[700]!, width: 2);
                                  }
                                  return BorderSide.none;
                                }),
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

                buildTitles("Privacy Protections"),
                ListView(
                  shrinkWrap: true,
                  children: List<Widget>.generate(
                    _selectedPrivacy.length,
                    (int index) => CheckboxListTile(
                      title: Text(
                        resourcePrivacy[index],
                        style: TextStyle(fontSize: 16),
                      ),
                      value: _selectedPrivacy[index],
                      onChanged: (value) => setState(() {
                        _selectedPrivacy[index] = value!;
                        if (value) {
                          selectedPrivacyOptions.add(resourcePrivacy[index]);
                        } else {
                          selectedPrivacyOptions.remove(resourcePrivacy[index]);
                        }
                      }),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      // focus only on the radio buttons within the list tile, not the entire tile
                      focusNode: FocusNode(skipTraversal: true),
                    ),
                  ),
                ),
                buildTitles("Resource Cost"),
                ListView(
                  shrinkWrap: true,
                  children: resourceCostOptions.map((option) {
                    return RadioListTile(
                      title: Text(
                        option,
                        style: TextStyle(fontSize: 16),
                      ),
                      value: option,
                      groupValue: resourceCost,
                      onChanged: (value) => setState(() {
                        resourceCost = value!;
                      }),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      // focus only on the radio buttons within the list tile, not the entire tile
                      focusNode: FocusNode(skipTraversal: true),
                    );
                  }).toList(),
                ),

                buildTitles("Health Focus"),
                ListView(
                  shrinkWrap: true,
                  children: List<Widget>.generate(
                    _selectedHealthFocus.length,
                    (int index) => CheckboxListTile(
                      title: Text(
                        healthFocusOptions[index],
                        style: TextStyle(fontSize: 16),
                      ),
                      value: _selectedHealthFocus[index],
                      onChanged: (value) => setState(() {
                        _selectedHealthFocus[index] = value!;
                        if (value) {
                          selectedHealthFocusOptions.add(healthFocusOptions[index]);
                        } else {
                          selectedHealthFocusOptions.remove(healthFocusOptions[index]);
                        }
                      }),
                      controlAffinity: ListTileControlAffinity.leading,
                      dense: true,
                      focusNode: FocusNode(skipTraversal: true),
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
                              activeTrackColor: Theme.of(context).primaryColor,
                              thumbColor: Theme.of(context).primaryColor,
                              overlayColor: Theme.of(context).primaryColor.withOpacity(0.2),
                              valueIndicatorColor:  Theme.of(context).primaryColor,
                              valueIndicatorTextStyle:
                                  TextStyle(color: Colors.white),
                            ),
                            child: Slider(
                              value: _culturalResponseSliderValue,
                              max: 5,
                              divisions: 5,
                              label: _culturalResponseSliderValue
                                  .round()
                                  .toString(),
                              onChanged: (double value) {
                                setState(() {
                                  _culturalResponseSliderValue = value;
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
                      value: _ageRange,
                      onChanged: (String? newValue) {
                        setState(() {
                          _ageRange = newValue!;
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

                // Attachments
                buildTitles("File Attachments"),
                AttachmentsManager(
                  onChanged: (files) {
                    _attachments = files;
                  },
                ),

                // Submit button and progress indicator (while submitting)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 48.0),
                  child: Column(children: [
                    ElevatedButton(
                      onPressed: _isSubmitted ? null : trySubmitResource,
                      child: Text('Submit Resource'),
                    ),
                    if (_isSubmitted)
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: LinearProgressIndicator(
                          value: _uploadProgress,
                        ),
                      ),
                  ]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _tagsController.dispose();
    super.dispose();
  }
}
