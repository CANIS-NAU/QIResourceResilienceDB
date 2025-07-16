//Package imports
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:web_app/model.dart';
import 'package:web_app/util.dart';

//Shows unverified resources for opportunity to be verified
class Verify extends StatelessWidget {

  //Clarify routing for main application
  Verify( { super.key } );
  static const String route = '/verify';

  //Get the query stream of resources who have not yet been verified
  final Stream<QuerySnapshot> resources = FirebaseFirestore.instance.collection('resources').where('verified', isEqualTo: false ).snapshots();
  CollectionReference resourceCollection = FirebaseFirestore.instance.collection('resources');

  showAlertDialog( BuildContext context, String statement ) 
  {
        // set up the button
        Widget okButton = TextButton(
        child: Text( "OK" ),
        onPressed: () {
            Navigator.pop( context );
        },
        );

        // set up the AlertDialog
        AlertDialog alert = AlertDialog(
        title: Text( "Alert" ),
        content: Text( statement ),
        actions: [
            okButton,
        ],
        );

        //show the dialog
        showDialog(
        context: context,
        builder: ( BuildContext context ) {
            return alert;
        },
        );
  }

  void reviewResource( Resource resource, BuildContext context )
  {
    User? user = FirebaseAuth.instance.currentUser;
    if( user != null )
    {
        if( user.email !=  resource.createdBy)
        {  
          Navigator.pushNamed(context, '/reviewresource',
            arguments: resource );
        }
        else
        {
            showAlertDialog( context, "Cannot review your own submission" );
        }
    }
  }

  // function to deny/delete a resource
  Future<void> deleteResource(BuildContext context, resource) async {
    try {
      await resourceCollection.doc(resource.id).delete();
      await showMessageDialog(
        context,
        title:'Success',
        message: "Resource has been denied."
      );
    } catch (e) {
      await showMessageDialog(
        context,
        title: 'Error',
        message: "Failed to delete resource: $e",
      );
    }
  }

  //Verification UI  
  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 800;
    final User? currentUser = FirebaseAuth.instance.currentUser;
    final parentContext = context;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Resource'),
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
              child: SingleChildScrollView(
                child: new Column(
                  children: [
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
                      final docs = data.docs.toList();

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
                                                overflow: TextOverflow.clip,
                                                softWrap: true,
                                                maxLines: isSmallScreen ? 2 : null,
                                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 18 : 25))
                                            ),
                                            subtitle: SizedBox( width: 80,
                                                child: Text('Description: ${data.docs[ index ][ 'description' ]}',
                                                    overflow: TextOverflow.ellipsis,
                                                    maxLines: 2,
                                                    softWrap: true,
                                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: isSmallScreen ? 12 : 14)),
                                            ),
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // if a resource was created by the current user, show created by you
                                                currentUser != null && currentUser.email == data.docs[index]['createdBy']
                                                    ? Text(
                                                  'Created by you',
                                                  style: TextStyle(
                                                    color: Colors.green,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                )
                                                    : SizedBox(),
                                                SizedBox(width: 10),
                                                // if the resource was created by the current user, disable the review button
                                                currentUser != null && currentUser.email == data.docs[index]['createdBy']
                                                    ? TextButton(
                                                  style: ButtonStyle(
                                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                      RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(18.0),
                                                        side: BorderSide(color: Colors.grey), // Make the button grey
                                                      ),
                                                    ),
                                                    foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                                                  ),
                                                  onPressed: null, // set onPressed to null to make the button unpressable
                                                  child: Text(
                                                    'Review',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                )
                                                // otherwise, show the review button
                                                    : TextButton(
                                                  style: ButtonStyle(
                                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                                      RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(18.0),
                                                        side: BorderSide(color: Theme.of(context).primaryColor),
                                                      ),
                                                    ),
                                                    foregroundColor: MaterialStateProperty.all<Color>(Colors.black),
                                                  ),
                                                  onPressed: () {
                                                    reviewResource(
                                                      Resource.fromJson(docs[index].data() as Map<String, dynamic>, data.docs[index].id),
                                                      context,
                                                    );
                                                  },
                                                  child: Text(
                                                    'Review',
                                                    style: TextStyle(
                                                      color: Theme.of(context).primaryColor,
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
                                                                Theme.of(context).primaryColor))),
                                                    foregroundColor:
                                                        MaterialStateProperty.all<
                                                            Color>(Colors.black),
                                                  ),
                                                  onPressed: () {
                                                    deleteResource(parentContext, docs[index]);
                                                  },
                                                  child: Icon(
                                                    Icons.delete_outlined,
                                                    color: Theme.of(context).primaryColor,
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
