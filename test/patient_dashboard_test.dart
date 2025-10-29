import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pc_bt_heal/PatientDashboardPage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

// Generate mock classes for FirebaseDatabase and DatabaseReference
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDatabaseEvent extends Mock implements DatabaseEvent {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

@GenerateMocks([MockDatabaseReference])
void main() {
  late MockDatabaseReference mockRef;
  late MockDatabaseEvent mockEvent;
  late MockDataSnapshot mockSnapshot;

  setUp(() {
    mockRef = MockDatabaseReference();
    mockEvent = MockDatabaseEvent();
    mockSnapshot = MockDataSnapshot();
  });

  testWidgets('Automated search filters doctor list',
          (WidgetTester tester) async {
        // Mock Firebase data
        final fakeData = {
          'doc1': {
            'fullName': 'Sarah ali',
            'address': 'Muscat',
            'enabled': true,
          },
          'doc2': {
            'fullName': 'Ahmed Hassan',
            'address': 'Sohar',
            'enabled': true,
          },
        };

        // Simulate Firebase snapshot
        when(mockSnapshot.value).thenReturn(fakeData);
        when(mockEvent.snapshot).thenReturn(mockSnapshot);
        when(mockRef.onValue)
            .thenAnswer((_) => Stream.fromIterable([mockEvent]));

        // Build the widget
        await tester.pumpWidget(
          const MaterialApp(home: PatientDashboardPage()),
        );

        // Wait for doctors to load
        await tester.pumpAndSettle();

        // Verify both doctors initially appear
        expect(find.text('Dr. Sarah Johnson'), findsOneWidget);
        expect(find.text('Dr. Ahmed Hassan'), findsOneWidget);

        // Type "Sarah" into the search bar
        await tester.enterText(
            find.byType(TextField), 'Sarah');
        await tester.pumpAndSettle();

        // Verify filtered result
        expect(find.text('Dr. Sarah Johnson'), findsOneWidget);
        expect(find.text('Dr. Ahmed Hassan'), findsNothing);
      });
}
