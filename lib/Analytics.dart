import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:web_app/common.dart';
import 'package:web_app/view_resource/filter.dart';

class EventLog {
  String? uuid; // Unique user ID
  String? session; // Session ID

  // Reference the event log document. Do with cookies later on.
  final CollectionReference eventRef =
      FirebaseFirestore.instance.collection('RRDBEventLog');

  Future<void> requestSession() async {
    if (this.uuid != null) {
      return;
    }

    final url = dotenv.get('GET_UUID', fallback: '/api/getSession');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      this.uuid = json.decode(response.body)['uuid'].toString();
      this.session = json.decode(response.body)['session'].toString();
    } else {
      debugPrint('Failed to get session information.');
    }
  }

  // Upload an event to the log
  Future<void> uploadRecord(String event, final payload) async {
    await this.requestSession();
    if (this.session == null) {
      return;
    }

    final eventObj = {
      "uuid": this.uuid,
      "sessionId": this.session,
      "event": event,
      "payload": payload,
      "timestamp": getCurrentTime()
    };

    try {
      await this.eventRef.add(eventObj);
      debugPrint("User event submitted");
    } catch (err) {
      debugPrint("Error submitting event");
    }
  }
}

// Resonsible for uploading searches and filter options
class HomeAnalytics {
  EventLog eventLog = EventLog();

  // Submit the user text search
  Future<void> submitTextSearch(String textSearch) {
    final search = {
      "search": textSearch,
    };

    return eventLog.uploadRecord("text-search", search);
  }

  // Submit the user filtered search
  Future<void> submitFilterSearch(Set<FilterItem> filter) {
    Map<String, dynamic> submissionFilter = {};
    for (var filterItem in filter) {
      submissionFilter[filterItem.category] = filterItem.value;
    }
    return eventLog.uploadRecord("filter", submissionFilter);
  }

  // Submit the resource clicked event
  Future<void> submitClickedResource(String resource) {
    return eventLog.uploadRecord("clicked-resource", {"resource": resource});
  }

  // Submit the link the user submitted
  Future<void> submitClickedLink(String type,Uri link, String resourceId) {
    final linkClicked = {
      "type": type,
      "link": link.toString(),
      "resourceId": resourceId
    };

    return eventLog.uploadRecord("clicked-link", linkClicked);
  }
}

/*
  TODO: Maybe put these in the event log as well. Might be helpful to tag these
  as admin events.
*/
class UserResourceSubmission {
  UserResourceSubmission(this.currentUser);
  final CollectionReference submissionRef =
      FirebaseFirestore.instance.collection('RRDBUserResourceSubmission');

  final User? currentUser;

  Future<void> submittedResource(String resourceName, String resourceType) {
    final resourceRecord = {
      "user": this.currentUser?.uid,
      "resourceName": resourceName,
      "resourceType": resourceType,
      "timestamp": getCurrentTime(),
    };

    return this
        .submissionRef
        .add(resourceRecord)
        .then((value) => debugPrint("User resource submission successful"))
        .catchError((onError) =>
            debugPrint("Error submitting user resource submission"));
  }
}

// Sends user review to db when user reviews a resource
class UserReview {
  UserReview(this.currentUser);
  final CollectionReference reviewRef =
      FirebaseFirestore.instance.collection('RRDBUserReview');

  final User? currentUser;

  Future<void> submittedResource(final rubricScores) {
    final resourceRecord = {
      "user": this.currentUser?.uid,
      "rubricScores": rubricScores,
      "timestamp": getCurrentTime(),
    };

    return this
        .reviewRef
        .add(resourceRecord)
        .then((value) => debugPrint("User review sucessfully uploaded"))
        .catchError((onError) => debugPrint("Error submitting user review"));
  }
}
