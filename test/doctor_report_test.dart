import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pc_bt_heal/DoctorReportPage.dart';


class MockUser extends Mock implements User {
  @override
  String? get email => 'zahra@heal.com';
}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}
class MockDatabaseReference extends Mock implements DatabaseReference {}
class MockDataSnapshot extends Mock implements DataSnapshot {}
class MockFirebaseDatabase extends Mock implements FirebaseDatabase {}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockFirebaseDatabase mockDatabase;
  late MockDatabaseReference mockRef;
  late MockDataSnapshot mockSnapshot;
  late MockUser mockUser;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockDatabase = MockFirebaseDatabase();
    mockRef = MockDatabaseReference();
    mockSnapshot = MockDataSnapshot();
    mockUser = MockUser();

    // fake auth user
    when(mockAuth.currentUser).thenReturn(mockUser);


    when(mockDatabase.ref('appointments')).thenReturn(mockRef);
    when(mockRef.orderByChild('doctorEmail')).thenReturn(mockRef);
    when(mockRef.equalTo('z@gmail.com')).thenReturn(mockRef);
    when(mockRef.get()).thenAnswer((_) async => mockSnapshot);
    when(mockSnapshot.exists).thenReturn(false);
  });


  testWidgets('PASS TEST: Doctor report page builds successfully', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DoctorReportPage()));


    expect(find.text('Doctor Case Report'), findsOneWidget);
    // shows progress while loading
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('FAIL TEST: Wrong text should fail', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: DoctorReportPage()));
    await tester.pumpAndSettle();
    // intentionally failing expectation
    expect(find.text('Fake Doctor Report'), findsOneWidget);
  });
}
