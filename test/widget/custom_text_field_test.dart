import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:web_app/createResource.dart';

void main(){
    group('Text field container visiblity can be toggled', () {
        // Build our app and trigger a frame.
        testWidgets('Widget is visible when visibility is true', (tester) async {
          String textFieldLabel = 'Text Field Label';
          bool isTextFieldVisable = false;
          Widget textFieldContainer;

          // Create a text field container with the label and visibility set to true.
          isTextFieldVisable = true;
          textFieldContainer = CustomTextFieldContainer(
            label: textFieldLabel,
            isVisible: isTextFieldVisable,
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: textFieldContainer,
              ),
            ),
          );
          // Verify that the text field container label is displayed.
          final labelFinder = find.text(textFieldLabel);
          expect(labelFinder, findsOneWidget);
        });
        
        testWidgets('Widget is not visible when visibility is false', (tester) async {
          // Create a text field container with the label and visibility set to false.
          String textFieldLabel = 'Text Field Label';
          bool isTextFieldVisable = false;
          Widget textFieldContainer = CustomTextFieldContainer(
            label: textFieldLabel,
            isVisible: isTextFieldVisable,
          );
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: textFieldContainer,
              ),
            ),
          );
          // Verify that the text field container label is not displayed.
          final labelFinder = find.text(textFieldLabel);
          expect(labelFinder, findsNothing);
        });
    });
    
}