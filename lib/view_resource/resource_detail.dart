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

const fieldPadding = EdgeInsets.symmetric(vertical: 8.0);


class ResourceDetail extends StatelessWidget {
  const ResourceDetail({required this.resourceModel});

  final Resource resourceModel;

// This widget displays the details of a resource in a dialog.
  Widget field(String label, dynamic value, {Widget Function(dynamic value)? builder}) {
    // if value is blank or null, dont render the field 
    if (value == null || (value is String && value.isEmpty)
        || (value is List && value.isEmpty)) {
      return SizedBox.shrink();
    }
    final valueWidget = builder != null // Check if a builder is provided, else use Text widget
        ? builder(value)
        : Text(value);

    return Padding(
      padding: fieldPadding,
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

  @override
  Widget build(BuildContext context) {
    
    List<Attachment> attachments = resourceModel.attachments ?? [];
    Uri? url =
        resourceModel.location != null ? Uri.parse(resourceModel.location!) : null;

    PdfDownload pdfDownload = PdfDownload();

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
    final visible = resourceModel.visibleFields();
    final fieldsToShow = [
      for (final fieldName in visible)
        if (fieldBuilders.containsKey(fieldName)) fieldBuilders[fieldName]!(),
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
                  )
              ],
            ),
          ),
        ),
      ],
    );
  }
}
