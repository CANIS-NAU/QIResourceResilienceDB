import 'package:flutter/material.dart';
import 'package:web_app/view_resource/resource_detail.dart';
import 'package:web_app/model.dart';
void main() {

  Resource resource = Resource(
    name: "Example Resource",
    address: "Example Address",
    resourceType: "Online",
    description: "Example Description",
    reviewBy: "Reviewer Name",
    reviewTime: DateTime.now(),
    rubric: Rubric(
      accessibilityFeatures: ['Visually Impaired', 'Hearing Impaired'],
      additionalComments: "Example additional comments",
      ageBalance: ['Under 18', '18-24', '24-65'],
      appropriate: true,
      avoidsAgeism: true,
      avoidsAppropriation: true,
      avoidsCondescension: true,
      avoidsRacism: true,
      avoidsSexism: true,
      avoidsStereotyping: true,
      avoidsVulgarity: true,
      contentAccuracy: 1,
      contentCurrentness: 2,
      contentTrustworthiness: 3,
      culturalGroundednessHopi: 2,
      culturalGroundednessIndigenous: 1,
      genderBalance: ['Female'],
      lifeExperiences: ['Specific to houseless or unsheltered relatives'],
      queerSexualitySpecific: true,
    ),
  );

  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: ResourceDetail(resourceModel: resource), // ⬅️ replace with your widget
        ),
      ),
    ),
  );
}
