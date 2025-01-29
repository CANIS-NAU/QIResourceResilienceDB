import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:web_app/Analytics.dart';
import 'package:web_app/common.dart';
import 'package:web_app/events/schedule.dart';
import 'package:web_app/events/schedule_view.dart';
import 'package:web_app/file_attachments.dart';
import 'package:web_app/pdfDownload.dart';
import 'package:web_app/util.dart';

class DetailLink extends StatelessWidget {
  DetailLink(
      {super.key,
      required this.analytics,
      required this.type,
      required this.text,
      required this.uriText,
      required this.resourceId});
  final HomeAnalytics analytics;
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
      analytics: analytics,
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
  const ResourceDetail({required this.analytics, required this.resource});

  final DocumentSnapshot resource;
  final HomeAnalytics analytics;

  String? addressString() {
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

  bool fieldDefined(String name) {
    try {
      final value = resource[name];
      if (value == null) {
        return false;
      } else if (value is String) {
        return value.isNotEmpty;
      } else if (value is List) {
        return value.isNotEmpty;
      } else {
        // don't know what type this is so just assume it's set
        return true;
      }
    } on StateError {
      return false;
    }
  }

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
          Text('$label: '),
          valueWidget,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    List<Attachment> attachments = getAttachmentsFromResource(resource);
    String? fullAddress = formatResourceAddress(resource);
    Uri? url =
        fieldDefined('location') ? Uri.parse(fieldString('location')!) : null;

    PdfDownload pdfDownload = PdfDownload();
    return SimpleDialog(
      key: ObjectKey(resource.id),
      titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      contentPadding: EdgeInsets.all(16),
      title: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(
          '${resource['name']}',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
                if (fieldDefined('description'))
                  field(
                    'Description',
                    Flexible(
                      child: Text(resource['description']),
                    ),
                  ),
                if (fieldDefined('resourceType'))
                  field('Type', Text(resource['resourceType'])),
                if (fieldDefined('schedule'))
                  field(
                    'Schedule',
                    ScheduleView(
                      schedule: Schedule.fromJson(resource['schedule']),
                    ),
                  ),
                if (fieldDefined('privacy')) //
                  field('Privacy', Text(fieldString('privacy')!)),
                if (fieldDefined('culturalResponse'))
                  field(
                    'Cultural Responsiveness',
                    Text(resource['culturalResponse']),
                  ),
                if (fieldDefined('cost')) //
                  field('Cost', Text(resource['cost'])),
                if (fullAddress != null)
                  field(
                      'Address',
                      DetailLink(
                          analytics: analytics,
                          type: "address",
                          text: fullAddress,
                          uriText: fullAddress,
                          resourceId: resource.id,)),
                if (fieldDefined('phoneNumber'))
                  field(
                      'Phone Number',
                      DetailLink(
                          analytics: analytics,
                          type: "phone",
                          text: fieldString('phoneNumber')!,
                          uriText: fieldString('phoneNumber')!,
                          resourceId: resource.id,)),
                if (url != null)
                  field(
                      'URL',
                      DetailLink(
                          analytics: analytics,
                          type: "url",
                          text: 'link to website here',
                          uriText: url.toString(),
                          resourceId: resource.id)),
                if (attachments.length > 0)
                  Padding(
                    padding: fieldPadding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Attachments: '),
                        AttachmentsList(
                            analytics: analytics, attachments: attachments, resourceId: resource.id),
                      ],
                    ),
                  ),
                Padding(
                  padding: fieldPadding,
                  // button to download resource pdf
                  child: ElevatedButton(
                    onPressed: () async {
                      // generate PDF
                      List<int> pdfBytes =
                          await pdfDownload.generateResourcePdf(
                              resource['name'],
                              resource['description'],
                              resource['resourceType'],
                              resource['privacy'],
                              resource['culturalResponsivness'],
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
                    // button to share resource
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
