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

// Helper function to ensure visibility and enter text
Future<void> enterText(
  WidgetTester tester, Key key, String text) async {
  final field = find.byKey(key);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.enterText(field, text);
}
// Helper function to ensure visibility and tap
Future<void> tapButton(WidgetTester tester, {String? text, Key? key}) async {
  final field = text != null ? find.text(text) : find.byKey(key!);
  await tester.ensureVisible(field);
  await tester.pumpAndSettle();
  await tester.tap(field);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase and dotenv before running tests
  setUpAll(() async {
    print('Loading dotenv...');
    await dotenv.load(fileName: "env");
    print('Dotenv loaded.');
    print('Connecting to Firebase...');

    final username = dotenv.env['LOGIN_USERNAME'];
    final password = dotenv.env['LOGIN_PASS'];

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
    await tester.tap(find.text(_testResourceType));
    await tester.pumpAndSettle();

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
    await tapButton(tester, text: Resource.privacyLabels.values.first); // privacy
    await tester.pumpAndSettle();

    // select cost options
    await tapButton(tester, text: Resource.costLabels.values.first); // cost
    await tester.pumpAndSettle();

    // select health focus options
    await tapButton(tester, text: Resource.healthFocusLabels.values.first);
    await tester.pumpAndSettle();

    // select cultural responsiveness level
    await tapButton(tester, text: Resource.culturalResponsivenessLabels.values.first);
    await tester.pumpAndSettle();

    // select age range from dropdown
    await tapButton(tester, key: Key('ageRangeDropdown'));
    await tester.pumpAndSettle();
    await tapButton(tester, text: Resource.ageLabels.values.first);
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

    // Verify the created resource fields
    expect(createdResource.name, _testName);
    expect(createdResource.location, _location);
    expect(createdResource.address, _testAddress);
    expect(createdResource.building, _testBuilding);
    expect(createdResource.city, _testCity);
    expect(createdResource.state, _testState);
    expect(createdResource.zipcode, _testZipcode);
    expect(createdResource.phoneNumber, _testPhoneNumber);
    expect(createdResource.description, _testDescription);
    expect(createdResource.tagline, _testTagline);
    expect(createdResource.resourceType, _testResourceType);
    expect(createdResource.privacy, contains(Resource.privacyLabels.keys.first));
    expect(createdResource.cost, contains(Resource.costLabels.keys.first));
    expect(createdResource.healthFocus, contains(Resource.healthFocusLabels.keys.first));
    expect(createdResource.culturalResponsiveness, Resource.culturalResponsivenessLabels.keys.first);
    expect(createdResource.agerange, Resource.ageLabels.keys.first);

  });

}



