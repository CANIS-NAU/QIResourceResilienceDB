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

    String displayString( int docIndex, 
                                    List<QueryDocumentSnapshot<Object?>> data )
    {
        return 'Your resource ${data[ docIndex ][ 'submittedName' ]} has been ${data[ docIndex ][ 'status' ]}. \n' +
               'Description: \n ${data[ docIndex ][ 'description' ]}\n' + 
               'Additional Information: ${data[ docIndex ][ 'comments' ]}\n'
               'Timestamp: ${data[ docIndex ][ 'timestamp' ]}';
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
                                            child: 
                                                Container(
                                                    child: SingleChildScrollView(
                                                        child: Column(
                                                        children: [ 
                                                            Text(displayString( index, data.docs ),
                                                            overflow: TextOverflow.visible,
                                                            softWrap: true,
                                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                                        ],
                                                    ),
                                                ),
                                                
                                            ),
                                        ));
                                    }
                                    )

                                );
                            }
                        else
                        {
                            return Text('No Inbox Messages');
                        }
                        }
                    ),
                ),
        );

    }
}