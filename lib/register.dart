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

    void registerUser( String email, String password, String role, BuildContext context ) async
    {
        try
        {
            final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
                email: email,
                password: password
            );

        } 
        on FirebaseAuthException catch ( error ) 
        {
            print( error );
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