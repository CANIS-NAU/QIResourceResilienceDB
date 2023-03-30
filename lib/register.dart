import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class Register extends StatelessWidget
{
    Register( { super.key } );
    static const String route = '/register';

    FirebaseAuth auth = FirebaseAuth.instance;

    String email = "";
    String password = "";
    String role = "";

    showAlertDialog( BuildContext context, String statement ) {

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

    void registerUser( String email, String password, String role, BuildContext context ) async
    {
        try
        {
            final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: email,
                password: password
            );

            showAlertDialog( context, "Successfully created user");
        } 
        on FirebaseAuthException catch ( error ) 
        {
            switch( error.code )
            {
                case 'email-already-in-use':
                    showAlertDialog( context, "A user with that email already exists");
                    break;
                case 'invalid-email':
                    showAlertDialog( context, "Invalid email address");
                    break;
                case 'operation-not-allowed':
                    showAlertDialog( context, "Registration disabled. Contact tech team");
                    break;
                case 'weak-password':
                    showAlertDialog( context, "Too weak of a password");
                    break;
            }
        }
    }

    Widget build( BuildContext context )
    {
      return Scaffold(
        appBar: AppBar(
            title: const Text('Register'),
        ),
        body: LayoutBuilder( builder: ( context, windowSize ) {
            return Container(
            child: new Stack(
                children : [
                    new Container(
                        height: windowSize.maxHeight / 2,
                        width: windowSize.maxWidth / 2,
                        padding: const EdgeInsets.symmetric( vertical: 20 ),
                        margin: EdgeInsets.only( top: 50, right: windowSize.maxWidth / 3, left: windowSize.maxWidth / 3 ),
                        child:
                            TextField(
                                obscureText: false,
                                decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Email' ),
                                onChanged: ( text )
                                {
                                    email = text;
                                },
                            ),
                    ),
                    new Container(
                        height: windowSize.maxHeight / 2,
                        width:  windowSize.maxWidth / 2,
                        padding: const EdgeInsets.symmetric( vertical: 20),
                        margin: EdgeInsets.only( top: 150, right: windowSize.maxWidth / 3, left: windowSize.maxWidth / 3 ),
                        child:
                            TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Password' ),
                                onChanged: ( text )
                                {
                                    password = text;
                                },
                            ),
                    ),
                    new Container(
                        height: windowSize.maxHeight / 2,
                        width:  windowSize.maxWidth / 2,
                        padding: const EdgeInsets.symmetric( vertical: 20),
                        margin: EdgeInsets.only( top: 250, right: windowSize.maxWidth / 3, left: windowSize.maxWidth / 3 ),
                        child:
                            TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Role' ),
                                onChanged: ( text )
                                {
                                    role = text;
                                },
                            ),
                    ),
                    new Container(
                        height: windowSize.maxHeight / 10,
                        width: windowSize.maxWidth / 5,
                        padding: const EdgeInsets.symmetric( vertical: 20 ),
                        margin: EdgeInsets.only( top: 350, right: windowSize.maxWidth / 2.5, left: windowSize.maxWidth / 2.5 ),
                        child:
                            TextButton(
                                style: ButtonStyle(
                                    foregroundColor: MaterialStateProperty.all<Color>( Colors.white ),
                                    backgroundColor: MaterialStateProperty.all<Color>( Colors.blue ),
                                    shape: MaterialStateProperty.all<RoundedRectangleBorder>(
                                        RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular( 18.0 ),
                                        side: BorderSide( color: Colors.blue )
                                    )
                                )
                                ), 
                                onPressed: () { 
                                    registerUser( email, password, role, context );
                                },
                                child: Text('Register'),
                        )
                    ),
                ],
            ),
        );
        }
        ),
     );
    }
}