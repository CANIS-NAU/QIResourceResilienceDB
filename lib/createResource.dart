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
import 'package:web_app/model.dart';

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
  'Covered by insurance',
  'Covered by insurance with copay',
  'Sliding scale (income-based)',
  'Pay what you can/donation-based',
  'Payment plans available',
  'Subscription',
  'One-time fee',
  'Free trial period'
];

const List<String> healthFocusOptions = [
  'Anxiety',
  'Depression',
  'Stress Management',
  'Substance Abuse',
  'Grief and Loss',
  'Trama and PTSD',
  'Suicide Prevention',
];

// Create resource page
class CreateResource extends StatefulWidget {
  @override
  State<CreateResource> createState() => _CreateResourceState();
}

class CustomRadioList<T> extends StatelessWidget {
  final Map<T, String> options;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final TextStyle? labelStyle;
  final FocusNode? focusNode;

  const CustomRadioList(
      {super.key,
      required this.options,
      required this.selectedValue,
      required this.onChanged,
      this.labelStyle,
      this.focusNode});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.entries.map((entry) {
        final value = entry.key;
        final label = entry.value;

        return RadioListTile<T>(
            title: Text(label, style: labelStyle),
            value: value,
            groupValue: selectedValue,
            onChanged: onChanged,
            focusNode: focusNode ?? FocusNode(skipTraversal: true),
            controlAffinity: ListTileControlAffinity.leading,
            dense: true);
      }).toList(),
    );
  }
}
class CustomCheckboxList extends StatelessWidget {
  final Map<String, String> options;
  final Set<String> selectedOptions;
  final ValueChanged<String> onChanged; 
  final TextStyle? labelStyle;
  final FocusNode? focusNode;

  const CustomCheckboxList(
    {
      super.key,
      required this.options,
      required this.selectedOptions,
      required this.onChanged,
      this.labelStyle,
      this.focusNode
    }
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.entries.map( (entry) {
        final key = entry.key;
        final label = entry.value;

        return CheckboxListTile(
          title: Text(
            label, 
            style: labelStyle,
          ),
          value: selectedOptions.contains(key),
          onChanged: (bool? value) {
            if (value != null) onChanged(key);
          },
          controlAffinity: ListTileControlAffinity.leading,
          focusNode: focusNode ?? FocusNode(skipTraversal: true),
        );
      }).toList()
    );
  }
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
  String resourceType = "";
  String culturalResponsiveness = "";
  String _ageRange = ageItems.first;
  Schedule? resourceSchedule = null;
  List<FileUpload> _attachments = [];

  // Controllers for all text inputs.
  final _nameController = TextEditingController();
  final _locationController = TextEditingController();
  final _addressController = TextEditingController();
  final _bldgController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  final _phoneController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  // Tags created stored in tag array
  List<dynamic> selectedTags = [];

  bool bypassVerification = false;

  // Used to store selected privacy options
  final List<bool> _selectedPrivacy =
      List<bool>.filled(resourcePrivacy.length, false);
  List<String> selectedPrivacyOptions = [];

  // used to store health focus options
  final List<bool> _selectedHealthFocus =
      List<bool>.filled(healthFocusOptions.length, false);
  List<String> selectedHealthFocusOptions = [];

  // used to store selected resource cost options
  final Set<String> _selectedCostOptions = {};

    
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
          _selectedCostOptions.isEmpty ) {
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
        'verified': bypassVerification,
        'resourceType': resourceType,
        'privacy': selectedPrivacyOptions,
        'culturalResponsiveness': culturalResponsiveness,
        'cost': _selectedCostOptions.toList(),
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

      String successMessage = bypassVerification
          ? "Resource submitted and auto-verified."
          : "Submitted resource for review.";

      await showMessageDialog(
        context,
        title: "Success",
        message: successMessage,
      );

      _nameController.clear();
      _locationController.clear();
      _addressController.clear();
      _bldgController.clear();
      _cityController.clear();
      _stateController.clear();
      _zipController.clear();
      _phoneController.clear();
      _descriptionController.clear();
      _tagsController.clear();
      selectedTags.clear();

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
    String label, bool isVisible, Function(String) onChangedCallback, {TextEditingController? controller}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: isVisible ? 8.0 : 0.0),
      child: Visibility(
        visible: isVisible,
        child: TextField(
          controller: controller,
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
                  controller: _nameController,
                ),
                buildTextFieldContainer(
                  'Link to the Resource',
                  true,
                  (text) {
                    resourceLocation = text;
                  },
                  controller: _locationController,
                ),
                buildTextFieldContainer(
                  'Address',
                  isInPersonSelected,
                  (text) {
                    resourceAddress = text;
                  },
                  controller: _addressController,
                ),
                buildTextFieldContainer(
                  'Apartment, building, floor, etc.',
                  isInPersonSelected,
                  (text) {
                    resourceBldg = text;
                  },
                  controller: _bldgController,
                ),
                buildTextFieldContainer(
                  'City',
                  isInPersonSelected,
                  (text) {
                    resourceCity = text;
                  },
                  controller: _cityController,
                ),
                buildTextFieldContainer(
                  'State',
                  isInPersonSelected,
                  (text) {
                    resourceState = text;
                  },
                  controller: _stateController,
                ),
                buildTextFieldContainer(
                  'Zip Code',
                  isInPersonSelected,
                  (text) {
                    resourceZip = text;
                  },
                  controller: _zipController,
                ),
                buildTextFieldContainer(
                  'Phone Number',
                  isHotlineSelected || isInPersonSelected,
                  (text) {
                    resourcePhoneNumber = text;
                  },
                  controller: _phoneController,
                ),
                buildTextFieldContainer(
                  'Description of the Resource',
                  true,
                  (text) {
                    resourceDescription = text;
                  },
                  controller: _descriptionController,
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
                CustomCheckboxList(
                  options: Resource.costLabels,
                  selectedOptions: _selectedCostOptions,
                  onChanged: (key) => setState(() {
                    if ( _selectedCostOptions.contains(key) ) {
                      _selectedCostOptions.remove(key);
                    } else{
                      _selectedCostOptions.add(key);
                    }
                  }),
                  labelStyle: TextStyle(fontSize: 16),
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
                CustomRadioList(
                  options: Resource.culturalResponsivenessLabels,
                  selectedValue: culturalResponsiveness,
                  onChanged: (value) => setState(() {
                    culturalResponsiveness = value!;
                  }),
                  labelStyle: TextStyle(fontSize: 16),
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

                Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: CheckboxListTile(
                    title: Text(
                      "Bypass Verification (Auto-Verify)",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Select this option if your resource is trusted and should bypass manual verification process.",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                    value: bypassVerification,
                    onChanged: (bool? value) {
                      setState(() {
                        bypassVerification = value ?? false;
                      });
                    },
                    activeColor: Theme.of(context).primaryColor,
                    controlAffinity: ListTileControlAffinity.trailing,
                    contentPadding: EdgeInsets.all(8.0),
                    tileColor: Colors.grey[100],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    focusNode: FocusNode(skipTraversal: true),
                  ),
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
    _nameController.dispose();
    _locationController.dispose();
    _addressController.dispose();
    _bldgController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }
}
