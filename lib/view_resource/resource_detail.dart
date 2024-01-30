import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_app/common.dart';
import 'package:web_app/events/schedule.dart';
import 'package:web_app/events/schedule_view.dart';
import 'package:web_app/pdfDownload.dart';

class Link extends StatelessWidget {
  Link({super.key, required this.text, required this.uri});

  final String text;
  final Uri uri;

  void onError(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Error"),
        content: Text("Failed to launch address"),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        if (await canLaunchUrl(uri)) {
          launchUrl(uri);
        } else {
          onError(context);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Text(
          this.text,
          style: TextStyle(
            color: Colors.blue,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );
  }
}

class AddressLink extends StatelessWidget {
  AddressLink({super.key, required this.fullAddress});

  final String fullAddress;

  @override
  Widget build(BuildContext context) {
    return Link(
      text: fullAddress,
      uri: Uri.parse(Uri.encodeFull('https://maps.google.com/?q=$fullAddress')),
    );
  }
}

class PhoneLink extends StatelessWidget {
  PhoneLink({super.key, required this.phoneNumber});

  final String phoneNumber;

  @override
  Widget build(BuildContext context) {
    return Link(
      text: phoneNumber,
      uri: Uri.parse("tel:$phoneNumber"),
    );
  }
}

class UrlLink extends StatelessWidget {
  UrlLink({super.key, required this.text, required this.url});

  final String text;
  final Uri url;

  @override
  Widget build(BuildContext context) {
    return Link(text: text, uri: url);
  }
}

const fieldPadding = EdgeInsets.symmetric(vertical: 8.0);

class ResourceDetail extends StatelessWidget {
  const ResourceDetail({required this.resource});

  final DocumentSnapshot resource;

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
    String? fullAddress = addressString();
    Uri? url =
        fieldDefined('location') ? Uri.parse(fieldString('location')!) : null;

    PdfDownload pdfDownload = PdfDownload();

    return SimpleDialog(
      key: ObjectKey(resource.id),
      titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      contentPadding: EdgeInsets.all(16),
      title: Text(
        '${resource['name']}',
        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
      ),
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
                  field('Address', AddressLink(fullAddress: fullAddress)),
                if (fieldDefined('phoneNumber'))
                  field(
                    'Phone Number',
                    PhoneLink(phoneNumber: fieldString('phoneNumber')!),
                  ),
                if (url != null)
                  field(
                    'URL',
                    UrlLink(text: 'link to website here', url: url),
                  ),
                Padding(
                  padding: fieldPadding,
                  // button to download resource pdf
                  child: ElevatedButton(
                    onPressed: () async {
                      // generate PDF
                      List<int> pdfBytes = await pdfDownload.generateResourcePdf(
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
                 if(url!= null)
                     Padding(
                       padding: fieldPadding,
                       // button to share resource
                       child: ElevatedButton(
                         onPressed: () {
                           pdfDownload.shareResourceLink(
                             resource['name'],
                             url,);
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
