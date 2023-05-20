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

  showAlertDialog( BuildContext context, String statement, User? user ) 
  {
    // set up the button
    Widget okButton = TextButton(
      child: Text( "OK" ),
      onPressed: () {
        Navigator.pop( context );
      },
    );
    
    Widget verifyButton = TextButton(
      child: Text( "Send Verify Email" ),
      onPressed: () {
        //Send a verification to users email
        sendEmailVerif( user );

        //Pop context on screen
        Navigator.pop( context );

        //Show that an email sent to user
        showAlertDialog( context, "Sent verification to corresponding email. Check spam.", user );
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

    if( statement == "You have not verified your email" )
    {
      // set up the AlertDialog
      alert = AlertDialog(
        title: Text( "Alert" ),
        content: Text( statement ),
        actions: [
          okButton,
          verifyButton,
        ],
      );
    }

    //show the dialog
    showDialog(
      context: context,
      builder: ( BuildContext context ) {
        return alert;
      },
    );
  }

  void signoutUser() async
  {
    await FirebaseAuth.instance.signOut();
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
        if( user.emailVerified )
        {
          IdTokenResult? userToken = await user?.getIdTokenResult();

          Map<String, dynamic>? claims = userToken?.claims;

          if( claims != null )
          {
            if( !claims['admin'] && !claims['manager'] )
            {
              showAlertDialog( context, "You don't have the authority to login on this platform", user );
              
              //Technically the user is signed in but we dont want this
              signoutUser();
            }
            else
            {
              Navigator.pushNamedAndRemoveUntil( context, '/home', (route) => false ); 
            }
          }
          else
          {
            showAlertDialog( context, "You don't have the authority to login on this platform", user );
            signoutUser();
          }
        }
        else
        {
          showAlertDialog( context, "You have not verified your email", user );
        }
      }
    } 
    on FirebaseAuthException catch ( error )
    {
      switch( error.code )
      {
        case 'user-not-found':
          showAlertDialog( context, "No user with that email exists", null );
          break;
        case 'wrong-password': 
          showAlertDialog( context, "Incorrect password for the user with that email", null );
          break;
        case 'invalid-email':
          showAlertDialog( context, "Invalid email.", null );
          break;
        case 'user-disabled':
          showAlertDialog( context, "User disabled", null );
          break;
        default:
          showAlertDialog( context, "Something went wrong. Check that password is correct.", null );
          break;
      }
    }
  }

  Future< void > sendEmailVerif( User? user ) async
  {
    if( user != null )
    {
      if( !user.emailVerified )
      {
        await user.sendEmailVerification();
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