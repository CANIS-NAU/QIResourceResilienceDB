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
import 'package:web_app/time.dart';
import 'package:web_app/util.dart';

import 'UserAnalytics.dart';

class ReviewResource extends StatefulWidget {
  final QueryDocumentSnapshot resourceData;

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
  Future<void> verifyResource(name) {
    return resourceCollection.doc(name.id).update({"verified": true})
        .then((value) => showAlertDialog(context, "Resource has been verified."))
        .catchError((error) => showAlertDialog(context, "Failed to verify resource: $error"));
  }

  // function to deny/delete a resource
  Future<void> deleteResource(name) {
    return resourceCollection.doc(name.id).delete()
        .then((value) => showAlertDialog(context, "Resource has been denied."))
        .then((value) => Navigator.pushNamed( context, '/dashboard' ))
        .catchError((error) => showAlertDialog(context, "Failed to delete resource: $error"));
        //redirect to resource verification page      
  }

  // function to add rubric info to a resource
  Future<void> updateResourceRubric(resource, userComments, totalScore) {
    // define rubric and all sub-fields (score, ratings, comments)
    final rubric = {
      'avoidRacism': avoidRacism,
      'avoidStereotyping': avoidStereotyping,
      'avoidAppropriation': avoidAppropriation,
      'avoidSexism': avoidSexism,
      'avoidAgeism': avoidAgeism,
      'avoidCond' : avoidCond,
      'avoidLanguage' : avoidLanguage,
      'appropriate' : appropriate,
      'totalScore': totalScore,
      'additionalComments': userComments,
      'genderBalance': selectedGenderOptions,
      'ageBalance': selectedAgeRanges,
      'lifeExperiences': selectedLifeExperiences,
      'experienceBalance': experienceRating,
      'contentAccurate' : contentAccurate,
      'contentTrustworthy' : contentTrustworthy,
      'contentCurrent' : contentCurrent,
    };

    // Add admin review of a resource
    if(userReview != null) {
      userReview?.submittedResource(rubric);
    }

  //update the resource with rubric information
    return resourceCollection.doc(resource.id).update({'rubric': rubric}).then(
            (value) => print("Resource successfully updated"))
        .catchError( (error) => print("Error updating document $error"));
  }

  Future<void> submitToInbox( QueryDocumentSnapshot currentResource, 
                                                String status, String comments )
  {
    String email = "${currentResource['createdBy']}";
    String resourceName = "${currentResource['name']}";

    DateTime currentTime = DateTime.now();

    String timestamp = "${currentTime}";
    
    String description = "" +
      "Cultural Rating part 1: ${ culturalRatingHopi } / 5, " +
      "Cultural Rating part 2: ${ culturalRatingIndigenous } / 5, "
      "Experience Rating: ${ experienceRating } / 5, " +
      "Current Rating: ${ currentRating } / 5, " +
      "Behavioral Health Accuracy Rating: ${ contentAccurate } / 5, " +
      "Behavioral Health Trustworthy Rating: ${ contentTrustworthy } / 5, " +
      "Current Rating: ${ currentRating } / 5, ";


    User? currentUser = FirebaseAuth.instance.currentUser;
    String? reviewer = (currentUser != null) ? currentUser.email : "";

    final inboxInstance = {
      'reviewedby': reviewer,
      'email': email,
      'status': status,
      'description': description,
      'submittedName': resourceName,
      'comments': comments,
      'timestamp': timestamp
    };

    return inboxRef.add( inboxInstance ).then( ( value ) => 
      print("Inbox instance added.") ).catchError( ( error ) => 
      print("Error creating document $error")
    );
  }

  // initialize all ratings to 0
  int? culturalRatingIndigenous = 0;
  int? culturalRatingHopi = 0;
  int? experienceRating = 0;
  int? currentRating = 0;
  String? avoidRacism = '/null';
  String? avoidStereotyping = '/null';
  String? avoidAppropriation = '/null';
  String? avoidLanguage = '/null';
  String? appropriate = '/null';
  String? avoidCond = '/null';
  String? avoidAgeism = '/null';
  String? avoidSexism = '/null';
  String? sexuality = '/null';
  int? contentAccurate = 0;
  int? contentTrustworthy = 0;
  int? contentCurrent = 0;

  // list of possible gender options
  List<String> genderOptions = [
    'Female',
    'Male',
    'Non-binary',
    'Other (please specify in comments)',
  ];

  final List<bool> selectedGenders = List<bool>.filled(4, false);
  List<String> selectedGenderOptions = [];

  // list of possible age ranges
  List<String> ageRanges = [
    'Under 18',
    '18-24',
    '24-65',
    '65+',
  ];

  final List<bool> selectedAges = List<bool>.filled(4, false);
  List<String> selectedAgeRanges = [];

  // list of possible life experiences
  List<String> lifeExperiences = [
    'Specific to houseless or unsheltered relatives',
    'Specific to parents or guardians',
    'Specific to grandparents',
    'Specific to college students',
    'Specific to people living away from home (e.g., college students or people living away from Hopi)',
  ];

  final List<bool> selectedExperiences = List<bool>.filled(5, false);
  List<String> selectedLifeExperiences = [];

  //Potential accessibility features
  List<String> accessibilityFeatures = [
    'Resource is accessible to people who are visually impaired.',
    'Resource is accessible to people who are hearing impaired.',
    'Resource is accessible for people with mobility challenges (only applicable for in-person resources).',
    'Resource offers accessibility features for people who are neurodivergent.',
    'Resource is related to a sober living facility, which has been verified by ADHS and AHCCCS.',
  ];

  final List<bool> selectedAccessibility = List<bool>.filled(5, false);
  List<String> selectedAccessibilityFeatures = [];

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

  // displays the score key
  Widget buildScoringKey() {
    return Text(
      "Please answer the following questions on the content of the resource.",
      style: TextStyle(
        decoration: TextDecoration.underline,
        color: Colors.black,
        fontSize: 15.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }

    // displays the score key
  Widget buildPreliminaryScoringKey() {
    return Text(
      "Please select 'Yes' or 'No' for the following questions. If you answer 'No' to any of the following questions, the resource will be automatically denied.",
      style: TextStyle(
        decoration: TextDecoration.underline,
        color: Colors.black,
        fontSize: 15.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  //class to represent yes and no radio buttons
 /* class YesNoButtons extends StatefulWidget {
    const YesNoButtons({super.key});

    @override
    State<YesNoButtons> createState() => _YesNoButtons();
  }

  class _YesNoButtons extends State<YesNoButtons> {
    PrelimAnswer? _answer = PrelimAnswer.yes;
  }*/

  // builds the radio button ratings for the preliminary questions
  Widget buildYesNoRating(rating, Function(String) updateRating, screenSize) {

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
        final value = ButtonOptions[index];
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
                updateRating(newValue as String);
              },
            ),
          ),
        );
      }),
    );
  }

    // builds the radio button ratings for the preliminary questions
  Widget buildPreliminaryRating(rating, Function(String) updateRating, screenSize) {

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
        final value = ButtonOptions[index];
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
                updateRating(newValue as String);
                if(newValue == 'No')
                {
                    deleteResource(widget.resourceData);
                    Navigator.pop(context);
                    Navigator.pushNamed( context, '/inbox' );
                    //submitToInbox( widget.resourceData, "Denied", userComments);
                }
              },
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
                            color: Colors.blue,
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
                            color: Colors.blue,
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
                            color: Colors.blue,
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

    int totalScore = culturalRatingHopi! + culturalRatingIndigenous!
                      + currentRating! + contentAccurate! + contentTrustworthy! + currentRating! + contentCurrent!;

    String resourceInfo = 'Name: ${widget.resourceData['name']}\n\n'
        'Description: ${widget.resourceData['description']}\n\n'
        'Type: ${widget.resourceData['resourceType']}\n\n';

    resourceInfo += 'Privacy: ${widget.resourceData['privacy'].join(', ')}\n\n'
        'Cultural Responsiveness: ${widget
        .resourceData['culturalResponsivness']}\n';

    if (widget.resourceData['resourceType'] == 'Event') {
      final schedule = Schedule.fromJson(widget.resourceData['schedule']);
      if (schedule is ScheduleOnce) {
        // One-time events info...
        resourceInfo += "\nOne time event:\n\n";
        resourceInfo += "Date: ${longDateFormat.format(schedule.date)}";
        if (schedule.time != null) {
          resourceInfo += " ${schedule.time!.format(context)} (${schedule.timeZone})";
        }
        resourceInfo += "\n";
      } else if (schedule is ScheduleRecurring) {
        // Recurring events info...
        resourceInfo += "\nRecurring event:\n\n";
        resourceInfo += "Starts: ${longDateFormat.format(schedule.date)}";
        if (schedule.time != null) {
          resourceInfo += " ${schedule.time!.format(context)} (${schedule.timeZone})";
        }
        resourceInfo += "\n\nFrequency: ${schedule.frequency.name}\n";
        if (schedule.until != null) {
          resourceInfo += "\nUntil: ${longDateFormat.format(schedule.until!)}\n";
        }
      } else {
        resourceInfo += "\n(UNHANDLED EVENT SCHEDULE)\n";
      }
    }

    // create a full address if it is an in person resource
    String fullAddress = "";
    String addressUrl = "";
    if (widget.resourceData['resourceType'] == 'In Person') {
      fullAddress = widget.resourceData['address'] + ' ' +
          widget.resourceData['building']! + ' ' + widget.resourceData['city'] +
          ' ' + widget.resourceData['state'] +  ' ' + widget.resourceData['zipcode'];
    }

    // create a phone url if it is a hotline or in person resource
    String phoneNumStr="";
    String phoneUrl = "";
    if (widget.resourceData['resourceType'] == 'Hotline' ||
        widget.resourceData['resourceType'] == 'In Person') {
      phoneNumStr = widget.resourceData['phoneNumber'];
      phoneUrl = "tel:$phoneNumStr";
    }

    // create a url link
    String urlStr = widget.resourceData['location'];
    final Uri url = Uri.parse(urlStr);

    // initialize the data a resource was created
    String date = '\nDate Added: ${widget.resourceData['dateAdded']}';

    return Scaffold(
        appBar: AppBar(
          title: const Text('Review Resource'),
        ),
        body: SafeArea(
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                  // display information about the resource
                  Text(
                  'Resource Information',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: screenSize.width > 600 ? 22.0 : 18.0,
                  ),
                ),
                SizedBox(height: 10),
                    Container(
                      padding: EdgeInsets.all(10.0),
                      height: 500,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withOpacity(0.5)),
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                      child: SingleChildScrollView(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                              buildPreliminaryScoringKey(),
                          SizedBox(height: 15.0),
                          // first standard: culturally grounded
                          buildStandardTitle(
                              "Avoids Racism",
                              "Content does not exhibit racist verbiage or values."),
                          SizedBox(height: 10.0),
                          // create rating buttons and assign to correct rating
                          SizedBox(
                              child: buildPreliminaryRating(avoidRacism, (newValue) {
                                setState(() {
                                  avoidRacism = newValue;
                                });
                              }, screenSize)),
                          SizedBox(height: 15),
                          
                          // first standard: culturally grounded
                          buildStandardTitle(
                              "Avoids Sexism and Gender Stereotyping",
                              "Content does not exhibit sexist verbiage or values."),
                          SizedBox(height: 10.0),
                          // create rating buttons and assign to correct rating
                          SizedBox(
                              child: buildPreliminaryRating(avoidSexism, (newValue) {
                                setState(() {
                                  avoidSexism = newValue;
                                });
                              }, screenSize)),
                          SizedBox(height: 15),

                          // first standard: culturally grounded
                          buildStandardTitle(
                              "Avoids Pan-Indian Stereotypes",
                              "Content does not exhibit sexist verbiage or values."),
                          SizedBox(height: 10.0),
                          // create rating buttons and assign to correct rating
                          SizedBox(
                              child: buildPreliminaryRating(avoidStereotyping, (newValue) {
                                setState(() {
                                  avoidStereotyping = newValue;
                                });
                              }, screenSize)),
                          SizedBox(height: 15),
                          
                          // first standard: culturally grounded
                          buildStandardTitle(
                              "Avoids Cultural Appropriation",
                              "Content does not appropriate or misuse any aspect of any culture."),
                          SizedBox(height: 10.0),
                          // create rating buttons and assign to correct rating
                          SizedBox(
                              child: buildPreliminaryRating(avoidAppropriation, (newValue) {
                                setState(() {
                                  avoidAppropriation = newValue;
                                });
                              }, screenSize)),
                          SizedBox(height: 15),
                          
                          // first standard: culturally grounded
                          buildStandardTitle(
                              "Avoids Ageism",
                              "Content does not exhibit stereotypes based on age."),
                          SizedBox(height: 10.0),
                          // create rating buttons and assign to correct rating
                          SizedBox(
                              child: buildPreliminaryRating(avoidAgeism, (newValue) {
                                setState(() {
                                  avoidAgeism = newValue;
                                });
                              }, screenSize)),
                          SizedBox(height: 15),
                          
                          // first standard: culturally grounded
                          buildStandardTitle(
                              "Avoids Being Condescending",
                              "Content does not 'talk down.'"),
                          SizedBox(height: 10.0),
                          // create rating buttons and assign to correct rating
                          SizedBox(
                              child: buildPreliminaryRating(avoidCond, (newValue) {
                                setState(() {
                                  avoidCond = newValue;
                                });
                              }, screenSize)),
                          SizedBox(height: 15),
                          
                          // first standard: culturally grounded
                          buildStandardTitle(
                              "Avoids Innapropriate Language and Content",
                              "Content avoids profanity, vulgar language, inappropriate references to sexuality or violence, or substance abuse."),
                          SizedBox(height: 10.0),
                          // create rating buttons and assign to correct rating
                          SizedBox(
                              child: buildPreliminaryRating(avoidLanguage, (newValue) {
                                setState(() {
                                  avoidLanguage = newValue;
                                });
                              }, screenSize)),
                          SizedBox(height: 15),
                          
                          // first standard: culturally grounded
                          buildStandardTitle(
                              "Content Suggests Available and Appropriate Services",
                              "Content does not recommend services that are unavailable or that are inconsistent with HBHSs approach to alcoholism treatment and/or behavioral healthcare."),
                          SizedBox(height: 10.0),
                          // create rating buttons and assign to correct rating
                          SizedBox(
                              child: buildPreliminaryRating(appropriate, (newValue) {
                                setState(() {
                                  appropriate = newValue;
                                });
                              }, screenSize)),
                          SizedBox(height: 15),
                      ],
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.all(10.0),
                  height: 500,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: SingleChildScrollView(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          buildScoringKey(),
                      SizedBox(height: 15.0),
                      // first standard: culturally grounded, part 1
                      buildStandardTitle(
                          "Culturally grounded",
                          "Content is specific to Indigenous individuals."),
                      SizedBox(height: 10.0),
                      // create rating buttons and assign to correct rating
                      SizedBox(
                          child: buildRating(culturalRatingIndigenous, (newValue) {
                            setState(() {
                              culturalRatingIndigenous = newValue;
                            });
                          }, screenSize)),
                      SizedBox(height: 15),
                      // first standard: culturally grounded, part 2
                      buildStandardTitle(
                          "Culturally grounded",
                          "Content is specific to Hopi."),
                      SizedBox(height: 10.0),
                      // create rating buttons and assign to correct rating
                      SizedBox(
                          child: buildRating(culturalRatingHopi, (newValue) {
                            setState(() {
                              culturalRatingHopi = newValue;
                            });
                          }, screenSize)),

                      // gender balance standard
                      buildStandardTitle(
                          "Gender and Sexual Orientation",
                          "Is the content specific to any particular gender(s)? "
                              "If so, please specify below. "),
                      SizedBox(height: 10.0),
                      Text(
                        "Which gender(s)?",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      // create check boxes to display possible genders
                            SizedBox(
                                width: screenSize.width > 850
                                    ? screenSize.width / 1.5
                                    : screenSize.width / 1,
                                child: GridView.count(
                                  crossAxisCount:
                                      screenSize.width > 850 ? 2 : 1,
                                  padding: EdgeInsets.only(right: 30.0),
                                  childAspectRatio: screenSize.width > 850 ? 8 : 15,
                                  shrinkWrap: true,
                                  children: List<CheckboxListTile>.generate(
                                      genderOptions.length,
                                      (int index) => CheckboxListTile(
                                            title: Text(genderOptions[index],
                                                style: TextStyle(fontSize: 14)),
                                            value: selectedGenders[index],
                                            onChanged: (value) {
                                              setState(() {
                                                selectedGenders[index] = value!;
                                                if (value) {
                                                  selectedGenderOptions.add(
                                                      genderOptions[index]);
                                                } else {
                                                  selectedGenderOptions.remove(
                                                      genderOptions[index]);
                                                }
                                              });
                                            },
                                            controlAffinity:
                                                ListTileControlAffinity.leading,
                                            contentPadding: EdgeInsets.zero,
                                            dense: true,
                                          )),
                                ),
                              ),
                              SizedBox(height: 15),
                      // sexuality and gender
                      buildStandardTitle(
                          "Is this content specific to LGBTQIA+/Two Spirit identities?",
                          "Please check yes or no."),
                      SizedBox(height: 10.0),
                      // create rating buttons and assign to correct rating
                      SizedBox(
                          child: buildYesNoRating(sexuality, (newValue) {
                            setState(() {
                              sexuality = newValue;
                            });
                          }, screenSize)),


                      // age balance standard
                      buildStandardTitle(
                          "Age balance",
                          "Please select which age group(s) the content is targeted towards. "),
                      SizedBox(height: 10.0),
                      Text(
                        "Ages:",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      // create check boxes for ages
                            SizedBox(
                                  width: screenSize.width > 850
                                      ? screenSize.width / 1.1
                                      : screenSize.width / 1,
                                  child: GridView.count(
                                      crossAxisCount:
                                          screenSize.width > 850 ? 3 : 1,
                                      padding: EdgeInsets.only(right: 30.0),
                                      childAspectRatio:
                                          screenSize.width > 850 ? 8 : 15,
                                      shrinkWrap: true,
                                      children: List<CheckboxListTile>.generate(
                                          ageRanges.length,
                                          (index) => CheckboxListTile(
                                                title: Text(ageRanges[index],
                                                    style: TextStyle(
                                                        fontSize: 14.0)),
                                                value: selectedAges[index],
                                                onChanged: (value) {
                                                  setState(() {
                                                    selectedAges[index] =
                                                        value!;
                                                    if (value) {
                                                      selectedAgeRanges.add(
                                                          ageRanges[index]);
                                                    } else {
                                                      selectedAgeRanges.remove(
                                                          ageRanges[index]);
                                                    }
                                                  });
                                                },
                                                controlAffinity:
                                                    ListTileControlAffinity
                                                        .leading,
                                                contentPadding: EdgeInsets.zero,
                                                dense: true,
                                              )))),
                              SizedBox(height: 15),
                    // life experience standard
                    buildStandardTitle(
                        "Life Experiences",
                        "Please select which life experiences this content is relavent for. "),
                    SizedBox(height: 10.0),
                    Text(
                      "Experiences:",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    // create check boxes for experiences
                          SizedBox(
                                width: screenSize.width > 850
                                    ? screenSize.width / 1.1
                                    : screenSize.width / 1,
                                child: GridView.count(
                                    crossAxisCount:
                                        screenSize.width > 850 ? 3 : 1,
                                    padding: EdgeInsets.only(right: 30.0),
                                    childAspectRatio:
                                        screenSize.width > 850 ? 8 : 15,
                                    shrinkWrap: true,
                                    children: List<CheckboxListTile>.generate(
                                        lifeExperiences.length,
                                        (index) => CheckboxListTile(
                                              title: Text(lifeExperiences[index],
                                                  style: TextStyle(
                                                      fontSize: 14.0)),
                                              value: selectedExperiences[index],
                                              onChanged: (value) {
                                                setState(() {
                                                  selectedExperiences[index] =
                                                      value!;
                                                  if (value) {
                                                    selectedLifeExperiences.add(
                                                        lifeExperiences[index]);
                                                  } else {
                                                    selectedLifeExperiences.remove(
                                                        lifeExperiences[index]);
                                                  }
                                                });
                                              },
                                              controlAffinity:
                                                  ListTileControlAffinity
                                                      .leading,
                                              contentPadding: EdgeInsets.zero,
                                              dense: true,
                                            )))),
                            SizedBox(height: 15),
                    // accessibility standard
                    buildStandardTitle(
                        "Accessibility",
                        "Please select any accessibility features available for the resource. "),
                    SizedBox(height: 10.0),
                    Text(
                      "Features:",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 10.0),
                    // create check boxes for accessibility
                    SizedBox(
                          width: screenSize.width > 850
                              ? screenSize.width / 1.1
                              : screenSize.width / 1,
                          child: GridView.count(
                              crossAxisCount:
                                  screenSize.width > 850 ? 3 : 1,
                              padding: EdgeInsets.only(right: 30.0),
                              childAspectRatio:
                                  screenSize.width > 850 ? 8 : 15,
                              shrinkWrap: true,
                              children: List<CheckboxListTile>.generate(
                                  accessibilityFeatures.length,
                                  (index) => CheckboxListTile(
                                        title: Text(accessibilityFeatures[index],
                                            style: TextStyle(
                                                fontSize: 14.0)),
                                        value: selectedAccessibility[index],
                                        onChanged: (value) {
                                          setState(() {
                                            selectedAccessibility[index] =
                                                value!;
                                            if (value) {
                                              selectedAccessibilityFeatures.add(
                                                  accessibilityFeatures[index]);
                                            } else {
                                              selectedAccessibilityFeatures.remove(
                                                  accessibilityFeatures[index]);
                                            }
                                          });
                                        },
                                        controlAffinity:
                                            ListTileControlAffinity
                                                .leading,
                                        contentPadding: EdgeInsets.zero,
                                        dense: true,
                                      )))),
                      SizedBox(height: 15),
                  ],
                ),
              ),
            ),
            Container(
            padding: EdgeInsets.all(10.0),
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.withOpacity(0.5)),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: SingleChildScrollView(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    buildScoringKey(),
                SizedBox(height: 15.0),
                //Accuracy standard
                buildStandardTitle(
                    "Content presents accurate, up-to-date infromation",
                    "1 means 'strongly disagree' and 5 means 'strongly agree."),
                SizedBox(height: 10.0),
                // create rating buttons and assign to correct rating
                SizedBox(
                    child: buildRating(contentAccurate, (newValue) {
                      setState(() {
                        contentAccurate = newValue;
                      });
                    }, screenSize)),
                SizedBox(height: 15),
                
                //Trustworthy standard
                buildStandardTitle(
                    "Content is from a reliable and trustworthy source, has credentials if applicable",
                    "1 means 'strongly disagree' and 5 means 'strongly agree."),
                SizedBox(height: 10.0),
                // create rating buttons and assign to correct rating
                SizedBox(
                    child: buildRating(contentTrustworthy, (newValue) {
                      setState(() {
                        contentTrustworthy = newValue;
                      });
                    }, screenSize)),
                SizedBox(height: 15),

                //Current Standard
                buildStandardTitle(
                    "Content is consistent with the current state of knowledge and practice and is not outdated",
                    "1 means 'strongly disagree' and 5 means 'strongly agree."),
                SizedBox(height: 10.0),
                // create rating buttons and assign to correct rating
                SizedBox(
                    child: buildRating(contentCurrent, (newValue) {
                      setState(() {
                        contentCurrent = newValue;
                      });
                    }, screenSize)),
                SizedBox(height: 15),
            ],
          ),
        ),
      ),


            SizedBox(height: 10),
            // display the total score of ratings
            Text(
                "Total Score: ${totalScore} / 25"),
            SizedBox(height: 20),
            // display box for user comments
            Text('Additional Comments',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: screenSize.width > 600 ? 22.0 : 18.0,
                )),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: SingleChildScrollView(
                physics: ScrollPhysics(),
                child: TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Type your additional comments here',
                      border: InputBorder.none,
                    ),
                    onChanged: (value) {
                        userComments = value;
                    }
                ),
              ),
            ),
            SizedBox(height: 20),
            // display verify or deny buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<
                        RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(color: Colors.blue))),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.black),
                  ),
                  onPressed: () {
                    verifyResource(widget.resourceData);
                    updateResourceRubric(widget.resourceData, userComments,
                                                                    totalScore);
                    submitToInbox( widget.resourceData, "Approved", 
                                                                 userComments );
                    Navigator.pop(context);
                    Navigator.pushNamed( context, '/inbox' );
                  },
                  child: Text(
                    'Verify',
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                TextButton(
                  style: ButtonStyle(
                    shape: MaterialStateProperty.all<
                        RoundedRectangleBorder>(
                        RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18.0),
                            side: BorderSide(
                                color: Colors.grey.shade700))),
                    foregroundColor:
                    MaterialStateProperty.all<Color>(Colors.black),
                  ),
                  onPressed: () {
                    deleteResource(widget.resourceData);
                    submitToInbox( widget.resourceData, "Denied",userComments );
                    Navigator.pop(context);
                    Navigator.pushNamed( context, '/inbox' );
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
            )
            ])),
    ),
    )
    );
  }
}
