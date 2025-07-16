import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Register extends StatefulWidget {
    Register({ super.key });

    @override
    _RegisterState createState() => _RegisterState();
}
class _RegisterState extends State<Register> {
    static const String route = '/register';

    FirebaseAuth auth = FirebaseAuth.instance;

    String email = "";
    String password = "";
    String role = "";

    List<String> userRoles = ["admin", "manager"];

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

                        //Success
                        if( response.statusCode == 200 ) 
                        {
                            // Success
                            showAlertDialog( context, "User successfully created" );

                            /*
                            Map<String, dynamic> userCredentials = jsonDecode( response.body );

                            userCredentials = userCredentials['data'];

                            String uid = userCredentials['uid'];

                            print( uid );

                            User? newUser = await FirebaseAuth.instance.userChanges().firstWhere( ( user ) => user?.uid == uid );

                            print( newUser );

                            if( newUser != null )
                            {
                                newUser.sendEmailVerification();

                                print("Email Sent");
                            }
                            else
                            {
                                print("NULL");
                            }
                            */

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
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              splashRadius: 20.0,
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
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
                  width: windowSize.maxWidth / 2,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  margin: EdgeInsets.only(
                      top: 250,
                      right: windowSize.maxWidth / 3,
                      left: windowSize.maxWidth / 3),
                  // creates a drop down with options for user roles
                  child: Stack(
                    children: [
                      DropdownButtonFormField<String>(
                        // value: role,
                        onChanged: (value) {
                          setState(() {
                            role = value!;
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: 'Role',
                        ),
                        items: [
                          DropdownMenuItem<String>(
                            value: 'admin',
                            child: Text('admin'),
                          ),
                          DropdownMenuItem<String>(
                            value: 'manager',
                            child: Text('manager'),
                          ),
                        ],
                      ),
                    ],
                  )
                    ),
                  new Container(
                      padding: EdgeInsets.all(8.0),
                      alignment: Alignment.center,
                      child: ElevatedButton(
                        child: Padding(padding: const EdgeInsets.all(12),
                            child: Text('Register', style: TextStyle(fontSize: 14),)),
                        style: ButtonStyle(
                            shape:
                                MaterialStateProperty.all<RoundedRectangleBorder>(
                                    RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18.0),
                        ))),
                        onPressed: () {
                          registerUser(email, password, role, context);
                        },
                      )),
            ],
            ),
        );
        }
        ),
     );
    }
}
