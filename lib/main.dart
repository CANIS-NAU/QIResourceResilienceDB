//Package imports
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/browser.dart' as tz;

//Screen or class imports
import 'package:web_app/home.dart';
import 'package:web_app/verify.dart';
import 'package:web_app/createResource.dart';
import 'package:web_app/loginpage.dart';
import 'package:web_app/dashboard.dart';
import 'package:web_app/register.dart';
import 'package:web_app/account.dart';
import 'package:web_app/reviewResource.dart';
import 'package:web_app/inbox.dart';
import 'package:web_app/userManagement.dart';

//Main function
void main() async {
  await dotenv.load(fileName: "env");
  debugPrint("Loaded environment: ${dotenv.get('APP_ENV_NAME')}.");

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // TimeZone database initialization for browsers.
  await tz.initializeTimeZone('assets/packages/timezone/data/latest.tzf');

  runApp(const MyApp());
}

//Serves as the root of application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Resilience Resource Database",

      //Initial Route to home
      initialRoute: '/',

      //Declare app routes. New screen routes to be added here
      routes: {
        '/home': ( context ) => const MyHomePage(),
        '/verify': ( context ) => Verify(),
        '/createresource': ( context ) => CreateResource(),
        '/login': ( context ) => Login(),
        '/dashboard': ( context ) => Dashboard(),
        '/register': ( context ) => Register(),
        '/account': ( context ) => Account(),
        '/inbox': ( context ) => Inbox(),
        '/usermanagement': ( context ) => Manage(),
        '/reviewresource' :  ( context ) => ReviewResource(resourceData: ModalRoute.of(context)!.settings.arguments as QueryDocumentSnapshot),
      },
      theme: ThemeData(
        primaryColor: Color(0xFF0060BE),
        focusColor: Color(0xFF0CCCCCC),
        // hintColor: Color(0xFF0b1b1b1),
        hoverColor: Color(0xFF0CCCCCC),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all<Color>(Color(0xFF0060BE)),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Color(0xFF0060BE)),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

