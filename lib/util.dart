import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:web_app/Analytics.dart';

void showAlertDialog(BuildContext context, String statement) {
  // set up the button
  Widget okButton = TextButton(
    child: Text("OK"),
    onPressed: () {
      Navigator.pop(context);
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text("Alert"),
    content: Text(statement),
    actions: [
      okButton,
    ],
  );

  //show the dialog
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

/// Show a message dialog with a given title and message
/// and return a Future for when the dialog is closed.
Future<void> showMessageDialog(BuildContext context,
    {required String title, required String message}) {
  return showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: Text("OK"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}

class Link extends StatelessWidget {
  Link({super.key, required this.analytics, required this.type, 
                                        required this.text, required this.uri});

  final HomeAnalytics analytics;
  final String type;
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
        analytics.submitClickedkLink(type,uri);
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
