import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_app/common.dart';
import 'package:web_app/events/schedule.dart';
import 'package:web_app/events/schedule_view.dart';
import 'package:web_app/file_attachments.dart';
import 'package:web_app/pdfDownload.dart';
import 'package:web_app/util.dart';
import 'package:web_app/model.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DetailLink extends StatelessWidget {
  DetailLink(
      {super.key,
      required this.type,
      required this.text,
      required this.uriText,
      required this.resourceId});
  final String type;
  final String text;
  final String uriText;
  final String resourceId;

  Uri parseUriText() {
    // Default to URL
    Uri uri = Uri.parse(this.uriText);
    switch (this.type) {
      case "address":
        String address = this.uriText;
        uri = Uri.parse(Uri.encodeFull('https://maps.google.com/?q=$address'));
        break;
      case "phone":
        String number = this.uriText;
        uri = Uri.parse("tel:$number");
        break;
    }
    return uri;
  }

  @override
  Widget build(BuildContext context) {
    return Link(
      type: type,
      text: text,
      uri: parseUriText(),
      resourceId: resourceId,
    );
  }
}
// Widget to build section titles
Widget sectionTitle({required String title}) {
  return Padding(
    padding: fieldPadding,
    child: Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    ),
  );
}

// Widget to assist in building list view for fields that are lists
Widget buildFieldList(List<String>? values) {
  if (values == null || values.isEmpty) {
    return SizedBox.shrink(); // Return empty widget if no values
  }
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: values.map((value) {
      return Padding(
        padding: EdgeInsets.fromLTRB(16.0, 8.0, 8.0, 8.0),
        child: Text('- $value'),
      );
    }).toList(),
  );
}

Widget field(String label, dynamic value, {Widget Function(dynamic value)? builder, bool padding = true}) {
  // if value is blank or null, dont render the field
  if (value == null || (value is String && value.isEmpty)
      || (value is List && value.isEmpty)) {
    return SizedBox.shrink();
  }
  final valueWidget = builder != null // Check if a builder is provided, else use Text widget
      ? builder(value)
      : Text(value.toString());

   return Padding(
    padding: padding ? fieldPadding : EdgeInsets.zero,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label: ',
          softWrap: true,
          overflow: TextOverflow.visible,
        ),
        Expanded(
          child: valueWidget,
        ),
      ],
    ),
  );
}

// Converts a boolean value to "Yes" or "No" string
String boolToYesNo(bool? value) {
  if (value == null) return "Unknown";
  return value ? "Yes" : "No";
}

const fieldPadding = EdgeInsets.symmetric(vertical: 8.0);

class RubricDetail extends StatelessWidget {
  const RubricDetail({required this.rubric, super.key});

  final Rubric rubric;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7, // Limit height to 70% of screen height
          maxWidth: 600, // Limit width to 600px
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Center(
                child: Text(
                  'Rubric Information',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              ),
              Divider(),
              // Rubric Details Section
              Expanded(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Creation info
                        sectionTitle(title: 'General Info'),
                        field('Reviewed By', rubric.reviewedBy),
                        field('Review Time', rubric.reviewTime),

                        const Divider(),

                        // Preliminary Rating Section
                        sectionTitle(title: 'Preliminary Rating'),
                        field('Appropriate', boolToYesNo(rubric.appropriate)),
                        field('Avoids Ageism', boolToYesNo(rubric.avoidsAgeism)),
                        field('Avoids Appropriation', boolToYesNo(rubric.avoidsAppropriation)),
                        field('Avoids Condescension', boolToYesNo(rubric.avoidsCondescension)),
                        field('Avoids Racism', boolToYesNo(rubric.avoidsRacism)),
                        field('Avoids Sexism', boolToYesNo(rubric.avoidsSexism)),
                        field('Avoids Stereotypes', boolToYesNo(rubric.avoidsStereotyping)),
                        field('Avoids Vulgarity', boolToYesNo(rubric.avoidsVulgarity)),

                        const Divider(),

                        // Descriptive Attributes Section
                        sectionTitle(title: 'Descriptive Attributes'),
                        Padding(
                          padding: fieldPadding,
                          child: Text('Accessibility Features: '),
                        ),
                        buildFieldList(rubric.accessibilityFeaturesLabel),
                        Padding(
                          padding: fieldPadding,
                          child: Text('Ages Served: '),
                        ),
                        buildFieldList(rubric.ageBalanceLabel),
                        Padding(
                          padding: fieldPadding,
                          child: Text('Genders Represented: '),
                        ),
                        buildFieldList(rubric.genderBalanceLabel),
                        Padding(
                          padding: fieldPadding,
                          child: Text('Life Experiences Represented: '),
                        ),
                        buildFieldList(rubric.lifeExperiencesLabel),
                        field('Additional Comments', rubric.additionalComments),
                        field('Queer Sexuality Specific', boolToYesNo(rubric.queerSexualitySpecific)),

                        const Divider(),

                        // Numerical Ratings Section
                        sectionTitle(title: 'Numerical Ratings'),
                        field('Content Accuracy', rubric.contentAccuracy),
                        field('Content Currentness', rubric.contentCurrentness),
                        field('Content Trustworthiness', rubric.contentTrustworthiness),
                        field('Cultural Groundedness (Hopi)', rubric.culturalGroundednessHopi),
                        field('Cultural Groundedness (Indigenous)', rubric.culturalGroundednessIndigenous),
                        field('Total Score', rubric.totalScore),
                      ],
                    ),
                  ),
                ),
              ),
              // Close Button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class ResourceDetail extends StatelessWidget {
  const ResourceDetail({required this.resourceModel});

  final Resource resourceModel;


// This widget displays the details of a resource in a dialog.
  

  @override
  Widget build(BuildContext context) {

    User? currentUser = FirebaseAuth.instance.currentUser;

    List<Attachment> attachments = resourceModel.attachments ?? [];
    Uri? url =
        resourceModel.location != null ? Uri.parse(resourceModel.location!) : null;

    PdfDownload pdfDownload = PdfDownload();
    // Create a map of field names to their corresponding widgets
    // Allows for the dynamic generation of fields based on the resource model
    final fieldBuilders = <String, Widget Function()>{
      'description': () => field('Description', resourceModel.description),
      'resourceType': () => field('Type', resourceModel.resourceTypeLabel),
      'schedule': () => field(
        'Schedule',
        resourceModel.schedule,
        builder: (value) => ScheduleView(schedule: value)),
      'privacy': () => field('Privacy', resourceModel.privacyLabel),
      'culturalResponsiveness': () => field('Cultural Responsiveness', resourceModel.culturalResponsivenessLabel),
      'cost': () => field('Cost', resourceModel.costLabel),
      'healthFocus': () => field('Health Focus', resourceModel.healthFocusLabel),
      'address': () => field(
        'Address',
        resourceModel.fullAddress,
        builder: (value) => DetailLink(
          type: "address",
          text: value,
          uriText: value,
          resourceId: resourceModel.id,
        )),
      'phoneNumber': () => field(
        'Phone Number',
        resourceModel.phoneNumber!,
        builder: (value) => DetailLink(
          type: "phone",
          text: value,
          uriText: resourceModel.phoneNumber!,
          resourceId: resourceModel.id,
        )),
      'location': () => field(
          'URL',
          resourceModel.location,
          builder: (value) => DetailLink(
            type: "url",
            text: 'link to website here',
            uriText: value!,
            resourceId: resourceModel.id,
          ),
        ),
      'attachments': () => field(
        'Attachments',
        attachments,
        builder: (value) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AttachmentsList(attachments: value, resourceId: resourceModel.id),
          ],
        ),
      ),
    };

    // Create a list of text widgets to show based what fields are visible
    final visible = resourceModel.visibleFields();

    final rubric = resourceModel.rubric;

    final fieldsToShow = [
      for (final fieldName in visible)
        if (fieldBuilders.containsKey(fieldName)) fieldBuilders[fieldName]!(),
      if (currentUser != null) ...[
        field('Reviewed By', rubric != null ? rubric.reviewedBy : null),
        field('Review Time', rubric != null ? rubric.reviewTime : null),
      ]
    ];
    return SimpleDialog(
      key: ObjectKey(resourceModel.id),
      titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      contentPadding: EdgeInsets.all(16),
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Expanded(
          child:
            Text(
            resourceModel.name!,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: Icon(Icons.close),
          splashRadius: 20,
        )
      ]),
      children: [
        Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: DefaultTextStyle(
            style: TextStyle(fontSize: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...fieldsToShow,
                if (resourceModel.rubric != null && currentUser != null)
                  Padding(
                    padding: fieldPadding,
                    child: ElevatedButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => RubricDetail(rubric: resourceModel.rubric!),
                        );
                      },
                      child: Text('View Rubric'),
                    ),
                  ),
                Padding(
                  padding: fieldPadding,
                  child: ElevatedButton(
                    onPressed: () async {

                      // generate PDF
                      List<int> pdfBytes =
                          await pdfDownload.generateResourcePdf(
                              resourceModel.name!,
                              resourceModel.description!,
                              resourceModel.resourceTypeLabel,
                              resourceModel.privacyLabel,
                              resourceModel.healthFocusLabel,
                              resourceModel.culturalResponsivenessLabel,
                              resourceModel.fullAddress,
                              resourceModel.phoneNumber,
                              url);
                           
                      // download PDF
                      pdfDownload.downloadPdf(pdfBytes, resourceModel.name!);
                    },
                    child: Text('Download PDF'),
                  ),
                ),
                if (url != null)
                  Padding(
                    padding: fieldPadding,
                    child: ElevatedButton(
                      onPressed: () {
                        pdfDownload.shareResourceLink(
                          resourceModel.name!,
                          url,
                        );
                      },
                      child: Text('Share'),
                    ),
                  ),
                
              ],
            ),
          ),
        ),
      ],
    );
  }
}
