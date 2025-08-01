/*
This page allows users to submit a resource for review by
entering resource information such as:
name, description, link, address (if in person),
phone number (if hotline or in person), type, privacy,
cost, cultural responsiveness, and age range.
*/

// TODO: fix tagging system 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:web_app/events/schedule.dart';
import 'package:web_app/events/schedule_form.dart';
import 'package:web_app/file_attachments.dart';
import 'package:web_app/util.dart';
import 'package:web_app/Analytics.dart';
import 'package:web_app/model.dart';


// Create resource page
class CreateResource extends StatefulWidget {
  @override
  State<CreateResource> createState() => _CreateResourceState();
}
// Custom radio list widget to display a list of radio buttons with labels
// This widget allows single selection from a list of options.
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

class CustomTextFieldContainer extends StatelessWidget {
  final String label;
  final bool isVisible;
  final TextEditingController? controller;

  const CustomTextFieldContainer({
    Key? key,
    required this.label,
    required this.isVisible,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!isVisible){
      return SizedBox.shrink();
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: isVisible ? 8.0 : 0.0),
      child: TextField(
        controller: controller,
        obscureText: false,
        decoration: InputDecoration(
          border: OutlineInputBorder(),
          labelText: label,
        ),
      ),
    );
  }
}

// Custom checkbox list widget to display a list of checkboxes with labels
// This widget allows multiple selections from a list of options.
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

  String _ageRange = "";
  Schedule? resourceSchedule = null;
  List<FileUpload> _attachments = [];

  // Stores the selected cultural responsiveness value
  String? culturalResponsiveness = Resource.culturalResponsivenessLabels.keys.first;

  // Resource type selected by user, initialized to the first type in the map.
  String resourceType = Resource.resourceTypeLabels.keys.first;

  // Used to store selected privacy options
  final Set<String> _selectedPrivacy = {};

  // used to store selected health focus options
  final Set<String> _selectedHealthFocus = {};

  // used to store selected resource cost options
  final Set<String> _selectedCostOptions = {};


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
  List<String> selectedTags = [];

  bool bypassVerification = false;

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

      

      // Get a newly generated ID for this resource.
      final resourceRef = resourceCollection.doc();

      // Upload attachments
      List<Attachment> attachments = _attachments.isEmpty
          ? []
          : await uploadAttachments(
              resourceRef.id, // use resource document ID as the file path
              _attachments,
              onProgress: (ratio) {
                setState(() {
                  _uploadProgress = ratio;
                });
              },
            );

      // Create the resource document JSON.
      final now = DateTime.now();

      // Create a new Resource object with updated properties
      final updatedResource = Resource(
        address: _addressController.text,
        agerange: _ageRange,
        attachments: attachments,
        building: _bldgController.text,
        city: _cityController.text,
        cost: _selectedCostOptions.toList(),
        createdBy: user.email,
        createdTime: now,
        culturalResponsiveness: culturalResponsiveness,
        dateAdded: "${now.month}/${now.day}/${now.year}",
        description: _descriptionController.text,
        healthFocus: _selectedHealthFocus.toList(),
        isVisable: true,
        location: _locationController.text,
        name: _nameController.text,
        phoneNumber: _phoneController.text,
        privacy: _selectedPrivacy.toList(),
        resourceType: resourceType,
        state: _stateController.text,
        schedule: resourceSchedule,
        tagline: selectedTags,
        verified: bypassVerification,
        zipcode: _zipController.text,
      );

      // Form validation:
      final errors = updatedResource.validateResource();
      if (errors.isNotEmpty) {
        await showMessageDialog(
          context,
          title: "Alert",
          message: "-${errors.join('\n-')}",
        );
        return;
      }
      // Submit to admin submission if object not null
      userSubmission?.submittedResource(updatedResource.name!, updatedResource.resourceType!);

      // Set the data of the document.
      await resourceRef.set(updatedResource.toJson());

      setState(() {
        // Just to make sure the progress bar shows full,
        // regardless of whether or not there were any attachments.
        _uploadProgress = 1.0;
      });

      debugPrint("Created resource ${resourceRef.id}");

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
    // Create a temporary resource object to determine visible fields
    final tempResource = Resource(resourceType: resourceType ?? '', /* other fields can be null */);
    final visibleFields = tempResource.visibleFields();
    
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
                CustomRadioList(
                  key: Key('resourceTypeRadioList'),
                  options: Resource.resourceTypeLabels,
                  selectedValue: resourceType,
                  onChanged: (value) => setState(() {
                    resourceType = value!;
                  }),
                  labelStyle: TextStyle(fontSize: 16),
                ),
                CustomTextFieldContainer(
                  key: Key('nameTextField'),
                  label: 'Name of the Resource',
                  isVisible: true, // Name entry is always visible
                  controller: _nameController,
                ),
                CustomTextFieldContainer(
                  key: Key('locationTextField'),
                  label: 'Link to the Resource',
                  isVisible: visibleFields.contains('location'),
                  controller: _locationController,
                ),
                CustomTextFieldContainer(
                  key: Key('addressTextField'),
                  label: 'Address',
                  isVisible: visibleFields.contains('address'),
                  controller: _addressController,
                ),
                CustomTextFieldContainer(
                  key: Key('buildingTextField'),
                  label: 'Apartment, building, floor, etc.',
                  isVisible: visibleFields.contains('building'),
                  controller: _bldgController,
                ),
                CustomTextFieldContainer(
                  key: Key('cityTextField'),
                  label: 'City',
                  isVisible: visibleFields.contains('city'),
                  controller: _cityController,
                ),
                CustomTextFieldContainer(
                  key: Key('stateTextField'),
                  label: 'State',
                  isVisible: visibleFields.contains('state'),
                  controller: _stateController,
                ),
                CustomTextFieldContainer(
                  key: Key('zipTextField'),
                  label: 'Zip Code',
                  isVisible: visibleFields.contains('zipcode'),
                  controller: _zipController,
                ),
                CustomTextFieldContainer(
                  key: Key('phoneTextField'),
                  label: 'Phone Number',
                  isVisible: visibleFields.contains('phoneNumber'),
                  controller: _phoneController,
                ),
                CustomTextFieldContainer(
                  key: Key('descriptionTextField'),
                  label: 'Description of the Resource',
                  isVisible: visibleFields.contains('description'),
                  controller: _descriptionController,
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: TextField(
                    key: Key('tagsTextField'),
                    obscureText: false,
                    controller: _tagsController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Please provide tags for the resource',
                    ),
                    onSubmitted: (text) {
                      if (text != "") {
                        setState(() {
                          selectedTags.add(text);
                          _tagsController.clear();
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
                  visible: visibleFields.contains('schedule'),
                  child: Column(children: [
                    buildTitles("Event Schedule"),
                    ScheduleFormFields(
                      key: Key('scheduleFormFields'),
                      onChanged: (schedule) {
                        setState(() {
                          resourceSchedule = schedule;
                        });
                      },
                    ),
                  ]),
                ),

                buildTitles("Privacy Protections"),
                CustomCheckboxList(
                  key: Key('privacyCheckboxList'),
                  options: Resource.privacyLabels,
                  selectedOptions: _selectedPrivacy,
                  onChanged: (key) => setState(() {
                    if ( _selectedPrivacy.contains(key) ){
                      _selectedPrivacy.remove(key);
                    } else {
                      _selectedPrivacy.add(key);
                    }
                  }),
                  labelStyle: TextStyle(fontSize: 16),
                ),
                buildTitles("Resource Cost"),
                CustomCheckboxList(
                  key: Key('costCheckboxList'),
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
                CustomCheckboxList(
                  key: Key('healthFocusCheckboxList'),
                  options: Resource.healthFocusLabels,
                  selectedOptions: _selectedHealthFocus,
                  onChanged: (key) => setState((){
                    if ( _selectedHealthFocus.contains(key) ) {
                      _selectedHealthFocus.remove(key);
                    } else {
                      _selectedHealthFocus.add(key);
                    }
                  }),
                  labelStyle: TextStyle(fontSize: 16),
                ),

                buildTitles("Cultural Responsiveness"),
                CustomRadioList(
                  key: Key('culturalResponsivenessRadioList'),
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
                      key: Key('ageRangeDropdown'),
                      value: _ageRange,
                      onChanged: (String? newValue) {
                        setState(() {
                          _ageRange = newValue!;
                        });
                      },
                      items: [
                        // Add an empty item for the default selection
                        DropdownMenuItem<String>(
                          value: "",
                          child: Text("Select Age Range"),
                        ),
                        // Generate dropdown items from the age labels
                        ...Resource.ageLabels.entries.map((entry) => 
                          DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value)),
                        ),
                      ]
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
                    key: Key('autoVerificationCheckbox'),
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
                      key: Key('submitResourceButton'),
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
