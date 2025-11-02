import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pc_bt_heal/PatientDashboardPage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

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

  testWidgets('Automated search filters doctor name and address',
          (WidgetTester tester) async {
        final fakeData = {
          'doc1': {
            'fullName': 'Sarah Ali',
            'address': 'Muscat',
            'enabled': true,
          },
          'doc2': {
            'fullName': 'Ahmed Hassan',
            'address': 'Sohar',
            'enabled': true,
          },
        };

        //Simulate Firebase snapshot
        when(mockSnapshot.value).thenReturn(fakeData);
        when(mockEvent.snapshot).thenReturn(mockSnapshot);
        when(mockRef.onValue).thenAnswer((_) => Stream.fromIterable([mockEvent]));

        //Build the PatientDashboardPage
        await tester.pumpWidget(
          const MaterialApp(home: PatientDashboardPage()),
        );

        // Wait for doctors to load
        await tester.pumpAndSettle();

        // Verify both doctors initially appear (name + address)
        expect(find.text('Sarah Ali'), findsOneWidget);
        expect(find.text('Muscat'), findsOneWidget);
        expect(find.text('Ahmed Hassan'), findsOneWidget);
        expect(find.text('Sohar'), findsOneWidget);

        await tester.enterText(find.byType(TextField), 'Sarah');
        await tester.pumpAndSettle();

        // Verify filtered result (name & address)
        expect(find.text('Sarah Ali'), findsOneWidget);
        expect(find.text('Muscat'), findsOneWidget);
        expect(find.text('Ahmed Hassan'), findsNothing);
        expect(find.text('Sohar'), findsNothing);

        await tester.enterText(find.byType(TextField), 'Sohar');
        await tester.pumpAndSettle();

        //Verify only Ahmed shows (matching address)
        expect(find.text('Ahmed Hassan'), findsOneWidget);
        expect(find.text('Sohar'), findsOneWidget);
        expect(find.text('Sarah Ali'), findsNothing);
        expect(find.text('Muscat'), findsNothing);
      });
}
