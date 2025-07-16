import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class Manage extends StatefulWidget {
  const Manage({super.key});
  static const String route = '/usermanagement';

  @override
  State<Manage> createState() => _ManageState();
}

class _ManageState extends State<Manage> {
    showAlertDialog(BuildContext context, String statement) {
        // set up the button
        Widget okButton = TextButton(
        child: Text("OK"),
        onPressed: () {
            Navigator.pop( context );
            setState((){});
        },
        );

        // set up the AlertDialog
        AlertDialog alert = AlertDialog(
        title: Text("Status Alert"),
        content: Text( statement ),
        actions: [
            okButton,
        ],
        );

        //show the dialog
        showDialog(
        context: context,
        builder: (BuildContext context) {
            return alert;
        },
        );
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Manage'),
          leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          splashRadius: 20.0,
          onPressed: () {
            Navigator.of(context).pop();
          },
          )
        ),
        body: FutureBuilder<List<dynamic>>(
          future: fetchFirebaseUsers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: Text("Loading Users"));
            } 
            else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } 
            else if (snapshot.data == null || snapshot.data!.isEmpty) {
              return Center(child: Text('No users found.'));
            } 
            else {
              List<dynamic> users = snapshot.data ?? [];
              String currentState = "";
              return Center(
                child: ListView.builder(
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
                            padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Center(
                                  child: RichText(
                                    text: TextSpan(
                                      text: users[index]['email'] ?? "",
                                      style: TextStyle(fontSize: 24),
                                      children: <TextSpan>[
                                        TextSpan(
                                          text: " account is currently ",
                                          style: TextStyle(fontSize: 24),
                                        ),
                                        TextSpan(
                                          text: users[index]['disabled']
                                              ? "Disabled"
                                              : "Enabled",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(height: 10),
                                Row(
                                  children: <Widget>[
                                    const Spacer(),
                                    TextButton(
                                      child: Text(
                                        users[index]['disabled'] ? "Enable" : 
                                        "Disable",
                                        style: TextStyle(color: Theme.of(context).primaryColor),
                                      ),
                                      onPressed: () {
                                        String suc = 
                                      "Successfully changed account status to ";
                                        String fail = 
                                           "Failure changed account status to ";
                                        String statusSubStr; 
                                        String stringStatus = 
                                              users[index]['disabled'] ?
                                                         "Enabled" : "Disabled";
                                        changeUserStatus(context, 
                                                            users[index]['uid'],
                                                             stringStatus).then(
                                                                 (bool status) {
                                                              if(status) {
                                                                statusSubStr = 
                                                                            suc;
                                                              }
                                                              else {
                                                                statusSubStr =
                                                                           fail;
                                                              }
                                                              showAlertDialog(
                                                                context,
                                                                statusSubStr +
                                                                  stringStatus);
                                                             });
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
                ),
              );
            }
          },
        ),
      );
    }

    Future<List<dynamic>> fetchFirebaseUsers() async {
      String? url = dotenv.env['GET_USERS'];
      User? admin = FirebaseAuth.instance.currentUser;
      if(admin != null) {
        IdTokenResult? adminToken = await admin?.getIdTokenResult();

        Map<String, dynamic>? claims = adminToken?.claims;

        if(claims != null) {
            final Map<String, dynamic> requestBody = {
                'adminToken': adminToken?.token,
            };

            if(url != null) {
              final http.Response response = await http.post(
                  Uri.parse(url),
                  headers: <String, String>{
                  'Content-Type': 'application/json; charset=UTF-8',
                  },
                  body: jsonEncode(requestBody),
              );

          if (response.statusCode == 200) {
            return json.decode(response.body)['Users'];
              }
            }
        }
      }

      return [];
    }

    Future<bool> changeUserStatus(context, String uid, String newStatus) async {
      bool returnStatus = false;
      String? url = dotenv.env['CHANGE_STATUS'];
      User? admin = FirebaseAuth.instance.currentUser;
      if(admin != null) {
        IdTokenResult? adminToken = await admin?.getIdTokenResult();

        Map<String, dynamic>? claims = adminToken?.claims;

        if(claims != null) {
          bool adminRole = claims['admin'];

          final Map<String, dynamic> requestBody = {
                'uid': uid,
                'adminToken': adminToken?.token,
          };

          if(url != null) {
            final http.Response response = await http.post(
                Uri.parse(url),
                headers: <String, String>{
                'Content-Type': 'application/json; charset=UTF-8',
                },
                body: jsonEncode(requestBody),
            );

            if(response.statusCode == 200) {
              returnStatus = true;
            }
          }
        }
      }
      return returnStatus;
    }
}