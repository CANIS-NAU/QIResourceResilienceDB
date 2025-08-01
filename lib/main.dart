//Package imports
import 'package:flutter/material.dart';
import 'package:web_app/top10resources.dart';
import 'firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:timezone/browser.dart' as tz;
import 'package:web_app/model.dart';

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
        '/reviewresource' :  ( context ) => ReviewResource(resourceData: ModalRoute.of(context)!.settings.arguments as Resource),
        '/top10resources' : (context) => Top10Resources(),
      },
      theme: ThemeData(
        primaryColor: Color.fromARGB(255, 0, 96, 190),
        primaryColorDark: Color.fromARGB(255, 0, 82, 162),
        primaryColorLight: Color.fromARGB(255, 0, 110, 219),
        focusColor: Color.fromARGB(255, 204, 204, 204),
        hoverColor: Color.fromARGB(255, 204, 204, 204),
        appBarTheme: AppBarTheme(
          color: Color.fromARGB(255, 0, 96, 190),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return Color.fromARGB(255, 0, 82, 162);
              } else if (states.contains(MaterialState.hovered)) {
                return Color.fromARGB(255, 0, 82, 162);
              } else if (states.contains(MaterialState.focused)) {
                return Color.fromARGB(255, 0, 82, 162);
              }
              return Color.fromARGB(255, 0, 96, 190);
            }),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
          foregroundColor: MaterialStateProperty.all<Color>(Color(0xFF0060BE)),
          backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.pressed)) {
              return Color.fromARGB(255, 204, 204, 204);
            } else if (states.contains(MaterialState.hovered)) {
              return Color.fromARGB(255, 204, 204, 204);
            } else if (states.contains(MaterialState.focused)) {
              return Color.fromARGB(255, 204, 204, 204);
            }
            return Colors.transparent;
          }),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all<Color>(Color(0xFF0060BE)),
            backgroundColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
              if (states.contains(MaterialState.pressed)) {
                return Color.fromARGB(255, 204, 204, 204);
              } else if (states.contains(MaterialState.hovered)) {
                return Color.fromARGB(255, 204, 204, 204);
              } else if (states.contains(MaterialState.focused)) {
                return Color.fromARGB(255, 204, 204, 204);
              }
              return Colors.transparent;
            }),
          ),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.grey,
          selectedColor: Color(0xFF0060BE),
          showCheckmark: true,
          checkmarkColor: Colors.white
        ),
        radioTheme: RadioThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Color(0xFF0060BE);
            }
            return Colors.grey;
          }),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
            if (states.contains(MaterialState.selected)) {
              return Color(0xFF0060BE);
            }
            return Colors.grey;
          }),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Color(0xFF0060BE), width: 2),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey),
          ),
        ),
      ),
      home: const MyHomePage(),
    );
  }
}

