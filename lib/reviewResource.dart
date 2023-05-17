/*
This page displays the resource information and rubric to the reviewer.
The rubric ratings, total score, and additional comments are saved and the reviewer can
choose to verify or deny a resource.
 */

//Package imports
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

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

  // function to verify a resource
  Future<void> verifyResource(name) {
    return resourceCollection.doc(name.id).update({"verified": true})
        .then((value) => print("Updated"))
        .catchError((error) => print("Failed to update resource: $error"));
  }

  // function to deny/delete a resource
  Future<void> deleteResource(name) {
    return resourceCollection.doc(name.id).delete()
        .then((value) => print("Resource Delete"))
        .catchError((error) => print("Failed to delete resource: $error"));
  }

  // function to add rubric info to a resource
  Future<void> updateResourceRubric(resource, userComments, totalScore) {
    // define rubric and all sub-fields (score, ratings, comments)
    final rubric = {
      'totalScore': totalScore,
      'additionalComments': userComments,
      'culturallyGrounded': culturalRating,
      'genderBalance': selectedGenderOptions,
      'ageBalance': selectedAgeRanges,
      'experienceBalance': experienceRating,
      'socialSupport': socialRating,
      'productionValue': productionRating,
      'relevance': relevanceRating,
      'consistency': consistencyRating,
      'modularizable': modularityRating,
      'authenticity': authenticityRating,
      'notMorallyOffensive': moralRating,
      'accurate': accurateRating,
      'trustworthySource': trustworthyRating,
      'current': currentRating,
      'language': languageRating,
    };

  //update the resource with rubric information
    return resourceCollection.doc(resource.id).update({'rubric': rubric}).then(
            (value) => print("Resource successfully updated"))
        .catchError( (error) => print("Error updating document $error"));
  }

  // initialize all ratings to 0
  int? culturalRating = 0;
  int? experienceRating = 0;
  int? socialRating = 0;
  int? productionRating = 0;
  int? relevanceRating = 0;
  int? consistencyRating = 0;
  int? modularityRating = 0;
  int? authenticityRating = 0;
  int? moralRating = 0;
  int? accurateRating = 0;
  int? trustworthyRating = 0;
  int? currentRating = 0;
  int? languageRating = 0;

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
    '25-34',
    '35-44',
    '45-54',
    '55+',
  ];

  final List<bool> selectedAges = List<bool>.filled(6, false);
  List<String> selectedAgeRanges = [];

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
      "Scoring: 1 = not at all; 5 = very much so",
      style: TextStyle(
        decoration: TextDecoration.underline,
        color: Colors.black,
        fontSize: 15.0,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // builds the radio button ratings
  Widget buildRating(rating, Function(int) updateRating, screenSize) {
    final ratingItemWidth = screenSize.width > 850
        ? screenSize.width / 10
        : screenSize.width / 8;

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

  @override
  Widget build(BuildContext context) {
    // get the screen size
    final Size screenSize = MediaQuery.of(context).size;

    String userComments = "";

    int totalScore = culturalRating! + experienceRating! + socialRating! +
        productionRating! + relevanceRating! + consistencyRating! +
        modularityRating! + authenticityRating! + moralRating! +
        accurateRating! + trustworthyRating! + currentRating! +
        languageRating!;

    String resourceInfo = 'Name: ${widget.resourceData['name']}\n\n'
        'Description: ${widget.resourceData['description']}\n\n'
        'Type: ${widget.resourceData['resourceType']}\n\n';

    if (widget.resourceData['resourceType'] == 'Hotline' ||
        widget.resourceData['resourceType'] == 'In Person') {
      resourceInfo += 'Phone Number: ${widget.resourceData['phoneNumber']}\n\n';
    }
    if (widget.resourceData['resourceType'] == 'In Person') {
      resourceInfo += 'Address: ${widget.resourceData['address']} ${widget
          .resourceData['building']!} '
          '${widget.resourceData['city']}, ${widget
          .resourceData['state']}, ${widget.resourceData['zipcode']}\n\n';
    }

    resourceInfo += 'Privacy: ${widget.resourceData['privacy'].join(', ')}\n\n'
        'Cultural Responsiveness: ${widget
        .resourceData['culturalResponsivness']}\n\n'
        'URL: ${widget.resourceData['location']}\n\n'
        'Date Added: ${widget.resourceData['dateAdded']}';

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
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: SingleChildScrollView(
                        child: Text(resourceInfo,
                            style: TextStyle(
                              fontSize: 14.0,
                            )))),
                SizedBox(height: 20),
                // display the rubric for the resource
                Text('Rubric',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: screenSize.width > 600 ? 22.0 : 18.0,
                    )),
                SizedBox(height: 10),
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
                      // first standard: culturally grounded
                      buildStandardTitle(
                          "Culturally grounded",
                          "Content is culturally responsive, "
                              "appropriate for AN/AI audience; avoids "
                              "“pan-Indian” stereotypes."),
                      SizedBox(height: 10.0),
                      // create rating buttons and assign to correct rating
                      SizedBox(
                          child: buildRating(culturalRating, (newValue) {
                            setState(() {
                              culturalRating = newValue;
                            });
                          }, screenSize)),
                      SizedBox(height: 15),

                      // gender balance standard
                      buildStandardTitle(
                          "Gender balance",
                          "Content reflects a range of gender and sexual "
                              "identities and perspectives. Avoids sexism and "
                              "gender stereotyping. "),
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
                        width: screenSize.width > 850 ? MediaQuery
                            .of(context).size.width / 1.5
                            : MediaQuery.of(context).size.width / 1,
                        child: GridView.count(
                          crossAxisCount: screenSize.width > 850 ? 2 : 1,
                          padding: EdgeInsets.only(right: 30.0),
                          childAspectRatio: 15,
                          shrinkWrap: true,
                          children: List<CheckboxListTile>.generate(
                              genderOptions.length,
                                  (int index) =>
                                  CheckboxListTile(
                                    title: Text(
                                        genderOptions[index], style: TextStyle(
                                        fontSize: 14)),
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
                                    controlAffinity: ListTileControlAffinity
                                        .leading,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  )
                          ),
                        ),
                      ),
                      SizedBox(height: 15),

                      // age balance standard
                      buildStandardTitle(
                          "Age balance",
                          "Content reflects a range of age perspectives "
                              "(18 and older), "
                              "avoids ageism and age stereotyping. "),
                      SizedBox(height: 10.0),
                      Text(
                        "Which ages?",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 14.0,
                        ),
                      ),
                      SizedBox(height: 10.0),
                      // create check boxes for ages
                      SizedBox(
                          width: screenSize.width > 850 ? MediaQuery
                              .of(context)
                              .size
                              .width / 1.1 : MediaQuery
                              .of(context)
                              .size
                              .width / 1,
                          child: GridView.count(
                              crossAxisCount: screenSize.width > 850 ? 3 : 1,
                              padding: EdgeInsets.only(right: 30.0),
                              childAspectRatio: 15,
                              shrinkWrap: true,
                              children: List<CheckboxListTile>.generate(
                                  ageRanges.length, (index) =>
                                  CheckboxListTile(
                                    title: Text(
                                        ageRanges[index], style: TextStyle(
                                        fontSize: 14.0)),
                                    value: selectedAges[index],
                                    onChanged: (value) {
                                      setState(() {
                                        selectedAges[index] = value!;
                                        if (value) {
                                          selectedAgeRanges.add(
                                              ageRanges[index]);
                                        } else {
                                          selectedAgeRanges.remove(
                                              ageRanges[index]);
                                        }
                                      });
                                    },
                                    controlAffinity: ListTileControlAffinity
                                        .leading,
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                  ))
                          )
                      ),
                      SizedBox(height: 15),
                      // experience balance standard
                      buildStandardTitle(
                          "Experience balance",
                          "Content reflects a range of life experiences, "
                              "situations, etc. (Examples: ppl with stable "
                              "housing and without, ppl who have sought "
                              "treatment and not, people with partners and not, "
                              "ppl with and without other behavioral health "
                              "or mental health concerns) "),
                      SizedBox(height: 10.0),
                      // create rating buttons and assign to correct rating
                      SizedBox(
                          child:
                          buildRating(experienceRating, (newValue) {
                            setState(() {
                              experienceRating = newValue;
                            });
                          }, screenSize)),
                      SizedBox(height: 15),
                      // social support standard
                      buildStandardTitle(
                          "Social support",
                          "Content reflects a range of social support/network "
                              "– includes content for individuals "
                              "who are on their own as well as those with "
                              "strong support from family, friends, "
                              "Learning Circles, sponsors, etc. "),
                      SizedBox(height: 10.0),
                      // create rating buttons and assign to correct rating
                      SizedBox(
                          child: buildRating(socialRating, (newValue) {
                            setState(() {
                              socialRating = newValue;
                            });
                          }, screenSize)),
                      SizedBox(height: 15),
                      // production value standard
                      buildStandardTitle(
                          "Production value",
                          "Content is professionally presented; audio is clear;"
                              " visuals are clear and engaging."),
                      SizedBox(height: 10.0),
                      // create rating buttons and assign to correct rating
                      SizedBox(
                          child:
                          buildRating(productionRating, (newValue) {
                            setState(() {
                              productionRating = newValue;
                            });
                          }, screenSize)),
                      SizedBox(height: 15),
                      // relevance standard
                      buildStandardTitle(
                          "Relevance",
                          "Content could be helpful for individuals in the SCF "
                              "and ANAI cultural context working with alcohol"
                              " misuse, recovery, sobriety, and/or addiction"),
                      SizedBox(height: 10.0),
                      // create rating buttons and assign to correct rating
                      SizedBox(
                          child: buildRating(relevanceRating, (newValue) {
                            setState(() {
                              relevanceRating = newValue;
                            });
                          }, screenSize)),
                      SizedBox(height: 15),
                      // consistency standard
                      buildStandardTitle(
                          "Consistency with existing SCF services",
                          "Content does not recommend services that are unavailable "
                              "or that are inconsistent with SCF’s approach "
                              "to alcohol treatment."),
                      SizedBox(height: 10.0),
                      // create rating buttons and assign to correct rating
                      SizedBox(
                          child:
                          buildRating(consistencyRating, (newValue) {
                            setState(() {
                              consistencyRating = newValue;
                            });
                          }, screenSize)),
                      SizedBox(height: 15),
                      // modularizable standard
                      buildStandardTitle("Modularizable",
                          "Content can be broken up into bite-sized chunks "
                              "that are reasonable for a smartphone app. "),
                      SizedBox(height: 10.0),
                      // create rating buttons and assign to correct rating
                      SizedBox(
                          child:
                          buildRating(modularityRating, (newValue) {
                            setState(() {
                              modularityRating = newValue;
                            });
                          }, screenSize)),
                      SizedBox(height: 15),
                  // authenticity standard
                  buildStandardTitle(
                      "Authenticity",
                      "Content is not “New Age” or “woo woo” (i.e.,"
                          " combination of a variety of ancient and modern "
                          "cultures, that emphasize beliefs (such as"
                          " reincarnation, holism, pantheism, and occultism) "
                          "outside the mainstream, and that advance"
                          " alternative approaches to spirituality, "
                          "right living, and health). Avoids cultural "
                          "appropriation (e.g., misuse of sweat lodge or "
                          "other ceremonies by non-Native people, "
                          "misrepresentation of Indigenous spiritual "
                          "and cultural practices)."),
                  SizedBox(height: 10.0),
                  // create rating buttons and assign to correct rating
                  SizedBox(
                      child:
                      buildRating(authenticityRating, (newValue) {
                        setState(() {
                          authenticityRating = newValue;
                        });
                      }, screenSize)),
                  SizedBox(height: 15),
                  // moral standard
                  buildStandardTitle(
                      "Not morally offensive",
                      "Content avoids profanity, vulgar language, "
                          "inappropriate references to sexuality or violence,"
                          " glorification of violence or substance abuse."),
                  SizedBox(height: 10.0),
                  // create rating buttons and assign to correct rating
                  SizedBox(
                      child: buildRating(moralRating, (newValue) {
                        setState(() {
                          moralRating = newValue;
                        });
                      }, screenSize)),
                  SizedBox(height: 15),
                  // accurate standard
                  buildStandardTitle("Accurate",
                      "Content presents accurate information."),
                  SizedBox(height: 10.0),
                  // create rating buttons and assign to correct rating
                  SizedBox(
                      child: buildRating(accurateRating, (newValue) {
                        setState(() {
                          accurateRating = newValue;
                        });
                      }, screenSize)),
                  SizedBox(height: 15),
                  // trustworthy standard
                  buildStandardTitle("Trustworthy source",
                      "Content is from a reliable, trustworthy source, "
                          "credentialed if applicable."),
                  SizedBox(height: 10.0),
                  // create rating buttons and assign to correct rating
                  SizedBox(
                      child:
                      buildRating(trustworthyRating, (newValue) {
                        setState(() {
                          trustworthyRating = newValue;
                        });
                      }, screenSize)),
                  SizedBox(height: 15),
                  // current standard
                  buildStandardTitle(
                      "Current",
                      "Content is consistent with current state of "
                          "knowledge and practice; not outdated. "),
                  SizedBox(height: 10.0),
                  // create rating buttons and assign to correct rating
                  SizedBox(
                      child: buildRating(currentRating, (newValue) {
                        setState(() {
                          currentRating = newValue;
                        });
                      }, screenSize)),
                  SizedBox(height: 15),
                  // language standard
                  buildStandardTitle("Language, tone",
                      "Content is pitched not too high or too low "
                          "(no “talking down”). "),
                  SizedBox(height: 10.0),
                  // create rating buttons and assign to correct rating
                  SizedBox(
                      child: buildRating(languageRating, (newValue) {
                        setState(() {
                          languageRating = newValue;
                        });
                      }, screenSize)),
                  SizedBox(height: 5),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            // display the total score of ratings
            Text(
                "Total Score: ${totalScore} / 65"),
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
                      setState(() {
                        userComments = value;
                      });
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
                    updateResourceRubric(widget.resourceData, userComments, totalScore);
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