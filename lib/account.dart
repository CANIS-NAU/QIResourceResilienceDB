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

  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          splashRadius: 20.0,
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      body: LayoutBuilder(
        builder: (context, windowSize) {
          final maxWidth = 600.0;
          final inputWidth =
              windowSize.maxWidth < maxWidth ? windowSize.maxWidth : maxWidth;
          return Center(
            child: Container(
              child: new Stack(
                children: [
                  Container(
                    width: inputWidth,
                    height: windowSize.maxHeight,
                    padding: const EdgeInsets.all(16),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SizedBox(height: 40),
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Current Password'),
                            onChanged: (text) {
                              pass = text;
                            },
                          ),
                          SizedBox(height: 20),
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'New Password'),
                            onChanged: (text) {
                              newPass = text;
                            },
                          ),
                          SizedBox(height: 20),
                          TextField(
                            obscureText: true,
                            decoration: InputDecoration(
                                border: OutlineInputBorder(),
                                labelText: 'Re-enter New Password'),
                            onChanged: (text) {
                              reenter = text;
                            },
                          ),
                          SizedBox(height: 30),
                          TextButton(
                            style: ButtonStyle(
                                foregroundColor:
                                    MaterialStateProperty.all<Color>(
                                        Colors.white),
                                backgroundColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.focused)) {
                                    return Theme.of(context).primaryColor.withOpacity(0.7);
                                  }
                                  return Theme.of(context).primaryColor;
                                }),
                                shape: MaterialStateProperty.all<
                                        RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(18.0),
                                        side: BorderSide(
                                            color: Theme.of(context).primaryColor)))),
                            onPressed: () {
                              changePassword(context, pass, newPass, reenter);
                            },
                            child: Text('Change Password'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}