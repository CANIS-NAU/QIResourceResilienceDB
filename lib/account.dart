import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class Account extends StatelessWidget
{
  Account( { super.key } );
  static const String route = '/account';

  String pass = '';
  String newPass = '';
  String reenter = '';

  void signoutUser() async
  {
    await FirebaseAuth.instance.signOut();
  }

  showAlertDialog( BuildContext context, String statement, bool success ) 
  {

    // set up the button
    Widget okButton = TextButton(
      child: Text( "OK" ),
      onPressed: () {
        Navigator.pop( context );

        if( success )
        {
          signoutUser();
          Navigator.pushNamedAndRemoveUntil( context, '/home', (route) => false );
        }
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

  Future<void> changePassword( BuildContext context, String password, String newPassword, String reenteredPass ) async 
  {

    User? user = FirebaseAuth.instance.currentUser;

    if( user != null )
    {
      if( newPassword == '' || reenteredPass == '' || password == '' )
      {
        showAlertDialog( context, "None of the fields can be empty", false );
      }
      else
      {
        if( reenteredPass == newPassword )
        {
          String? email = user.email;

          if( email != null && password != null )
          {
            AuthCredential credential = EmailAuthProvider.credential(
              email: email,
              password: password,
            );

            // Re-authenticate the user
            await user.reauthenticateWithCredential( credential );
          }
          
          user.updatePassword( newPassword ).then( ( _ ) {
            showAlertDialog( context, "Password successfully changed. Please log back in with new password", true );
          }).catchError( ( error ) {
            switch( error )
            {
              case 'weak-password':
                showAlertDialog( context, "New password too weak", false );
                break;
              case 'requires-recent-login':
                showAlertDialog( context, "Needs a more recent login", false );
                break;
            }
          });
        }
        else
        {
          showAlertDialog( context, "Your new password and re-entered password do not match", false );
        }
      }
    }
  }

  Widget build( BuildContext context )
  {
    return Scaffold(
        appBar: AppBar(
            title: const Text('Account'),
        ),
        body: LayoutBuilder( builder: ( context, windowSize ) {
            return Container(
            child: new Stack(
                children : [
                    new Container(
                        height: windowSize.maxHeight / 2,
                        width:  windowSize.maxWidth / 2,
                        padding: const EdgeInsets.symmetric( vertical: 20),
                        margin: EdgeInsets.only( top: 50, right: windowSize.maxWidth / 3, left: windowSize.maxWidth / 3 ),
                        child:
                            TextField(
                                obscureText: true,
                                decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Current Password' ),
                                onChanged: ( text )
                                {
                                  pass = text;
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
                                labelText: 'New Password' ),
                                onChanged: ( text )
                                {
                                  newPass = text;
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
                                labelText: 'Re-enter New Password' ),
                                onChanged: ( text )
                                {
                                  reenter = text;
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
                                  changePassword( context, pass, newPass, reenter );
                                },
                                child: Text('Change Password'),
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