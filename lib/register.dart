import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_admin/firebase_admin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Register extends StatelessWidget
{
    Register( { super.key } );
    static const String route = '/register';

    FirebaseAuth auth = FirebaseAuth.instance;

    String email = "";
    String password = "";
    String role = "";

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

 Future<void> registerUser(
      String email, String password, String role, BuildContext context) async 
    {
        if( email != "" && password != "" && role != "" )
        {
            String displayStatement = "";

            String? url = dotenv.env['REGISTER_URL'];

            User? admin = FirebaseAuth.instance.currentUser;

            if( admin != null )
            {
                IdTokenResult? adminToken = await admin?.getIdTokenResult();

                Map<String, dynamic>? claims = adminToken?.claims;

                if( claims != null )
                {
                    bool adminRole = claims['admin'];

                    final Map<String, dynamic> requestBody = {
                        'adminToken': adminToken?.token,
                        'email': email,
                        'password': password,
                        'role': role,
                    };

                    if( url != null )
                    {
                        final http.Response response = await http.post(
                            Uri.parse( url ),
                            headers: <String, String>{
                            'Content-Type': 'application/json; charset=UTF-8',
                            },
                            body: jsonEncode( requestBody ),
                        );

                        if( response.statusCode == 200 ) 
                        {
                            // Success
                            showAlertDialog( context, "User successfully created" );
                        } 
                        else
                        {
                            Map<String, dynamic> errorSpecs = json.decode( response.body )['error'];

                            String errorMessage = errorSpecs['code'];
                        
                            switch( errorMessage )
                            {
                                case "auth/email-already-exists":
                                    displayStatement = "There is already a user with that email";
                                    break;
                                case "auth/invalid-email":
                                    displayStatement = "That is not a valid email adress";
                                    break;
                                case "auth/invalid-password":
                                    displayStatement = "The password is not strong enough( at least six character )";
                                    break;
                                default:
                                    displayStatement = "An error occured, please contact development team";
                                    break;
                            }

                            showAlertDialog( context, displayStatement );
                        }
                    }
                    else
                    {
                        displayStatement = "Something went wrong. Please contact tech team.";
                        showAlertDialog( context, displayStatement );                       
                    }
                    
                }
                else
                {
                    displayStatement = "Something went wrong. Please contact tech team.";
                    showAlertDialog( context, displayStatement );
                }
            }
            else
            {
                displayStatement = "You do not have the authority to do that";
                showAlertDialog( context, displayStatement );     
            }
        }
        else
        {
            showAlertDialog( context, "Cannot create user. A required field is empty" );
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
