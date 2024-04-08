import 'package:web_app/common.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Sends users resource submission to db
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
