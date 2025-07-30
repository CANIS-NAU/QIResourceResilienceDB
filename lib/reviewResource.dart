/*
This page displays the resource information and rubric to the reviewer.
The rubric ratings, total score, and additional comments are saved and the reviewer can
choose to verify or deny a resource.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//Package imports
import 'package:flutter/material.dart';
import 'package:web_app/createResource.dart';
import 'package:web_app/model.dart';
import 'package:web_app/util.dart';
import 'package:web_app/Analytics.dart';
import 'package:web_app/view_resource/resource_detail.dart';

enum VerificationStatus {
  Approved,
  Denied,
}

// Widget that displays a row of radio buttons that are responsive to screen size
// If the screen is narrower than 600px, it displays the radio buttons in a column instead of a row
class ResponsiveRadioRow<T> extends StatelessWidget {
  final Map<T, String> options;
  final T? selectedValue;
  final ValueChanged<T?> onChanged;
  final TextStyle? labelStyle;
  final FocusNode? focusNode;

  const ResponsiveRadioRow({
    super.key,
    required this.options,
    required this.selectedValue,
    required this.onChanged,
    this.labelStyle,
    this.focusNode,
  });

    @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 600;

    final tiles = options.entries.map((entry) {
      return _buildTile(entry.key, entry.value);
    }).toList();

    return isWide
        ? Wrap(
            spacing: 12.0,
            runSpacing: 8.0,
            alignment: WrapAlignment.start,
            children: tiles,
          )
        : Column(children: tiles);
  }
  // builds tiles of radio row/column
  Widget _buildTile(T value, String label) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 100), // Optional
      child: RadioListTile<T>(
        title: Text(label, style: labelStyle),
        value: value,
        groupValue: selectedValue,
        onChanged: onChanged,
        focusNode: focusNode ?? FocusNode(skipTraversal: true),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
  }

class ReviewResource extends StatefulWidget {
  final Resource resourceData;

  ReviewResource({Key? key, required this.resourceData})
      : super(key: key);

  @override
  State<ReviewResource> createState() => _ReviewResourceState();
}


class _ReviewResourceState extends State<ReviewResource> {
  final CollectionReference resourceCollection = FirebaseFirestore.instance
      .collection('resources');


  final CollectionReference inboxRef = FirebaseFirestore.instance
      .collection('rrdbInbox');

  // Declare as static to pass to constructor
  static User? currentUser = FirebaseAuth.instance.currentUser;   
  // If the current user is not null then initalize the class
  UserReview? userReview = currentUser != null ? 
                                                UserReview(currentUser) : null;

  // function to verify a resource
  Future<void> verifyResource(Resource resource) async {
  try {
    await resourceCollection.doc(resource.id).update({"verified": true});

    if (!mounted) return;
    await showMessageDialog(
      context,
      title: 'Success',
      message: "Resource has been verified.",
    );
  } catch (e) {
    if (!mounted) return;
    await showMessageDialog(
      context,
      title: 'Error',
      message: "Failed to verify resource: $e",
    );
  }
}

  // builds a rubric from info given in form
  Rubric buildRubricFromForm(){
    return Rubric(
      // default preliminary ratings to false if not filled out
      appropriate: appropriate ?? false,
      avoidsAgeism: avoidsAgeism ?? false,
      avoidsAppropriation: avoidsAppropriation ?? false,
      avoidsCondescension: avoidsCondescension ?? false,
      avoidsRacism: avoidsRacism ?? false,
      avoidsSexism: avoidsSexism ?? false,
      avoidsStereotyping: avoidsStereotyping ?? false,
      avoidsVulgarity: avoidsVulgarity ?? false,
      accessibilityFeatures: _selectedAccessibilityFeatures.toList(),
      additionalComments: _userCommentController.text,
      ageBalance: _selectedAge.toList(),
      genderBalance: _selectedGender.toList(),
      lifeExperiences: _selectedLifeExperiences.toList(),
      queerSexualitySpecific: queerSexualitySpecific,
      contentAccuracy: contentAccuracy,
      contentCurrentness: contentCurrentness,
      contentTrustworthiness: contentTrustworthiness,
      culturalGroundednessHopi: culturalGroundednessHopi,
      culturalGroundednessIndigenous: culturalGroundednessIndigenous,
      reviewTime: DateTime.now(),
      reviewedBy: currentUser!.email,
    );
  }
  // take in the name of the standard and description and displays it
  Widget buildStandardTitle(title, description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          child: Text(
            "$title: ",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16.0,
              fontWeight: FontWeight.bold,
            ),
            softWrap: true,
            overflow: TextOverflow.clip,
          ),
        ),
        Flexible(
          fit: FlexFit.loose,
          child: Text(
            "$description",
            style: TextStyle(
              color: Colors.black,
              fontSize: 15.0,
            ),
            softWrap: true,
            overflow: TextOverflow.clip,
          ),
        )
      ],
    );
  }

  // function to deny/delete a resourcecontext
  Future<void> deleteResource(resource) async {
    try {
      await resourceCollection.doc(resource.id).delete();
      await showMessageDialog(
        context,
        title:'Success',
        message: "Resource has been denied."
      );
    } catch (e) {
      await showMessageDialog(
        context,
        title: 'Error',
        message: "Failed to delete resource: $e",
      );
    }
  }

  Future<void> handleRubricSubmission( Resource resource, VerificationStatus status ) async {

    resource.rubric = buildRubricFromForm();

    if (status == VerificationStatus.Approved) {
      // set resource as verified
      await verifyResource(resource);
      // Update DB
      await updateResourceRubric(resource, status);
      // Send to inbox
      await submitToInbox(resource, status);
    }
    else {
      await submitToInbox(resource, status);
      await deleteResource(resource);
    }
  }

  ValueChanged<bool?> preliminaryRatingHandler({
      required BuildContext context,
      required void Function(bool?) updateRating,
      }) {
        return (newValue) async {
          updateRating(newValue);

          if (newValue == false) {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text("Confirm Resource Rejection"),
                content: const Text(
                  "Answering 'No' to any preliminary questions will result in the automatic rejection of this resource. Are you sure?"
                ),
                actions: [
                  TextButton(
                    child: const Text("No, go back"),
                    style: TextButton.styleFrom(
                            foregroundColor: Color.fromARGB(255, 72, 72, 72),
                          ),
                    onPressed: () => Navigator.pop(context, false),
                  ),
                  OutlinedButton(
                    child: const Text("Yes, reject"),
                    style: OutlinedButton.styleFrom(
                            foregroundColor: Theme.of(context).primaryColorDark,
                          ),
                    onPressed: () => Navigator.pop(context, true),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await handleRubricSubmission(widget.resourceData, VerificationStatus.Denied);
              if (context.mounted) Navigator.pop(context);
            } else {
              updateRating(null);
            }
          }
  };
}


  // function to add rubric info to a resource
  Future<void> updateResourceRubric(resource, status) async {
    
    final rubric = resource.rubric!;
    final reviewedBy = rubric.reviewedBy;
    final reviewTime = rubric.reviewTime;

    // Add admin review of a resource
    if(userReview != null) {
      userReview?.submittedResource(rubric.toJson());
    }



  //update the resource with rubric information
    try {
      await resourceCollection.doc(resource.id).update({
      'rubric': rubric.toJson(),
      'reviewedBy': reviewedBy,
      'reviewTime': reviewTime,
      'isDeleted': status == VerificationStatus.Denied,
      });
      print("Resource successfully updated");
      // clear text controller
      _userCommentController.clear();
    } catch (error) {
      print("Error updating document $error");
    }
  }

  Future<void> submitToInbox( Resource resource, 
                                                VerificationStatus status )
  {

    final rubric = resource.rubric!;

    final inboxInstance = {
      'resourceID': resource.id, 
      'reviewedby': rubric.reviewedBy,
      'email': resource.createdBy,
      'status': status.name,
      'rubric': rubric.toJson(),
      'submittedName': resource.name,
      'comments': rubric.additionalComments,
      'timestamp': rubric.reviewTime,
    };

    return inboxRef.add( inboxInstance )
      .then( (value) { 
        print("Inbox instance added.");
      }).catchError( (error) { 
        print("Error creating document $error");
      });
  }

  // initialize all ratings to default values
  bool? appropriate = null;
  bool? avoidsAgeism = null;
  bool? avoidsAppropriation = null;
  bool? avoidsCondescension = null;
  bool? avoidsRacism = null;
  bool? avoidsSexism = null;
  bool? avoidsStereotyping = null;
  bool? avoidsVulgarity = null;

  List<String>? selectedAccessibilityFeatures = [];
  String? userComments = null;
  List<String>? selectedAgeRanges = [];
  List<String>? selectedGenderOptions = [];
  List<String>? selectedLifeExperiences = [];
  bool? queerSexualitySpecific = null;

  int? contentAccuracy = 0;
  int? contentCurrentness = 0;
  int? contentTrustworthiness = 0;
  int? culturalGroundednessHopi = 0;
  int? culturalGroundednessIndigenous = 0;

  final String? reviewedBy = currentUser?.email;
  final DateTime? reviewTime = DateTime.now();

  Set<String> _selectedGender = {};

  Set<String> _selectedAge= {};

  Set<String> _selectedLifeExperiences = {};

  Set<String> _selectedAccessibilityFeatures = {};

  final _userCommentController = TextEditingController();

  

  @override
  Widget build(BuildContext context) {
    // get the screen size
    final Size screenSize = MediaQuery.of(context).size;


    int totalScore = culturalGroundednessHopi! + culturalGroundednessIndigenous!
                      + contentAccuracy! + contentTrustworthiness! + contentCurrentness!;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Resource'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          splashRadius: 20.0,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 800),
          child: Stack(
            children: [
              Positioned.fill(
                child: ListView(
                  padding: EdgeInsets.all(16.0),
                  children: [
                          //ResourceDetail(resourceModel: widget.resourceData,),
                    //SizedBox(height: 20.0),
                    Text(
                      'Resource Information',
                      style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.width > 600 ? 22.0 : 18.0,
                      ),
                    ),
                    SizedBox(height: 10),
                    Divider(
                      color: Colors.grey,
                      thickness: 1.0,
                    ),
                    Text("Please select Yes or No for the following questions. If you answer No to any of the following questions, the resource will be automatically denied.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15.0),
                    // first standard: culturally grounded
                    buildStandardTitle(
                      "Avoids Racism",
                      "Content does not exhibit racist verbiage or values.",
                    ),
                    SizedBox(height: 10.0),
                    // create rating buttons and assign to correct rating
                    ResponsiveRadioRow(
                      options: { true: "Yes", false: "No" },
                      selectedValue: avoidsRacism, 
                      onChanged: preliminaryRatingHandler(
                        context: context,
                        updateRating: (val) => setState(() => avoidsRacism = val),
                      )
                    ),       
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Avoids Sexism and Gender Stereotyping",
                      "Content does not exhibit sexist verbiage or values.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(
                      options: { true: "Yes", false: "No" },
                      selectedValue: avoidsSexism, 
                      onChanged: preliminaryRatingHandler(
                        context: context,
                        updateRating: (val) => setState(() => avoidsSexism = val),
                      )
                    ),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Avoids Pan-Indian Stereotypes",
                      "Content does not exhibit sexist verbiage or values.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(
                      options: { true: "Yes", false: "No" },
                      selectedValue: avoidsStereotyping, 
                      onChanged: preliminaryRatingHandler(
                        context: context,
                        updateRating: (val) => setState(() => avoidsStereotyping = val),
                      )
                    ),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Avoids Cultural Appropriation",
                      "Content does not appropriate or misuse any aspect of any culture.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(
                      options: { true: "Yes", false: "No" },
                      selectedValue: avoidsAppropriation, 
                      onChanged: preliminaryRatingHandler(
                        context: context,
                        updateRating: (val) => setState(() => avoidsAppropriation = val),
                      )
                    ),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Avoids Ageism",
                      "Content does not exhibit stereotypes based on age.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(
                      options: { true: "Yes", false: "No" },
                      selectedValue: avoidsAgeism, 
                      onChanged: preliminaryRatingHandler(
                        context: context,
                        updateRating: (val) => setState(() => avoidsAgeism = val),
                      )
                    ),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Avoids Being Condescending",
                      "Content does not 'talk down.'",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(
                      options: { true: "Yes", false: "No" },
                      selectedValue: avoidsCondescension, 
                      onChanged: preliminaryRatingHandler(
                        context: context,
                        updateRating: (val) => setState(() => avoidsCondescension = val),
                      )
                    ),SizedBox(height: 15),
                    buildStandardTitle(
                      "Avoids Innapropriate Language and Content",
                      "Content avoids profanity, vulgar language, inappropriate references to sexuality or violence, or substance abuse.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(
                      options: { true: "Yes", false: "No" },
                      selectedValue: avoidsVulgarity, 
                      onChanged: preliminaryRatingHandler(
                        context: context,
                        updateRating: (val) => setState(() => avoidsVulgarity = val),
                      )
                    ),SizedBox(height: 15),
                    buildStandardTitle(
                      "Content Suggests Available and Appropriate Services",
                      "Content does not recommend services that are unavailable or that are inconsistent with HBHSs approach to alcoholism treatment and/or behavioral healthcare.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(
                      options: { true: "Yes", false: "No" },
                      selectedValue: appropriate, 
                      onChanged: preliminaryRatingHandler(
                        context: context,
                        updateRating: (val) => setState(() => appropriate = val),
                      )
                    ),SizedBox(height: 15),
                    Divider(
                      color: Colors.grey,
                      thickness: 1.0,
                    ),
                    Text("Please answer the following questions on the content of the resource.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15.0),
                    buildStandardTitle(
                      "Culturally grounded",
                      "Content is specific to Indigenous individuals.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(options: {
                      1: "1",
                      2: "2",
                      3: "3",
                      4: "4",
                      5: "5",
                    }, selectedValue: culturalGroundednessIndigenous, onChanged: (value) {
                      setState(() {
                        culturalGroundednessIndigenous = value!;
                      });
                    }),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Culturally grounded",
                      "Content is specific to Hopi.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(options: {
                      1: "1",
                      2: "2",
                      3: "3",
                      4: "4",
                      5: "5",
                    }, selectedValue: culturalGroundednessHopi, onChanged: (value) {
                      setState(() {
                        culturalGroundednessHopi = value!;
                      });
                    }),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Gender and Sexual Orientation",
                      "Is the content specific to any particular gender(s)? If so, please specify below.",
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      "Which gender(s)?",
                      style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    CustomCheckboxList(
                      options: Rubric.genderLabels,
                      selectedOptions: _selectedGender,
                      onChanged: (value) {
                        setState(() {
                          if (_selectedGender.contains(value)) {
                            _selectedGender.remove(value);
                          } else {
                            _selectedGender.add(value);
                          }
                        });
                      },
                    ),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Is this content specific to LGBTQIA+/Two Spirit identities?",
                      "Please check yes or no.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(options: {
                      true: "Yes",
                      false: "No",
                    }, selectedValue: queerSexualitySpecific, onChanged: (value) {
                      setState(() {
                        queerSexualitySpecific = value!;
                      });
                    }),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Age balance",
                      "Please select which age group(s) the content is targeted towards.",
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      "Ages:",
                      style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    CustomCheckboxList(
                      options: Resource.ageLabels,
                      selectedOptions: _selectedAge,
                      onChanged: (value) {
                        setState(() {
                          if (_selectedAge.contains(value)) {
                            _selectedAge.remove(value);
                          } else {
                            _selectedAge.add(value);
                          }
                        });
                      },
                    ),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Life Experiences",
                      "Please select which life experiences this content is relavent for.",
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      "Experiences:",
                      style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    CustomCheckboxList(
                      options: Rubric.lifeExperienceLabels,
                      selectedOptions: _selectedLifeExperiences,
                      onChanged: (value) {
                        setState(() {
                          if (_selectedLifeExperiences.contains(value)) {
                            _selectedLifeExperiences.remove(value);
                          } else {
                            _selectedLifeExperiences.add(value);
                          }
                        });
                      },
                    ),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Accessibility",
                      "Please select any accessibility features available for the resource.",
                    ),
                    SizedBox(height: 10.0),
                    Text(
                      "Features:",
                      style: TextStyle(
                      color: Colors.black,
                      fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    CustomCheckboxList(
                      options: Rubric.accessibilityLabels,
                      selectedOptions: _selectedAccessibilityFeatures,
                      onChanged: (value) {
                        setState(() {
                          if (_selectedAccessibilityFeatures.contains(value)) {
                            _selectedAccessibilityFeatures.remove(value);
                          } else {
                            _selectedAccessibilityFeatures.add(value);
                          }
                        });
                      },
                    ),
                    SizedBox(height: 15),
                    Divider(
                      color: Colors.grey,
                      thickness: 1.0,
                    ),
                    Text("Please answer the following questions on the content of the resource.",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 15.0),
                    buildStandardTitle(
                      "Content presents accurate, up-to-date infromation",
                      "1 means 'strongly disagree' and 5 means 'strongly agree.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(options: {
                      1: "1",
                      2: "2",
                      3: "3",
                      4: "4",
                      5: "5",
                    }, selectedValue: contentAccuracy, onChanged: (value) {
                      setState(() {
                        contentAccuracy = value!;
                      });
                    }),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Content is from a reliable and trustworthy source, has credentials if applicable",
                      "1 means 'strongly disagree' and 5 means 'strongly agree.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(options: {
                      1: "1",
                      2: "2",
                      3: "3",
                      4: "4",
                      5: "5",
                    }, selectedValue: contentTrustworthiness, onChanged: (value) {
                      setState(() {
                        contentTrustworthiness = value!;
                      });
                    }),
                    SizedBox(height: 15),
                    buildStandardTitle(
                      "Content is consistent with the current state of knowledge and practice and is not outdated",
                      "1 means 'strongly disagree' and 5 means 'strongly agree.",
                    ),
                    SizedBox(height: 10.0),
                    ResponsiveRadioRow(options: {
                      1: "1",
                      2: "2",
                      3: "3",
                      4: "4",
                      5: "5",
                    }, selectedValue: contentCurrentness, onChanged: (value) {
                      setState(() {
                        contentCurrentness = value!;
                      });
                    }),
                    SizedBox(height: 15),
                    SizedBox(height: 10),
                    Text("Total Score: ${totalScore} / 25"),
                    SizedBox(height: 20),
                    Text(
                      'Additional Comments',
                      style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.width > 600 ? 22.0 : 18.0,
                      ),
                    ),
                    SizedBox(height: 10),
                    TextField(
                      maxLines: 3,
                      decoration: InputDecoration(
                      hintText: 'Type your additional comments here',
                      border: InputBorder.none,
                      ),
                      controller: _userCommentController,
                    ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                      TextButton(
                        style: ButtonStyle(
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                          side: BorderSide(color: Theme.of(context).primaryColor),
                          ),
                        ),
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                        ),
                        onPressed: () async {
                          await handleRubricSubmission(widget.resourceData, VerificationStatus.Approved);
                          if (mounted) {
                            Navigator.pop(context);
                          }
                        },
                        child: Text(
                        'Verify',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                      ),
                      SizedBox(width: 10),
                      TextButton(
                        style: ButtonStyle(
                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                          RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                          side: BorderSide(color: Colors.grey.shade700),
                          ),
                        ),
                        foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                        ),
                        onPressed: () async {
                          await handleRubricSubmission(widget.resourceData, VerificationStatus.Denied);
                        if (mounted) {
                          Navigator.pop(context);
                        }
                        },
                        child: Text(
                        'Deny',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        ),
                      ),
                      ],
                    ),
                  ],
                ),
              ),
              Positioned(
                top: 16.0,
                right: 16.0,
                child: ElevatedButton (
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                  ),
                  onPressed: () async {
                    showDialog(
                      context: context,
                      builder: (dialogContext) {
                        return ResourceDetail(resourceModel: widget.resourceData);
                      },
                    );
                  },
                  child: Text(
                    'View Resource Details',
                    style: TextStyle(fontSize: 14.0, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        )
      )
    );
  }
}
