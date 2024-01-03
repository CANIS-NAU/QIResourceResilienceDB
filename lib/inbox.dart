import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class Inbox extends StatelessWidget
{
    Inbox( { super.key } );
    static const String route = '/inbox';

    bool inboxEmpty = true;

    final CollectionReference inboxRef = FirebaseFirestore.instance
                                                       .collection('rrdbInbox');

    //Get the current signed in user
    User? currUser = FirebaseAuth.instance.currentUser;

    String? returnEmail()
    {
        User? currUser = FirebaseAuth.instance.currentUser;

        String? email = currUser != null ? currUser.email : "";

        return email;
    }

    Widget showRubricDetail(BuildContext context, doc)
    {
        String parts = doc['description'].replaceAll(', ', '\n');;
        return AlertDialog(
            titlePadding: EdgeInsets.fromLTRB(16, 16, 16, 0),
            contentPadding: EdgeInsets.all(16),
            title: Text(
                'Rubric Information',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            content: FractionallySizedBox(
                widthFactor: null,
                heightFactor: null,
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                    Text('All Scores:\n${parts}\n\n'),
                    Text('Additional Information: ${doc['comments']}\n\n'),
                    Text('Time Reviewed: ${doc['timestamp']}')
                    // Add more widgets as needed
                ],
                ),
            ),
            actions: <Widget>[
                new ElevatedButton(
                    onPressed: () {
                        Navigator.of(context).pop();
                    },
                    child: const Text('Close'),
                ),
            ],

        );
    }

    Future<void> deleteInboxItem(doc) 
    {
        // TODO: Show user via pop up operation status
        return inboxRef.doc(doc.id).delete()
        .then((value) => print("Successfully deleted message."))
        .catchError((error) => print("Error deleting message."));
    }

    Widget cardDisplay(BuildContext context, int docIndex,
                                      List<QueryDocumentSnapshot<Object?>> data)
    {
        bool resourceApproved = data[docIndex]['status'] == "Approved";
        String resourceName = 
                   "Your Resource: resource ${data[docIndex]['submittedName']}";
        String outcome = "has been ${data[docIndex]['status']}.";
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
                    padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                        Center( child: Text(
                        resourceName + outcome,
                        style: TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                        ),
                        )),
                        Container(height: 10),
                        Row(
                        children: <Widget>[
                            const Spacer(),
                            TextButton(
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.transparent,
                                ),
                                child: const Text(
                                    "Rubric Info",
                                    style: TextStyle(color: Colors.blue),
                                ),
                                onPressed: () {
                                    showDialog(
                                        context: context,
                                        builder: (BuildContext context) 
                                        {
                                            return showRubricDetail(context,
                                                                data[docIndex]);
                                        },
                                    );
                                },
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

    Stream<QuerySnapshot> getInboxItems()
    {
        return FirebaseFirestore.instance.collection('rrdbInbox').where('email',
                                         isEqualTo: returnEmail() ).snapshots();
    } 

    Widget build( BuildContext context )
    {
        return Scaffold(
            appBar: AppBar(
                title: const Text('Inbox'),
            ),
            body:
                new Container(
                    padding: const EdgeInsets.symmetric( vertical: 20),
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
                                                itemBuilder: (context, index) 
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