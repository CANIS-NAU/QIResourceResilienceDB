import 'package:web_app/common.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminResourceSubmission {
  AdminResourceSubmission(this.currentUser);
  final CollectionReference submissionRef = FirebaseFirestore.instance
  .collection('RRDBAdminResourceSubmission');

  final User? currentUser;

  Future<void> submittedResource(String resourceName, String resourceType) {
    final resourceRecord = {
      "user": this.currentUser?.uid,
      "resourceName": resourceName,
      "resourceType": resourceType,
      "timestamp": getCurrentTime(), 
    };

    return this.submissionRef.add(resourceRecord).then((value) => 
      print("Admin submission submission successful")).catchError((onError) => 
      print("Error submitting admin resource submission"));
  }
}

class AdminReview {
  AdminReview(this.currentUser);
  final CollectionReference reviewRef = FirebaseFirestore.instance
  .collection('RRDBAdminReview');

  final User? currentUser;

  Future<void> submittedResource(final rubricScores) {  
    final resourceRecord = {
      "user": this.currentUser?.uid,
      "rubricScores": rubricScores,
      "timestamp": getCurrentTime(), 
    };

    return this.reviewRef.add(resourceRecord).then((value) => 
      print("Admin review sucessfully uploaded")).catchError((onError) => 
      print("Error submitting admin review"));
  }
}
