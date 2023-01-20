//Package imports
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class Login extends StatelessWidget
{
  Login( { super.key } );
  static const String route = '/login';

  String username = "";
  String password = "";


  void login( String username, String password )
  {
    //Login with user credentials

    //Route to dashboard
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
                            labelText: 'Username' ),
                            onChanged: ( text )
                            {
                                username = text;
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
                                login( username, password );
                                Navigator.pushNamed( context, '/dashboard' );
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