import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/createResource.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_app/model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:web_app/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:collection/collection.dart';

// Helper function to ensure visibility, ensure field exists and enter text
Future<void> enterText(
  WidgetTester tester, Key key, String text) async {
  final field = find.byKey(key);
  // check that widget is found
  expect(field, findsOneWidget); 

  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
}
// Helper function to ensure visibility, ensure field exists and tap
Future<void> tapButton(WidgetTester tester, {String? text, Key? key}) async {
  final field = text != null ? find.text(text) : find.byKey(key!);
  // check that widget is found  
  expect(field, findsOneWidget);

  await tester.ensureVisible(field);  
  await tester.pumpAndSettle();
  await tester.tap(field);
}
// Helper function to ensure visibility, ensure field exists and tap multiple buttons, provided as a list of strings
Future<void> tapMultiple(WidgetTester tester, List<String> options) async {
  for (var option in options) {
    Finder field = find.text(option);
    // check that widget is found
    expect(field, findsOneWidget);

    await tester.ensureVisible(field);  
    await tester.pumpAndSettle();
    await tester.tap(field);
  }
}

// Variables to hold resource data
final String _testResourceType = Resource.resourceTypeLabels.values.first;
final String _testName = 'Automatic Test Resource';
final String _location = 'http://example.com/';
final String _testAddress = '1900 S Knoles Dr';
final String _testBuilding = '#1';
final String _testCity = 'Flagstaff';
final String _testState = 'AZ';
final String _testZipcode = '86001';
final String _testPhoneNumber = '555-1234';
final String _testDescription = 'This is a test resource description';
final List<String> _testTagline = ['testTag1'];
final List<String> _privacyOptions = [Resource.privacyLabels.values.first, Resource.privacyLabels.values.last];
final List<String> _costOptions = [Resource.costLabels.values.first, Resource.costLabels.values.last];
final List<String> _healthFocusOptions = [Resource.healthFocusLabels.values.first, Resource.healthFocusLabels.values.last];
final String _culturalResponsiveness = Resource.culturalResponsivenessLabels.values.first;
final String _ageRange = Resource.ageLabels.values.first;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and dotenv before running tests
  setUpAll(() async {
    print('Loading dotenv...');
    await dotenv.load(fileName: "env");
    print('Dotenv loaded.');
    print('Connecting to Firebase...');

    final username = dotenv.env['TEST_ADMIN_USERNAME'];
    final password = dotenv.env['TEST_ADMIN_PASSWORD'];

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('Firebase connected successfully.');
    // Sign in with a test user (make sure this user exists in your dev Firebase project)
    print('Signing in test user...');
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: username!,
      password: password!,
    );
    print('Test user signed in successfully.');
  });
  // Clean up after test
  tearDownAll(() async {
    // delete created resources
    final query = await FirebaseFirestore.instance
      .collection('resources')
      .where('name', isEqualTo: _testName)
      .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }

    // signout of firebase
    await FirebaseAuth.instance.signOut();
  });

  

  testWidgets('Test create resource flow', (tester) async {
    // render the CreateResource widget
    await tester.pumpWidget(
      MaterialApp(
        home: CreateResource(),
      ),
    );
    // wait for the widget to settle
    await tester.pumpAndSettle();

    // select the resource type from radio buttons
    await tapButton(tester, text:_testResourceType);

    // fill out text fields

    await enterText(tester, Key('nameTextField'), _testName); // name
    await enterText(tester, Key('locationTextField'), _location); // location (url)
    await enterText(tester, Key('addressTextField'), _testAddress); // address
    await enterText(tester, Key('buildingTextField'), _testBuilding); // building
    await enterText(tester, Key('cityTextField'), _testCity); // city
    await enterText(tester, Key('stateTextField'), _testState); // state
    await enterText(tester, Key('zipTextField'), _testZipcode); // zipcode
    await enterText(tester, Key('phoneTextField'), _testPhoneNumber); // phone number
    await enterText(tester, Key('descriptionTextField'), _testDescription); // description
    await enterText(tester, Key('tagsTextField'), _testTagline.join(', ')); // tagline

    // wait for the widget to settle
    await tester.pumpAndSettle();

    // select privacy options
    await tapMultiple(tester, _privacyOptions); // privacy
    await tester.pumpAndSettle();

    // select cost options
    await tapMultiple(tester, _costOptions); // cost
    await tester.pumpAndSettle();

    // select health focus options
    await tapMultiple(tester, _healthFocusOptions); // health focus
    await tester.pumpAndSettle();

    // select cultural responsiveness level
    await tapButton(tester, text: _culturalResponsiveness);
    await tester.pumpAndSettle();

    // select age range from dropdown
    await tapButton(tester, key: Key('ageRangeDropdown'));
    await tester.pumpAndSettle();
    await tapButton(tester, text: _ageRange);
    await tester.pumpAndSettle();

    // check auto-verification checkbox
    await tapButton(tester, key: Key('autoVerificationCheckbox'));
    await tester.pumpAndSettle();

    // submit the resource
    await tapButton(tester, key: Key('submitResourceButton'));
    await tester.pumpAndSettle();

    final query = await FirebaseFirestore.instance
        .collection('resources')
        .where('name', isEqualTo: _testName)
        .get();
    
    expect(query.docs.length, 1, reason: 'Resource created in Firestore');

    final Resource createdResource = 
                    Resource.fromJson(query.docs.first.data(), query.docs.first.id);

    // Validate the created resource fields
    expect(createdResource.name, _testName);
    expect(createdResource.location, _location);
    expect(createdResource.address, _testAddress);
    expect(createdResource.building, _testBuilding);
    expect(createdResource.city, _testCity);
    expect(createdResource.state, _testState);
    expect(createdResource.zipcode, _testZipcode);
    expect(createdResource.phoneNumber, _testPhoneNumber);
    expect(createdResource.description, _testDescription);
    expect(createdResource.resourceType, _testResourceType);
    expect(createdResource.culturalResponsiveness, Resource.culturalResponsivenessLabels.keys.first);
    expect(createdResource.agerange, Resource.ageLabels.keys.first);

    // Validate list entries
    expect(_privacyOptions.join(', ') , createdResource.privacyLabel);
    expect(_costOptions.join(', '), createdResource.costLabel);
    expect(_healthFocusOptions.join(', '), createdResource.healthFocusLabel);


  });

}



