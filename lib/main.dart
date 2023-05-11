//Package imports
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

//Screen or class imports
import './home.dart';
import './verify.dart';
import './createResource.dart';
import './loginpage.dart';
import './dashboard.dart';
import './reviewResource.dart';

//Main fubction
void main() async  {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
     options: DefaultFirebaseOptions.currentPlatform
  );
  runApp( const MyApp() );
}

//Serves as the root of application 
class MyApp extends StatelessWidget {
  const MyApp( {super.key} );
  
  @override
  Widget build( BuildContext context ) {
    return MaterialApp(
      title: "Resource Web Page",

      //Initial Route to home 
      initialRoute: '/',

      //Declare app routes. New screen routes to be added here
      routes: {
        '/home': ( context ) => const MyHomePage(),
        '/verify': ( context ) => Verify(),
        '/createresource': ( context ) => CreateResource(),
        '/login': ( context ) => Login(),
        '/dashboard': ( context ) => Dashboard(),
        '/reviewresource' :  ( context ) => ReviewResource(resourceData: ModalRoute.of(context)!.settings.arguments as QueryDocumentSnapshot),
      },
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(),
    );
  }
}