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

  Future<void> deleteResource( name ){
      return resourceCollection.doc( name.id ).delete()
          .then( ( value ) => print( "Resource Delete" ) )
          .catchError( (error) => print("Failed to delete resource: $error" ) );
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
              child: SingleChildScrollView(
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
                          return Container(
                          height: 500,
                          child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                            child: ListView.builder(
                                scrollDirection: Axis.vertical,
                                shrinkWrap: true,
                                itemCount: data.size,
                                itemBuilder: (context, index) {
                                  return Container(
                                      height: 100,
                                    // create each resource card
                                      child: Card(
                                        color: Colors.white,
                                        elevation: 4,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(0))
                                        ),
                                        child: ListTile(
                                            contentPadding: EdgeInsets.symmetric(
                                                vertical: 10.0,
                                                horizontal: 30.0),
                                            dense: false,
                                            title: SizedBox(width: index == 0? 95:80,
                                                child: Text('${data.docs[index]['name']}',
                                                overflow: TextOverflow.visible,
                                                softWrap: true,
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25))
                                            ),
                                            subtitle: SizedBox( width: 80,
                                                child: Text('Description: ${data.docs[ index ][ 'description' ]}',
                                                    overflow: TextOverflow.visible,
                                                    softWrap: true,
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                TextButton(
                                                  style: ButtonStyle(
                                                    shape: MaterialStateProperty.all<
                                                            RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(18.0),
                                                            side: BorderSide(
                                                                color:
                                                                    Colors.blue))),
                                                    foregroundColor:
                                                        MaterialStateProperty.all<
                                                            Color>(Colors.black),
                                                  ),
                                                  onPressed: () {
                                                    Navigator.pushNamed(context, '/reviewresource',
                                                      arguments: data.docs[index]);
                                                  },
                                                  child: Text(
                                                    'Review',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                                SizedBox(width: 10),
                                                TextButton(
                                                  style: ButtonStyle(
                                                    shape: MaterialStateProperty.all<
                                                            RoundedRectangleBorder>(
                                                        RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(18.0),
                                                            side: BorderSide(
                                                                color:
                                                                    Colors.blue))),
                                                    foregroundColor:
                                                        MaterialStateProperty.all<
                                                            Color>(Colors.black),
                                                  ),
                                                  onPressed: () {
                                                    deleteResource(
                                                        data.docs[index]);
                                                  },
                                                  child: Icon(
                                                    Icons.delete_outlined,
                                                    color: Colors.blue,
                                                    size: 18.0,
                                                  ),
                                                ),
                                              ]),
                                        ),
                                      ));
                                }),
                          ),
                        );
                      }
                      else {
                        return Text("There are no resources to be verified");
                      }
                    }
                ),
            ),
          ],
        ),
              ),
      ),
    );
  }
}