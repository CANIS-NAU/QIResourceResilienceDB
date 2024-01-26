import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class Manage extends StatefulWidget {
  const Manage({super.key});

  @override
  State<Manage> createState() => _ManageState();
}

class _ManageState extends State<Manage> {
    showAlertDialog(BuildContext context, String statement) {
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

    @override
    Widget build(BuildContext context) {
      return FutureBuilder<List<dynamic>>(
        future: fetchFirebaseUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } 
          else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          }
          else if (snapshot.data == null || snapshot.data!.isEmpty) {
            return Text('No users found.');
          }
          else {
            List<dynamic> users = snapshot.data ?? [];
            return ListView.builder(
              itemCount: users.length,
              itemBuilder: (context, index) {
                return Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                    ),
                    clipBehavior: Clip.antiAliasWithSaveLayer,
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                        Container(
                            padding: const EdgeInsets.fromLTRB(15,15,15,0),
                            child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                                Center( 
                                child: RichText(
                                    text: 
                                        TextSpan(
                                        text: users[index]['email'] ?? "",
                                        style: TextStyle(fontSize: 24),
                                    children: <TextSpan>[
                                        TextSpan(
                                            text: " account is currently ",
                                            style: TextStyle(fontSize: 24),
                                        ),
                                        TextSpan(
                                            text: 
                                              users[index]['disabled'] 
                                                       ? "Disabled" : "Enabled",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                            ),
                                        ),
                                    ],
                                ),
                                )),
                                Container(height: 10),
                                Row(
                                children: <Widget>[
                                    const Spacer(),
                                    TextButton(
                                        style: TextButton.styleFrom(
                                            foregroundColor: Colors.transparent,
                                        ),
                                        child: const Text(
                                            "Enable/Disable",
                                            style: 
                                                  TextStyle(color: Colors.blue),
                                        ),
                                        onPressed: () {
                                          changeUserStatus(
                                                   context,users[index]['uid']);
                                        },
                                    ),
                                ],
                                ),
                            ],
                            ),
                        ),
                        Container(height: 5),
                        ],
                    ),
                );
              },
            );
          }
        },
      );
    }

    Future<List<dynamic>> fetchFirebaseUsers() async 
    {
      String? url = "http://127.0.0.1:5001/sunrise-f9b44/us-central1/handleWebSignUpRole/getUsers";
      User? admin = FirebaseAuth.instance.currentUser;
      if(admin != null)
      {
        IdTokenResult? adminToken = await admin?.getIdTokenResult();

        Map<String, dynamic>? claims = adminToken?.claims;

        if(claims != null)
        {
            final Map<String, dynamic> requestBody = {
                'token': adminToken?.token,
            };

            if(url != null)
            {
              final http.Response response = await http.post(
                  Uri.parse(url),
                  headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(requestBody),
              );

              if(response.statusCode == 200)
              {
                return json.decode( response.body )['Users'];
              }
              else
              {
                print(json.decode( response.body )['error']);
              }
            }
            else
            {
              print("Cannot find cloud function");
            }
        }
      }

      return [];
    }

    Future<void> changeUserStatus(context, String uid) async
    {
      String? url = "http://127.0.0.1:5001/sunrise-f9b44/us-central1/handleWebSignUpRole/updateAccountStatus";
      User? admin = FirebaseAuth.instance.currentUser;
      if(admin != null)
      {
        IdTokenResult? adminToken = await admin?.getIdTokenResult();

        Map<String, dynamic>? claims = adminToken?.claims;

        if(claims != null)
        {
            bool adminRole = claims['admin'];

            final Map<String, dynamic> requestBody = {
                'uid': uid,
                'token': adminToken?.token,
            };

            if(url != null)
            {
              final http.Response response = await http.post(
                  Uri.parse(url),
                  headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(requestBody),
              );

              if(response.statusCode == 200)
              {
                showAlertDialog(context,"Success: changed account status.");
              }
              else
              {
                showAlertDialog(context,"Error: changing account status.");
              }
            }
            else
            {
              print("Cannot find cloud function");
            }
        }
      }
    }
}