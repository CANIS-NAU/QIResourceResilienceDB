import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_app/view_resource/filter.dart';
import 'package:firebase_auth/firebase_auth.dart';
// Time
import 'package:web_app/common.dart';

// Cookies
import 'dart:html';

class EventLog {
  // Identifying session id 
  String uuid = "";

  // Reference the event log document. Do with cookies later on.
  final CollectionReference eventRef = FirebaseFirestore.instance
    .collection('RRDBEventLog');

  // Upload an event to the log
  Future<void> uploadRecord(String event, final payload) {

    if(this.uuid == "") {
      this.uuid = this.generatedUUID(this.getCookie());
    }

    final eventObj = {
      "uuid": this.uuid,
      "event": event,
      "payload": payload,
      "timestamp": getCurrentTime()
    };

    return this.eventRef.add(eventObj).then((value) => 
      print("User event submitted")).catchError((onError) => 
      print("Error submitting event"));
  }

  String generateNewUUID() {
    final now = DateTime.now();
    return now.microsecondsSinceEpoch.toString();
  }

  Map getCookie() {
    // Get the cookie attached to document
    final cookie = document.cookie!;

    // Create a map from the cookie structure
    final entity = cookie.split("; ").map((item) {
      final split = item.split("=");
      return MapEntry(split[0], split[1]);
    });

    // return the cookie map
    return Map.fromEntries(entity);
  }

  // Check if the cookie contains a uuid
  bool checkUUIDNotNull(Map cookieMap) {
    return cookieMap.containsKey("uuid");
  }

  // Generate a new uuid if one is not present
  String generatedUUID(Map cookieMap) {
    String uuid = "";
    if(this.checkUUIDNotNull(cookieMap)) {
      uuid = cookieMap["uuid"];
    }
    else {
      uuid = this.generateNewUUID();
      document.cookie = "uuid=$uuid";
    }
    return uuid;
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

    return eventLog.uploadRecord("text-search",search);
  }
  
  // Submit the user filtered search
  Future<void> submitFilterSearch(Set<FilterItem> filter) {
    Map<String,dynamic> submissionFilter = {};
    for(var filterItem in filter) {
      submissionFilter[filterItem.category] = filterItem.value;
    }
    return eventLog.uploadRecord("filter", submissionFilter);
  }

  // Submit the resource clicked event
  Future<void> submitClickedResource(String resource) {
    return eventLog.uploadRecord("clicked-resource",{"resource": resource});
  }

  // Submit the link the user submitted
  Future<void> submitClickedkLink(String type,Uri link) {
    final linkClicked = {
      "type": type,
      "link": link.toString(),
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
  final CollectionReference submissionRef = FirebaseFirestore.instance
  .collection('RRDBUserResourceSubmission');

  final User? currentUser;

  Future<void> submittedResource(String resourceName, String resourceType) {
    final resourceRecord = {
      "user": this.currentUser?.uid,
      "resourceName": resourceName,
      "resourceType": resourceType,
      "timestamp": getCurrentTime(), 
    };

    return this.submissionRef.add(resourceRecord).then((value) => 
      print("User resource submission successful")).catchError((onError) => 
      print("Error submitting user resource submission"));
  }
}

// Sends user review to db when user reviews a resource
class UserReview {
  UserReview(this.currentUser);
  final CollectionReference reviewRef = FirebaseFirestore.instance
  .collection('RRDBUserReview');

  final User? currentUser;

  Future<void> submittedResource(final rubricScores) {  
    final resourceRecord = {
      "user": this.currentUser?.uid,
      "rubricScores": rubricScores,
      "timestamp": getCurrentTime(), 
    };

    return this.reviewRef.add(resourceRecord).then((value) => 
      print("User review sucessfully uploaded")).catchError((onError) => 
      print("Error submitting user review"));
  }
}