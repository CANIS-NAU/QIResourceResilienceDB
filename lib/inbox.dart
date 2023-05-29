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

    //Get the current signed in user
    User? currUser = FirebaseAuth.instance.currentUser;

    String? returnEmail()
    {
        User? currUser = FirebaseAuth.instance.currentUser;

        String? email = currUser != null ? currUser.email : "";

        return email;
    }

    Stream<QuerySnapshot> getInboxItems()
    {
        return FirebaseFirestore.instance.collection('rrdbInbox').where('email', isEqualTo: returnEmail() ).snapshots();
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
                        builder: (
                            BuildContext context,
                            AsyncSnapshot<QuerySnapshot> snapshot,
                        ){
                            if(snapshot.hasError)
                            {
                                return Text("${snapshot.error}");
                            }
                            if( snapshot.connectionState == ConnectionState.waiting )
                            {
                                return Text("Loading Inbox Items");
                            }

                            final data = snapshot.requireData;

                            if(data.size != 0)
                            {
                            return Container(
                                height: 500,
                                child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: data.size,
                                itemBuilder: (context, index) {
                                    return Container(
                                    height: 100,
                                    child: Card(
                                        color: Colors.white,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(0)),
                                        ),
                                    // the format for each resource box
                                        child: ListTile(
                                        contentPadding: EdgeInsets.symmetric(
                                            vertical: 10.0,
                                            horizontal: 30.0),
                                            dense: false,
                                            title: SizedBox( width: index == 0 ? 95 : 80,
                                            child: Text('Your resource ${data.docs[ index ][ 'submittedName' ]} has been ${data.docs[ index ][ 'status' ]}.',
                                            overflow: TextOverflow.visible,
                                            softWrap: true,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),)),
                                            subtitle: SizedBox( width: 80,
                                        child: Text('Description: ${data.docs[ index ][ 'description' ]}',
                                            overflow: TextOverflow.visible,
                                            softWrap: true,
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14))),
                                        ),
                                    ),
                                    );
                                }
                                )

                            );
                            }
                        else
                            {
                            return Text('No resources');
                            }
                        }
                    ),
                ),
        );

    }
}