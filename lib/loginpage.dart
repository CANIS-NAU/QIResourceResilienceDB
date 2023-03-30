//Package imports
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class Login extends StatelessWidget
{

  Login( { super.key } );
  static const String route = '/login';

  String email = "";
  String password = "";

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


  void login( String email, String password, BuildContext context ) async
  {
    try 
    {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password
      );

      User? user = credential.user;

      if( user != null )
      {
        IdTokenResult? userToken = await user?.getIdTokenResult();

        Map<String, dynamic>? claims = userToken?.claims;

        if( claims != null )
        {
          if( !claims['admin'] && !claims['manager'] )
          {
            showAlertDialog( context, "You don't have the authority to login on this platform" );
          }
          else
          {
            Navigator.pushNamed( context, '/home' );  
          }
        }
        else
        {
          showAlertDialog( context, "You don't have the authority to login on this platform" );
        }
      }
    } 
    on FirebaseAuthException catch ( error ) {

      if ( error.code == 'user-not-found' )
      {
        showAlertDialog( context, "No user with that email exists" );
      } 
      else if( error.code == 'wrong-password' ) 
      {
        showAlertDialog( context, "Incorrect password for the user with that email" );
      }
    }
  }

  @override
  Widget build( BuildContext context ) 
  {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
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
                    height: windowSize.maxHeight / 10,
                    width: windowSize.maxWidth / 5,
                    padding: const EdgeInsets.symmetric( vertical: 20 ),
                    margin: EdgeInsets.only( top: 250, right: windowSize.maxWidth / 2.5, left: windowSize.maxWidth / 2.5 ),
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
                                //Login function to return bool and check if login sucess
                                login( email, password, context );
                            },
                            child: Text('Login'),
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