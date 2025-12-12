import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pc_bt_heal/ViewFeedbackPage.dart';

late MockFirebaseDatabase mockDbInstance;
late MockFirebaseAuth mockAuthInstance;

Future<void> setupMockFirebase(Map<String, dynamic> initialData) async {
  mockDbInstance = MockFirebaseDatabase();
  mockAuthInstance = MockFirebaseAuth();
  await mockDbInstance.ref().set(initialData);
}


void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ViewFeedbackPage tests', () {

    // 1. Test initial loading state
    testWidgets('shows CircularProgressIndicator initially', (WidgetTester tester) async {
      await setupMockFirebase({});
      await tester.pumpWidget(const MaterialApp(home: ViewFeedbackPage()));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pumpAndSettle();
    });

    // 2. Test when no feedback is found
    testWidgets('shows "No feedback found" when both nodes are empty', (WidgetTester tester) async {
      await setupMockFirebase({
        'feedback': {},
        'systemDoctorFeedback': {},
      });

      await tester.pumpWidget(const MaterialApp(home: ViewFeedbackPage()));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('No feedback found'), findsOneWidget);
    });

    // 3. Test successful loading and display of combined feedback
    testWidgets('loads and displays feedback from both patient and doctor nodes, sorted by date', (WidgetTester tester) async {
      final patientFeedbackTime = DateTime.now().millisecondsSinceEpoch - 100000;
      final doctorFeedbackTime = DateTime.now().millisecondsSinceEpoch; // Latest time

      final mockData = {
        'feedback': {
          'patientKey1': {
            'patientEmail': 'patient@test.com',
            'doctorName': 'Dr. Smith',
            'doctorFeedback': 'Good communication',
            'systemFeedback': 'App is simple',
            'rating': 4,
            'createdAt': patientFeedbackTime,
          },
        },
        'systemDoctorFeedback': {
          'doctorKey1': {
            'doctorName': 'Dr. Jones',
            'feedback': 'System needs dark mode.',
            'createdAt': doctorFeedbackTime,
            'doctorEmail': 'jones@example.com',
          },
        },
      };

      await setupMockFirebase(mockData);
      await tester.pumpWidget(const MaterialApp(home: ViewFeedbackPage()));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(Card), findsNWidgets(2));

      final firstTile = tester.widget<ListTile>(find.byType(ListTile).first);
      final secondTile = tester.widget<ListTile>(find.byType(ListTile).last);

      expect(find.descendant(of: find.byWidget(firstTile), matching: find.text('Doctor: Dr. Jones')), findsOneWidget);
      expect(find.descendant(of: find.byWidget(secondTile), matching: find.text('Patient: patient@test.com')), findsOneWidget);
      expect(find.textContaining('Date:'), findsNWidgets(2));
    });

    // 4. Test missing/default values for patient feedback
    testWidgets('handles missing fields in patient feedback gracefully', (WidgetTester tester) async {
      final mockData = {
        'feedback': {
          'patientKey2': {
            'createdAt': 1,
          },
        },
        'systemDoctorFeedback': {},
      };

      await setupMockFirebase(mockData); 

      await tester.pumpWidget(const MaterialApp(home: ViewFeedbackPage()));
      await tester.pumpAndSettle();

      // Verify defaults are applied
      expect(find.text('Patient: Unknown patient'), findsOneWidget);
      expect(find.textContaining('About Doctor: Unknown doctor'), findsOneWidget);
      expect(find.textContaining('Doctor feedback: -'), findsOneWidget);
      expect(find.textContaining('System feedback: -'), findsOneWidget);
      expect(find.textContaining('Rating: - / 5'), findsOneWidget);
    });
  });
}