import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/createResource.dart';
import 'package:integration_test/integration_test.dart';
import 'package:web_app/model.dart';
import 'package:web_app/file_attachments.dart';

void main(){
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Variables to hold resource data
  final String _testResourceType = Resource.resourceTypeLabels.keys.first;
  final String _testName = 'Test Resource';
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
    await tester.enterText(find.byKey(Key('nameTextField')), _testName); // name
    await tester.enterText(find.byKey(Key('locationTextField')), _location); // location (url)
    await tester.enterText(find.byKey(Key('addressTextField')), _testAddress); // address
    await tester.enterText(find.byKey(Key('buildingTextField')), _testBuilding); // building
    await tester.enterText(find.byKey(Key('cityTextField')), _testCity); // city
    await tester.enterText(find.byKey(Key('stateTextField')), _testState); // state
    await tester.enterText(find.byKey(Key('zipcodeTextField')), _testZipcode); // zipcode
    await tester.enterText(find.byKey(Key('phoneNumberTextField')), _testPhoneNumber); // phone number
    await tester.enterText(find.byKey(Key('descriptionTextField')), _testDescription); // description
    await tester.enterText(find.byKey(Key('taglineTextField')), _testTagline.join(', ')); // tagline
    // wait for the widget to settle
    await tester.pumpAndSettle();

    // select privacy options
    await tester.tap(find.text(Resource.privacyLabels.values.first));
    await tester.pumpAndSettle();

    // select cost options
    await tester.tap(find.text(Resource.costLabels.values.first));
    await tester.pumpAndSettle();

    // select health focus options
    await tester.tap(find.text(Resource.healthFocusLabels.values.first));
    await tester.pumpAndSettle();

    // select cultural responsiveness level
    await tester.tap(find.text(Resource.culturalResponsivenessLabels.values.first));
    await tester.pumpAndSettle();

    // select age range from dropdown
    await tester.tap(find.byKey(Key('ageRangeDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text(Resource.ageLabels.values.first));
    await tester.pumpAndSettle();

    // check auto-verification checkbox
    await tester.tap(find.byKey(Key('autoVerificationCheckbox')));
    await tester.pumpAndSettle();

    // submit the resource
    await tester.tap(find.byKey(Key('submitResourceButton')));
    await tester.pumpAndSettle();
    /*
    // define fields for test resource
    final List<Attachment> _testAttachment = [
      Attachment(
        name: 'test.txt',
        fileSize: 123,
        mimeType: 'text/plain',
        url: 'https://example.com/test.txt',
      ),
    ];
    final DateTime now = DateTime.now();

    // create a test resource
    final testResource = Resource(
      address: '1900 S Knoles Dr',
      agerange: Resource.ageLabels.keys.first,
      attachments: _testAttachment,
      building: '#1',
      city: 'Flagstaff',
      cost: [Resource.costLabels.keys.first],
      createdBy: 'test@example.com',
      createdTime: now,
      culturalResponsiveness: Resource.culturalResponsivenessLabels.keys.first,
      dateAdded: "${now.month}/${now.day}/${now.year}",
      description: 'This is a test resource description',
      healthFocus: [Resource.healthFocusLabels.keys.first],
      isVisable: true,
      location: 'http://example.com/',
      name: 'Test Resource',
      phoneNumber: '555-1234',
      privacy: [Resource.privacyLabels.keys.first],
      resourceType: Resource.resourceTypeLabels.keys.first,
      state: 'AZ',
      schedule: null, // not event type so no schedule
      tagline: ['testTag1'],
      verified: true,
      zipcode: '86001',
    );*/





  });

}



