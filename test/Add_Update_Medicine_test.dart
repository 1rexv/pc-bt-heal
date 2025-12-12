import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_database_mocks/firebase_database_mocks.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pc_bt_heal/AddUpdateMedicinePage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Need a mock instance accessible by reference for data injection
  late MockFirebaseDatabase mockDb;

  group('AddUpdateMedicinePage widget tests', () {
    late MockFirebaseAuth mockAuth;

    setUp(() async {
      final user = MockUser(
        isAnonymous: false,
        uid: 'doctor123',
        email: 'doctor@example.com',
        displayName: 'Dr. Tester',
      );
      mockAuth = MockFirebaseAuth(mockUser: user);
      mockDb = MockFirebaseDatabase();

      final initialData = <String, dynamic>{
        'appointments': {},
        'medicines': {},
        'patientNotifications': {},
      };
      await mockDb.ref().set(initialData);
    });

    testWidgets('shows validation snackbar when required fields are missing',
            (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: AddUpdateMedicinePage(
              ),
            ),
          );

          await tester.pumpAndSettle();

          final submitButton = find.byKey(const Key('submitButton'));
          await tester.tap(submitButton);
          await tester.pumpAndSettle();

          expect(find.text('Please fill in all required fields'), findsOneWidget);
        });

    testWidgets('adds new medicine and shows success snackbar',
            (WidgetTester tester) async {
          final appointmentId = 'appt1';
          final appointmentData = {
            appointmentId: {
              'doctorEmail': 'doctor@example.com',
              'patientEmail': 'patient@example.com',
              'patientName': 'Patient One',
              'status': 'accepted',
            }
          };


          await mockDb.ref().set({'appointments': appointmentData, 'medicines': {}});

          await tester.pumpWidget(
            MaterialApp(
              home: AddUpdateMedicinePage(
              ),
            ),
          );

          await tester.pumpAndSettle();

          final patientDropdown = find.byKey(const Key('patientDropdown'));
          await tester.tap(patientDropdown);
          await tester.pumpAndSettle();

          final patientItem = find.text('Patient One').last;
          await tester.tap(patientItem);
          await tester.pumpAndSettle();

          // Fill medicine fields
          await tester.enterText(find.byKey(const Key('nameField')), 'Azithromycin');
          await tester.enterText(find.byKey(const Key('dosageField')), '500mg once daily');
          await tester.enterText(find.byKey(const Key('durationField')), '5');


          await tester.tap(find.byKey(const Key('submitButton')));
          await tester.pumpAndSettle();

          expect(find.text('Medicine added successfully!'), findsOneWidget);

          final medicinesEvent = await mockDb.ref('medicines').once();
          final medicinesValue = medicinesEvent.snapshot.value as Map<Object?, Object?>?;
          expect(medicinesValue, isNotNull);
          expect(medicinesValue!.length, 1);

          final notifEvent = await mockDb.ref('patientNotifications').once();
          final notifValue = notifEvent.snapshot.value as Map<Object?, Object?>?;
          expect(notifValue, isNotNull);
          expect(notifValue!.length, 1);
        });
  });
}