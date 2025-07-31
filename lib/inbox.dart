import 'package:flutter/material.dart';
import 'package:web_app/view_resource/resource_detail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:web_app/model.dart';

enum VerificationStatus {
  Approved,
  Denied,
}

class Inbox extends StatelessWidget
{
    Inbox( { super.key } );
    static const String route = '/inbox';

    final CollectionReference inboxRef = FirebaseFirestore.instance
                                                       .collection('rrdbInbox');
    final User? currUser = FirebaseAuth.instance.currentUser;



    Future<void> deleteInboxItem(doc) async {
        // TODO: Show user via pop up operation status
        try {
          await inboxRef.doc(doc.id).delete();
          print('Successfully deleted message.');
        } catch (error) {
          print('Error deleting message.');
        }
    }

    Widget cardDisplay(BuildContext context, int docIndex,
                                      List<QueryDocumentSnapshot<Object?>> data)
    {
        Map<String, dynamic> doc = data[docIndex].data() as Map<String, dynamic>;

        Rubric? rubric = doc.containsKey('rubric')
          ? Rubric.fromJson(doc['rubric'] as Map<String, dynamic>)
          : null;

        bool resourceApproved = doc['status'] == VerificationStatus.Approved.name;

        return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
            ),
            clipBehavior: Clip.antiAliasWithSaveLayer,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                Center( child: Icon(
                    resourceApproved ? Icons.check : Icons.close_outlined,
                    size: 50.0,
                    color: resourceApproved ? Colors.green : Colors.red,
                ),
                ),
                Container(
                    padding: const EdgeInsets.fromLTRB(15,15,15,0),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                        Center( 
                          child: buildCardText(currUser, doc)
                        ),
                        Container(height: 10),
                        Row(
                        children: <Widget>[
                            const Spacer(),
                            Visibility(
                                visible: rubric != null,
                                child: TextButton(
                                    style: TextButton.styleFrom(
                                        foregroundColor: Colors.transparent,
                                    ),
                                    child: Text(
                                        "Rubric Info",
                                        style: TextStyle(color: Theme.of(context).primaryColor),
                                    ),
                                    onPressed: () {
                                        showDialog(
                                            context: context,
                                           builder: (context) => DetailDialog(
                                            detailView: RubricDetailView(rubric: rubric!),
                                            title: "Rubric Information")
                                        );
                                    },
                                )
                            ),
                            TextButton(
                            style: TextButton.styleFrom(
                                foregroundColor: Colors.transparent,
                            ),
                            child: const Text(
                                "Delete",
                                style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () {
                                deleteInboxItem(data[docIndex]);
                            },
                            ),
                        ],
                        ),
                    ],
                    ),
                ),
                Container(height: 5),
                ],
            ),
        );
    }
    Widget buildCardText(currentUser, Map<String, dynamic> doc){
      final userEmail = currentUser.email;

      String resourceMessage = "";
      String resourceStatusMessage = "";

      // set message strings depending if user is submitter or reviewer
      if (userEmail == doc['email']) {
        resourceMessage = "Your Resource: ";
        resourceStatusMessage = " has been ${doc['status']}";
      } else if (userEmail == doc['reviewedBy']) {
        resourceMessage = "Your Review of: ";
        resourceStatusMessage = " has been received and the resource has been ${doc['status']}";
      }
      
      return RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          text: resourceMessage,
          style: TextStyle(fontSize: 24),
          children: <TextSpan>[
            TextSpan(
              text: "${doc['submittedName']}",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            TextSpan(
              text: resourceStatusMessage,
              style: TextStyle(fontSize: 24),
            ),
          ],
        ),
      );
    }

    Stream<QuerySnapshot> getInboxItems()
    {
        String email = currUser?.email ?? "";

        return FirebaseFirestore.instance.collection('rrdbInbox').where(
          Filter.or(
            Filter('email', isEqualTo: email),
            Filter('reviewedBy', isEqualTo: email),
          )).snapshots();
    } 

    Widget build(BuildContext context)
    {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Inbox'),
                leading: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    splashRadius: 20.0,
                    onPressed: () {
                        Navigator.of(context).pop();
                    },
                ),
            ),
            body:
                new Container(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: StreamBuilder<QuerySnapshot>(
                        stream: getInboxItems(),
                        builder: 
                        (
                            BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot
                        )
                        {
                            if(snapshot.hasError)
                            {
                                return Text("${snapshot.error}");
                            }
                            if(snapshot.connectionState == 
                                                        ConnectionState.waiting)
                            {
                                return Text("Loading Inbox Items");
                            }

                            final data = snapshot.requireData;

                            if(data.size != 0)
                            {
                                return Align( 
                                    alignment: Alignment.topCenter,
                                    child: Container(
                                        width: 
                                         MediaQuery.of(context).size.width*0.75,
                                        child: 
                                            ListView.builder(
                                                scrollDirection: Axis.vertical,
                                                shrinkWrap: true,
                                                itemCount: data.size,
                                                itemBuilder:(context,index) 
                                                {
                                                
                                                    return cardDisplay(
                                                       context,index,data.docs);
                                                }
                                            )
                                    )
                                );
                            }
                            else
                            {
                                return Text('No inbox items at this time.');
                            }
                        }
                    ),
                ),
        );

    }
}