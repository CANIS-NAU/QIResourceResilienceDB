/*
This page displays the resource information and rubric to the reviewer.
The rubric ratings, total score, and additional comments are saved and the reviewer can
choose to verify or deny a resource.
 */

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
//Package imports
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:web_app/events/schedule.dart';
import 'package:web_app/model.dart';
import 'package:web_app/time.dart';
import 'package:web_app/top10resources.dart';
import 'package:web_app/util.dart';
import 'package:web_app/Analytics.dart';
import 'package:web_app/createResource.dart';
import 'package:web_app/model.dart';
import 'package:web_app/view_resource/resource_detail.dart';

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
  Future<void> verifyResource(resource) async {
    try {
      await resourceCollection.doc(resource.id).update({"verified": true});
      await showMessageDialog(
        context,
        title:'Success',
        message: "Resource has been verified."
      );
    } catch (e) {
      await showMessageDialog(
        context,
        title: 'Error',
        message: "Failed to verify resource: $e",
      );
    }
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

  // function to add rubric info to a resource
  Future<void> updateResourceRubric(resource, userComments) {
    // define rubric and all sub-fields (score, ratings, comments)
    final Rubric rubric = 
      Rubric(
        appropriate: appropriate,
        avoidAgeism: avoidAgeism,
        avoidAppropriation: avoidAppropriation,
        avoidCondescension: avoidCondescension,
        avoidRacism: avoidRacism,
        avoidSexism: avoidSexism,
        avoidStereotyping: avoidStereotyping,
        avoidVulgarity: avoidVulgarity,

        accessibilityFeatures: _selectedAccessibilityFeatures.toList(),
        additionalComments: userComments,
        ageBalance: _selectedAge.toList(),
        genderBalance: _selectedGender.toList(),
        lifeExperiences: _selectedLifeExperiences.toList(),
        queerSexualitySpecific: queerSexualitySpecific,

        contentAccurate: contentAccurate,
        contentCurrent: contentCurrent,
        contentTrustworthy: contentTrustworthy,
        culturallyGroundedHopi: culturalRatingHopi,
        culturallyGroundedIndigenous: culturalRatingIndigenous,
      ); 
    
    // Add admin review of a resource
    if(userReview != null) {
      userReview?.submittedResource(rubric.toJson());
    }

  //update the resource with rubric information
    return resourceCollection.doc(resource.id).update({'rubric': rubric}).then(
            (value) => print("Resource successfully updated"))
        .catchError( (error) => print("Error updating document $error"));
  }

  Future<void> submitToInbox( Resource resource, 
                                                String status, String comments )
  {
    
    String description = "" +
      "Indigenous Cultural Rating: ${ culturalRatingIndigenous } / 5, "
      "Hopi Cultural Rating: ${ culturalRatingHopi } / 5, " +
      "Behavioral Health Accuracy Rating: ${ contentAccurate } / 5, " +
      "Behavioral Health Trustworthy Rating: ${ contentTrustworthy } / 5, " +
      "Behavioral Health Current Rating: ${ contentCurrent } / 5, ";


    User? currentUser = FirebaseAuth.instance.currentUser;
    String? reviewer = (currentUser != null) ? currentUser.email : "";

    final inboxInstance = {
      'reviewedby': reviewer,
      'email': resource.createdBy,
      'status': status,
      'description': description,
      'submittedName': resource.name,
      'comments': comments,
      'timestamp': DateTime.now()
    };

    return inboxRef.add( inboxInstance ).then( ( value ) => 
      print("Inbox instance added.") ).catchError( ( error ) => 
      print("Error creating document $error")
    );
  }

  // initialize all ratings to default values
  bool? appropriate = null;
  bool? avoidAgeism = null;
  bool? avoidAppropriation = null;
  bool? avoidCondescension = null;
  bool? avoidRacism = null;
  bool? avoidSexism = null;
  bool? avoidStereotyping = null;
  bool? avoidVulgarity = null;

  List<String>? selectedAccessibilityFeatures = [];
  String? userComments = null;
  List<String>? selectedAgeRanges = [];
  List<String>? selectedGenderOptions = [];
  List<String>? selectedLifeExperiences = [];
  bool? queerSexualitySpecific = null;

  int? contentAccurate = 0;
  int? contentCurrent = 0;
  int? contentTrustworthy = 0;
  int? culturalRatingHopi = 0;
  int? culturalRatingIndigenous = 0;


  Set<String> _selectedGender = {};

  Set<String> _selectedAge= {};

  Set<String> _selectedLifeExperiences = {};

  Set<String> _selectedAccessibilityFeatures = {};

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

  // builds the radio button ratings for the preliminary questions
  Widget buildYesNoRating(rating, Function(bool) updateRating, screenSize) {

    double ratingItemWidth;

    if (screenSize.width > 850) {
      ratingItemWidth = screenSize.width / 10;
    } else if (screenSize.width > 600) {
      ratingItemWidth = screenSize.width / 8;
    } else {
      ratingItemWidth = screenSize.width / 6;
    }

    // list of option strings
    const List<String> ButtonOptions = [
      'Yes',
      'No',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(2, (index) {
        final label = ButtonOptions[index];
        final value = (label == 'Yes');
        return SizedBox(
          width: ratingItemWidth,
          child: Container(
            child: RadioListTile(
              dense: true,
              title: Row(
                  children: [
                    Expanded(
                      child: Text("$label"))]),
              value: value,
              groupValue: rating,
              onChanged: (newValue) {
                updateRating(newValue as bool);
              },
              focusNode: FocusNode(skipTraversal: true),
            ),
          ),
        );
      }),
    );
  }

    // builds the radio button ratings for the preliminary questions
  Widget buildPreliminaryRating(rating, Function(bool) updateRating, screenSize) {

    double ratingItemWidth;

    if (screenSize.width > 850) {
      ratingItemWidth = screenSize.width / 10;
    } else if (screenSize.width > 600) {
      ratingItemWidth = screenSize.width / 8;
    } else {
      ratingItemWidth = screenSize.width / 6;
    }

    // list of option strings
    const List<String> ButtonOptions = [
      'Yes',
      'No',
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(2, (index) {
        final label = ButtonOptions[index];
        final value = (label == 'Yes');
        return SizedBox(
          width: ratingItemWidth,
          child: Container(
            child: RadioListTile(
              dense: true,
              title: Row(
                  children: [
                    Expanded(
                      child: Text("$label"))]),
              value: value,
              groupValue: rating,
              onChanged: (newValue) {
                updateRating(newValue as bool);
                if(newValue == false)
                {
                  Future(() async {
                    await deleteResource(widget.resourceData);
                    await submitToInbox(widget.resourceData, "Denied", "Resource denied by reviewer.");
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  });
                    //submitToInbox( widget.resourceData, "Denied", userComments);
                }
              },
              focusNode: FocusNode(skipTraversal: true),
            ),
          ),
        );
      }),
    );
  }

  // builds the radio button ratings
  Widget buildRating(rating, Function(int) updateRating, screenSize) {

    double ratingItemWidth;

    if (screenSize.width > 850) {
      ratingItemWidth = screenSize.width / 10;
    } else if (screenSize.width > 600) {
      ratingItemWidth = screenSize.width / 8;
    } else {
      ratingItemWidth = screenSize.width / 6;
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(5, (index) {
        final value = index + 1;
        return SizedBox(
          width: ratingItemWidth,
          child: Container(
            child: RadioListTile(
              dense: true,
              title: Row(
                  children: [
                    Expanded(
                      child: Text("$value"))]),
              value: value,
              groupValue: rating,
              onChanged: (newValue) {
                updateRating(newValue as int);
              },
              focusNode: FocusNode(skipTraversal: true),
            ),
          ),
        );
      }),
    );
  }

  // creates an active phone number link
  Widget buildPhoneLink(phoneUrl, phoneNumStr, resourceType) {
    // check if resource has a phone number
    if(resourceType == "Hotline" || resourceType == "In Person") {
      return Column(children: [
        GestureDetector(
            onTap: () async {
              if (await canLaunchUrlString(phoneUrl)) {
                await launchUrlString(phoneUrl);
              } else {
                showDialog(
                    context: context,
                    builder: (context) =>
                        AlertDialog(
                            title: Text("Error"),
                            content: Text("Failed to call phone number"),
                            actions: [
                              TextButton(
                                child: Text("OK"),
                                onPressed: () => Navigator.pop(context),
                              )
                            ]));
              }
            },
            // display phone number link
            child: RichText(
                text: TextSpan(
                    text: 'Phone Number: ',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                          text: '$phoneNumStr\n',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ))
                    ]))),
      ]);
    }
    else{
      // returns an empty widget if resource is not in person or hotline
      // (doesn't have a phone number)
      return SizedBox.shrink();
    }
    }

    // creates an active address link
    Widget buildAddressLink(addressUrl, fullAddress, resourceType) {
    if(resourceType == "In Person") {
      return Column(children: [
        GestureDetector(
            onTap: () async {
              String formattedAddress = fullAddress.replaceAll(" ", "+");
              String mapUrl = 'https://maps.google.com/?q=$formattedAddress';
              if (await canLaunchUrlString(mapUrl)) {
                await launchUrlString(mapUrl);
              } else {
                showDialog(
                    context: context,
                    builder: (context) =>
                        AlertDialog(
                            title: Text("Error"),
                            content: Text("Failed to launch address"),
                            actions: [
                              TextButton(
                                child: Text("OK"),
                                onPressed: () => Navigator.pop(context),
                              )
                            ]));
              }
            },
            // display address link
            child: RichText(
                text: TextSpan(
                    text: 'Address: ',
                    style: TextStyle(color: Colors.black, fontSize: 14),
                    children: [
                      TextSpan(
                          text: '$fullAddress\n',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                            decoration: TextDecoration.underline,
                          ))
                    ]))),
      ]);
    }
    else{
      // returns an empty widget if resource is not in person
      // (doesn't have an address)
      return SizedBox.shrink();
    }
    }

    // creates an active url link
    Widget buildUrlLink(url, urlStr){
    return Column(
      children: [
        GestureDetector(
            onTap: () async {
              if (await canLaunchUrl(url)) {
                await launchUrl(url);
              } else {
                showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                        title: Text("Error"),
                        content: Text(
                            "Failed to launch URL"),
                        actions: [
                          TextButton(
                            child: Text("OK"),
                            onPressed: () =>
                                Navigator.pop(context),
                          )
                        ]));
              }
            },
            child: RichText(
                text: TextSpan(
                    text: "URL: Link to website ",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 14,
                    ),
                    children: [
                      TextSpan(
                          text: 'here',
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 14,
                            decoration:
                            TextDecoration.underline,
                          ))
                    ])))
      ]
    );
    }

  @override
  Widget build(BuildContext context) {
    // get the screen size
    final Size screenSize = MediaQuery.of(context).size;

    String userComments = "";

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
        child: Container(
          padding: EdgeInsets.symmetric(horizontal:16.0),
          child: ListView(
            padding: EdgeInsets.only(right:16.0, top: 16.0),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  SizedBox(
                    child: buildPreliminaryRating(avoidRacism, (newValue) {
                    setState(() {
                      avoidRacism = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Avoids Sexism and Gender Stereotyping",
                    "Content does not exhibit sexist verbiage or values.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildPreliminaryRating(avoidSexism, (newValue) {
                    setState(() {
                      avoidSexism = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Avoids Pan-Indian Stereotypes",
                    "Content does not exhibit sexist verbiage or values.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildPreliminaryRating(avoidStereotyping, (newValue) {
                    setState(() {
                      avoidStereotyping = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Avoids Cultural Appropriation",
                    "Content does not appropriate or misuse any aspect of any culture.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildPreliminaryRating(avoidAppropriation, (newValue) {
                    setState(() {
                      avoidAppropriation = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Avoids Ageism",
                    "Content does not exhibit stereotypes based on age.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildPreliminaryRating(avoidAgeism, (newValue) {
                    setState(() {
                      avoidAgeism = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Avoids Being Condescending",
                    "Content does not 'talk down.'",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildPreliminaryRating(avoidCondescension, (newValue) {
                    setState(() {
                      avoidCondescension = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Avoids Innapropriate Language and Content",
                    "Content avoids profanity, vulgar language, inappropriate references to sexuality or violence, or substance abuse.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildPreliminaryRating(avoidVulgarity, (newValue) {
                    setState(() {
                      avoidVulgarity = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Content Suggests Available and Appropriate Services",
                    "Content does not recommend services that are unavailable or that are inconsistent with HBHSs approach to alcoholism treatment and/or behavioral healthcare.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildPreliminaryRating(appropriate, (newValue) {
                    setState(() {
                      appropriate = newValue;
                    });
                    }, screenSize),
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
                    "Culturally grounded",
                    "Content is specific to Indigenous individuals.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildRating(culturalRatingIndigenous, (newValue) {
                    setState(() {
                      culturalRatingIndigenous = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Culturally grounded",
                    "Content is specific to Hopi.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildRating(culturalRatingHopi, (newValue) {
                    setState(() {
                      culturalRatingHopi = newValue;
                    });
                    }, screenSize),
                  ),
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
                  }),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Is this content specific to LGBTQIA+/Two Spirit identities?",
                    "Please check yes or no.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildYesNoRating(queerSexualitySpecific, (newValue) {
                    setState(() {
                      queerSexualitySpecific = newValue;
                    });
                    }, screenSize),
                  ),
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
                  SizedBox(
                    child: buildRating(contentAccurate, (newValue) {
                    setState(() {
                      contentAccurate = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Content is from a reliable and trustworthy source, has credentials if applicable",
                    "1 means 'strongly disagree' and 5 means 'strongly agree.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildRating(contentTrustworthy, (newValue) {
                    setState(() {
                      contentTrustworthy = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  buildStandardTitle(
                    "Content is consistent with the current state of knowledge and practice and is not outdated",
                    "1 means 'strongly disagree' and 5 means 'strongly agree.",
                  ),
                  SizedBox(height: 10.0),
                  SizedBox(
                    child: buildRating(contentCurrent, (newValue) {
                    setState(() {
                      contentCurrent = newValue;
                    });
                    }, screenSize),
                  ),
                  SizedBox(height: 15),
                  SizedBox(height: 10),
                  Text(
                    "Total Score: ${contentAccurate! 
                                    + contentTrustworthy!
                                    + contentCurrent!
                                    + culturalRatingHopi!
                                    + culturalRatingIndigenous!} / 25"),
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
                    onChanged: (value) {
                    userComments = value;
                    },
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
                          await verifyResource(widget.resourceData);
                          await updateResourceRubric(widget.resourceData, userComments);
                          await submitToInbox( widget.resourceData, "Approved",
                                                                       userComments );
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
                          await deleteResource(widget.resourceData);
                          await submitToInbox(widget.resourceData, "Denied", userComments);
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
            ]
          ),
        ),
      ),
      bottomNavigationBar: 
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
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
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold)
            ),
          ),
        ),
      ),
    );
  }
}
