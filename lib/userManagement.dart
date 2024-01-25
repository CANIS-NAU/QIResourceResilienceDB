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
  const Manage( { super.key } );

  @override
  State<Manage> createState() => _ManageState();
}

class _ManageState extends State<Manage>{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users'),
      ),
      body: Container(
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
              fetchFirebaseUsers();
          },
          child: Text('Get Users'),
  )
      )
    ); 
    }

    Future<void> fetchFirebaseUsers() async 
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
                print(json.decode( response.body )['Users']);
              }
              else
              {
                print(response.body);
                print(json.decode( response.body )['error']);
              }
            }
            else
            {
              print("Cannot find cloud function");
            }
        }
      }
    }

    Future<void> changeUserStatus(String uid) async
    {
      String? url = dotenv.env['CHANGE_STATUS'];
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
                print("Success: changed account status.");
              }
              else
              {
                print("Error: changing account status.");
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