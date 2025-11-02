import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pc_bt_heal/DoctorReportPage.dart';

class MockUser extends Mock implements User {
  @override
  String? get email => 'z@gmail.com';
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockQuery extends Mock implements Query {}
class MockDataSnapshot extends Mock implements DataSnapshot {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseDatabase mockDatabase;
  late MockDatabaseReference mockRef;
  late MockQuery mockQuery;
  late MockDataSnapshot mockSnapshot;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockDatabase = MockFirebaseDatabase();
    mockRef = MockDatabaseReference();
    mockQuery = MockQuery();
    mockSnapshot = MockDataSnapshot();
    mockUser = MockUser();

    //Fake user
    when(mockAuth.currentUser).thenReturn(mockUser);

    //Database and query chain
    when(mockDatabase.ref('appointments')).thenReturn(mockRef);
    when(mockRef.orderByChild('doctorEmail')).thenReturn(mockQuery);
    when(mockQuery.equalTo('z@gmail.com')).thenReturn(mockQuery);
    when(mockQuery.get()).thenAnswer((_) async => mockSnapshot);

    //Fake snapshot data
    when(mockSnapshot.exists).thenReturn(true);
    when(mockSnapshot.value).thenReturn({
      'case1': {'doctorEmail': 'z@gmail.com', 'doctorName': 'zahra mohammed', 'status': 'treated'},
      'case2': {'doctorEmail': 'z@gmail.com', 'doctorName': 'zahra mohammed', 'status': 'pending'},
      'case3': {'doctorEmail': 'z@gmail.com', 'doctorName': 'zahra mohammed', 'status': 'completed'},
    });
  });

  //PASS TEST
  testWidgets('PASS TEST: Doctor report page builds and shows cases', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DoctorReportPage(database: mockDatabase)),
    );
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(find.text('Doctor Case Report'), findsOneWidget);
    expect(find.textContaining('Total'), findsOneWidget);
    expect(find.textContaining('Treated'), findsOneWidget);
    expect(find.textContaining('Pending'), findsOneWidget);
  });

  // FAIL TEST
  testWidgets('FAIL TEST: Wrong text should fail', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: DoctorReportPage(database: mockDatabase)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Fake Doctor Report'), findsOneWidget); //should fail
  });
}
