import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:appstinence/main.dart';   // Main app entry point
import 'package:appstinence/screens/home_screen.dart';
import 'package:appstinence/screens/onboarding_screen.dart';

void main() {
  group('Appstinence UI Tests', () {
    testWidgets('Onboarding screen displays core features and continue button', (WidgetTester tester) async {
      // Build the OnboardingScreen
      await tester.pumpWidget(const MaterialApp(home: OnboardingScreen()));

      // Verify onboarding content
      expect(find.text('Quick Setup:'), findsOneWidget);
      expect(find.text('Explain Core Features'), findsOneWidget);

      // Verify continue button is present
      expect(find.text('Continue'), findsOneWidget);

      // Tap the 'Continue' button
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Since navigation is handled in the main app, this won't change screens here.
      // However, in an integrated test (with Navigator), the tester would confirm navigation.
    });

    testWidgets('Home screen displays key sections with navigation icons', (WidgetTester tester) async {
      // Build the HomeScreen
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

      // Verify key text
      expect(find.text('Take Control of Your Time'), findsOneWidget);

      // Verify navigation icons and labels
      expect(find.text('Blocks'), findsOneWidget);
      expect(find.text('Block an App'), findsOneWidget);
      expect(find.text('Challenges'), findsOneWidget);

      // Verify icons exist
      expect(find.byIcon(Icons.block), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    });

    testWidgets('App navigation from onboarding to home screen works', (WidgetTester tester) async {
      // Build entire app to test navigation
      await tester.pumpWidget(const AppstinenceApp());

      // Verify Onboarding screen is the initial screen
      expect(find.text('Quick Setup:'), findsOneWidget);

      // Tap continue to navigate to home
      await tester.tap(find.text('Continue'));
      await tester.pumpAndSettle();

      // Confirm the HomeScreen is displayed after navigation
      expect(find.text('Take Control of Your Time'), findsOneWidget);
      expect(find.text('Blocks'), findsOneWidget);
      expect(find.text('Block an App'), findsOneWidget);
      expect(find.text('Challenges'), findsOneWidget);
    });
  });
}
