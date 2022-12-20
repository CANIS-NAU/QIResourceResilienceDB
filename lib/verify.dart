//Package imports
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

//Shows unverified resources for oppurtunity to be verified
class Verify extends StatelessWidget {
  
  //Clarify routing for main application
  Verify( { super.key } );
  static const String route = '/verify';

  //Get the query strem of resources who have not yet been verified
  final Stream<QuerySnapshot> resources = FirebaseFirestore.instance.collection('resources').where('verified', isEqualTo: false ).snapshots();
  CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');

  //Once verified, update current doc verification to true
  Future<void> verifyResource( name ){
    return resourceCollection.doc( name.id ).update( {"verified": true } )
      .then( ( value ) => print( "Updated" ) )
      .catchError( (error) => print("Failed to update resource: $error" ) );
  }

  //Verification UI  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Resource'),
      ),
      body: 
          new Container(
              child: new Column(
                children: [
                  //Gather the data stream information
                  new Container(
                     padding: const EdgeInsets.symmetric( vertical: 10),
                     child: StreamBuilder<QuerySnapshot>(
                     stream: resources,
                     builder: (
                      BuildContext context,
                      AsyncSnapshot<QuerySnapshot> snapshot, 
                    ) {

                    //Check for firestore snapshot error
                    if( snapshot.hasError )
                    {
                      return Text("Something went wrong");
                    }
                    
                    //Check if connection is being made
                    if( snapshot.connectionState == ConnectionState.waiting )
                    {
                      return Text("Loading Resources From Dataabse");
                    }
                    
                    //Get the snapshot data
                    final data = snapshot.requireData;

                    //Return a list of the data, no data if size is 0
                    if( data.size != 0 )
                    {
                        //Return the list of data in ListView
                        return ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        itemCount: data.size,
                        itemBuilder: ( context, index ) {
                        return Container( 
                            padding: const EdgeInsets.symmetric( vertical: 20 ),
                            margin: const EdgeInsets.only(top: 30, right: 0, left: 0),
                            decoration: BoxDecoration(
                                        color: Colors.blue,
                                        boxShadow: [
                                        BoxShadow(
                                            color: Colors.grey,
                                            spreadRadius: 5,
                                            blurRadius: 7,
                                            offset: Offset(10.0, 10.0),
                                        )
                                      ]
                                    ),
                            child: 
                            new Stack(
                                children: [
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 10),
                                    margin: const EdgeInsets.only(top: 0, right: 0, left: 100),
                                    child: 
                                    Text("Title",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 10),
                                    margin: const EdgeInsets.only(top: 0, right: 0, left: 250),
                                    child: 
                                    Text("Type",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 10),
                                    margin: const EdgeInsets.only(top: 0, right: 0, left: 450),
                                    child: 
                                    Text("Reporting",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 10),
                                    margin: const EdgeInsets.only(top: 0, right: 0, left: 650),
                                    child: 
                                    Text("Responsiveness",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 10),
                                    margin: const EdgeInsets.only(top: 0, right: 0, left: 900),
                                    child: 
                                    Text("Location",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 10),
                                    margin: const EdgeInsets.only(top: 0, right: 0, left: 1100),
                                    child: 
                                    Text("Description",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 10),
                                    margin: const EdgeInsets.only(top: 0, right: 0, left: 1270),
                                    child: 
                                    Text("Date Added",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 0),
                                    margin: const EdgeInsets.only(top: 50, right: 0, left: 100),
                                    child: 
                                    Text( "${data.docs[ index ][ 'name' ]}",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),        
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 0),
                                    margin: const EdgeInsets.only(top: 50, right: 0, left: 250),
                                    child: 
                                    Text( "${data.docs[ index ][ 'name' ]}",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),       
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 0),
                                    margin: const EdgeInsets.only(top: 50, right: 0, left: 450),
                                    child: 
                                    Text( "${data.docs[ index ][ 'name' ]}",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 0),
                                    margin: const EdgeInsets.only(top: 50, right: 0, left: 650),
                                    child: 
                                    Text( "${data.docs[ index ][ 'name' ]}",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),                               
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 0),
                                    margin: const EdgeInsets.only(top: 50, right: 0, left: 900),
                                    child: 
                                    Text( "${data.docs[ index ][ 'name' ]}",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),                                  
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 0),
                                    margin: const EdgeInsets.only(top: 50, right: 0, left: 1100),
                                    child: 
                                    Text( "${data.docs[ index ][ 'name' ]}",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),                                 
                                ),
                                new Container(
                                    padding: const EdgeInsets.symmetric( vertical: 0),
                                    margin: const EdgeInsets.only(top: 50, right: 0, left: 1270),
                                    child: 
                                    Text( "${data.docs[ index ][ 'name' ]}",
                                    textAlign: TextAlign.left,
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        ),
                                    ),                                
                                ),
                                //Button onclick verify's resource                            
                                new Container(
                                    margin: const EdgeInsets.only(top: 20, right: 0, left: 5),
                                    child: 
                                    TextButton(
                                        style: ButtonStyle(
                                        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(18.0),
                                            side: BorderSide(color: Colors.white)
                                        )
                                        ),
                                        foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                                        ),
                                        onPressed: () { 
                                            verifyResource( data.docs[ index ]);
                                        },
                                        child: Text('Verify',
                                        style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        ),
                                        ),
                                    ),                            
                                ),
                                ],
                            ),
                        );
                       }
                    );
                  }
                  else
                  {
                    return Text("There are no resources to be verified");
                  }
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}