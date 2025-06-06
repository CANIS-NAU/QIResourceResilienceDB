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

/// Given a document for a resource that contains address information,
/// format that address as a single string.
String? formatResourceAddress(DocumentSnapshot resource) {
  try {
    return filterJoin([
      resource['address'],
      resource['building'],
      resource['city'],
      resource['state'],
      resource['zipcode'],
    ], emptyValue: null);
  } on StateError {
    return null;
  }
}

class ResourceDetail extends StatelessWidget {
  const ResourceDetail({required this.resource});

  final DocumentSnapshot resource;

  Resource get resourceModel =>
      Resource.fromJson(resource.data() as Map<String, dynamic>);


  String? fieldString(String name) {
    try {
      final value = resource[name];
      if (value == null) {
        return null;
      } else if (value is String) {
        return value.isNotEmpty ? value : null;
      } else if (value is List) {
        return value.isNotEmpty ? value.join(', ') : null;
      } else {
        // don't know what type this is so just 'toString' it.
        return value.toString();
      }
    } on StateError {
      return null;
    }
  }

  Widget field(String label, Widget valueWidget) {
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
    String? fullAddress = resourceModel.fullAddress;
    Uri? url =
        resourceModel.location != null ? Uri.parse(resourceModel.location!) : null;

    PdfDownload pdfDownload = PdfDownload();

    final fieldBuilders = <String, Widget Function()>{
      'description': () => field('Description', Text(resourceModel.description ?? '')),
      'resourceType': () => field('Type', Text(resourceModel.resourceTypeLabel)),
      'schedule': () => resourceModel.schedule != null
        ? field('Schedule', ScheduleView(schedule: resourceModel.schedule!))
        : SizedBox.shrink(),
      'privacy': () => field('Privacy', Text(resourceModel.privacyLabel)),
      'culturalResponsiveness': () => field('Cultural Responsiveness', Text(resourceModel.culturalResponsivenessLabel)),
      'cost': () => field('Cost', Text(resourceModel.costLabel)),
      'healthFocus': () => field('Health Focus', Text(resourceModel.healthFocusLabel)),
      'address': () => fullAddress != null
        ? field('Address', DetailLink(type: "address", text: fullAddress, uriText: fullAddress, resourceId: resource.id))
        : SizedBox.shrink(),
      'phoneNumber': () => resourceModel.phoneNumber != null
        ? field('Phone Number', DetailLink(type: "phone", text: resourceModel.phoneNumber!, uriText: resourceModel.phoneNumber!, resourceId: resource.id))
        : SizedBox.shrink(),
      'url': () => resourceModel.location != null
        ? field(
          'URL',
          DetailLink(
          type: "url",
          text: 'link to website here',
          uriText: resourceModel.location!,
          resourceId: resource.id,
          ),
        )
        : SizedBox.shrink(),
      'attachments': () => attachments.isNotEmpty
        ? Padding(
          padding: fieldPadding,
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Attachments: '),
            AttachmentsList(attachments: attachments, resourceId: resource.id),
          ],
          ),
        )
        : SizedBox.shrink(),
    };
    final visible = resourceModel.visibleFields();
    final fieldsToShow = [
      for (final fieldName in visible)
        if (fieldBuilders.containsKey(fieldName)) fieldBuilders[fieldName]!(),
    ];
    return SimpleDialog(
      key: ObjectKey(resource.id),
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
                      Map<String, dynamic>? resourceData = resource.data() as Map<String, dynamic>?;
                      List<dynamic> healthFocus = (resourceData != null && resourceData.containsKey('healthFocus')) ? resourceData['healthFocus']: [];

                      // generate PDF
                      List<int> pdfBytes =
                          await pdfDownload.generateResourcePdf(
                              resource['name'],
                              resource['description'],
                              resource['resourceType'],
                              resource['privacy'],
                              healthFocus,
                              resource['culturalResponsiveness'],
                              fullAddress,
                              fieldString('phoneNumber'),
                              url);
                      // download PDF
                      pdfDownload.downloadPdf(pdfBytes, resource['name']);
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
                          resource['name'],
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
