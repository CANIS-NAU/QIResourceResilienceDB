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



    Future<void> deleteInboxItem(doc) 
    {
        // TODO: Show user via pop up operation status
        return inboxRef.doc(doc.id).delete()
        .then((value) => print('Successfully deleted message.'))
        .catchError((error) => print('Error deleting message.'));
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
                        child: RichText(
                            text: 
                                TextSpan(
                                text: 'Your Resource: ',
                                style: TextStyle(fontSize: 24),
                            children: <TextSpan>[
                                TextSpan(
                                    text: "${doc['submittedName']} ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                    ),
                                ),
                                TextSpan(
                                    text: 
                                        "has been ${doc['status']}.",
                                    style: TextStyle(fontSize: 24),
                                ),
                            ],
                        ),
                        )),
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
                                           builder: (context) => RubricDetail(rubric: rubric!)
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

    Stream<QuerySnapshot> getInboxItems()
    {
        String email = currUser?.email ?? "";
        return FirebaseFirestore.instance.collection('rrdbInbox').where('email',
                                          isEqualTo: email).snapshots();
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