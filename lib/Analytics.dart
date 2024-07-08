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

  Future<void> uploadRecord(String event) {

    if(this.uuid == "") {
      this.uuid = this.generatedUUID(this.getCookie());
    }

    final eventObj = {
      "uuid": this.uuid,
      "event": event,
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

  bool checkUUIDNotNull(Map cookieMap) {
    return cookieMap.containsKey("uuid");
  }

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

  // Declare data collection references
  final CollectionReference searchRef = FirebaseFirestore.instance
    .collection('RRDBSearches');
  final CollectionReference filterRef = FirebaseFirestore.instance
    .collection('RRDBFilters');
  final CollectionReference clickedRef = FirebaseFirestore.instance 
    .collection("RRDBClickedResources");
  final CollectionReference clickedLinkRef = FirebaseFirestore.instance 
    .collection("RRDBClickedLinks");

  // Submit the user text search
  Future<void> submitTextSearch(String textSearch) {
    final search = {
      "search": textSearch,
      "timestamp": getCurrentTime()
    };

    eventLog.uploadRecord("text-search");

    return this.searchRef.add(search).then((value) => 
      print("User search submitted")).catchError((onError) => 
      print("Error submitting user search"));
  }
  
  // Submit the user filtered search
  Future<void> submitFilterSearch(Set<FilterItem> filter) {
    Map<String,dynamic> submissionFilter = {};
    for(var filterItem in filter) {
      submissionFilter[filterItem.category] = filterItem.value;
    }

    submissionFilter["timestamp"] = getCurrentTime();

    return this.filterRef.add(submissionFilter).then((value) => 
      print("User filter submitted")).catchError((onError) => 
      print("Error submitting user filter"));
  }

  // Submit the resource the user clicked
  Future<void> submitClickedResource(String resource) {
    final clicked = {
      "resource": resource,
      "timestamp": getCurrentTime()
    };
    
    eventLog.uploadRecord("clicked-resource");

    return this.clickedRef.add(clicked).then((value) => 
      print("User click submitted")).catchError((onError) => 
      print("Error submitting user click"));
  }

  Future<void> submitClickedkLink(String type,Uri link) {
    final linkClicked = {
      "type": type,
      "link": link.toString(),
      "time": getCurrentTime()
    };

    eventLog.uploadRecord("clicked-link");

    return this.clickedLinkRef.add(linkClicked).then((value) => 
      print("User clicked link submitted")).catchError((onError) => 
      print("Error submitting user clicked link"));
  }
}

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