import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class AcceptAppointmentsPage extends StatefulWidget {
  const AcceptAppointmentsPage({super.key});

  @override
  State<AcceptAppointmentsPage> createState() =>
      _AcceptAppointmentsPageState();
}

class _AcceptAppointmentsPageState extends State<AcceptAppointmentsPage> {
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref("appointments");

  final String? currentDoctorEmail =
      FirebaseAuth.instance.currentUser?.email;

  List<Map<dynamic, dynamic>> acceptedAppointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  void _fetchAppointments() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;
      if (data == null) return;

      List<Map<dynamic, dynamic>> accepted = [];

      data.forEach((key, value) {
        final appointment = Map<dynamic, dynamic>.from(value);
        appointment['id'] = key;

        if (appointment['doctorEmail'] == currentDoctorEmail &&
            appointment['status'] == 'accepted') {
          accepted.add(appointment);
        }
      });

      if (mounted) {
        setState(() => acceptedAppointments = accepted);
      }
    });
  }

  Future<void> _startVideoCall(
      String appointmentId,
      String patientId,
      String patientName,
      ) async {
    final callRef =
    FirebaseDatabase.instance.ref("incomingCalls/$patientId");

    await callRef.set({
      "active": true,
      "roomId": "appointment_$appointmentId",
      "doctorName":
      FirebaseAuth.instance.currentUser?.displayName ?? "Doctor",
    });

    final jitsiMeet = JitsiMeet();
    jitsiMeet.join(
      JitsiMeetConferenceOptions(
        room: "appointment_$appointmentId",
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    final pageTitle =
    isArabic ? "المواعيد المقبولة" : "Accepted Appointments";
    final noAppointmentsText = isArabic
        ? "لا توجد مواعيد مقبولة حالياً"
        : "No accepted appointments yet";
    final timeText = isArabic ? "الوقت" : "Time";
    final unknownPatient =
    isArabic ? "مريض غير معروف" : "Unknown Patient";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          pageTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: acceptedAppointments.isEmpty
          ? Center(
        child: Text(
          noAppointmentsText,
          style: const TextStyle(fontSize: 16),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: acceptedAppointments.length,
        itemBuilder: (context, index) {
          final appt = acceptedAppointments[index];

          return Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: const Icon(
                Icons.person,
                color: Colors.green,
              ),
              title: Text(
                appt['patientName'] ?? unknownPatient,
              ),
              subtitle: Text(
                "$timeText: ${appt['time'] ?? '--'}",
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.video_call,
                  color: Colors.purple,
                  size: 30,
                ),
                tooltip: isArabic
                    ? "بدء مكالمة فيديو"
                    : "Start Video Call",
                onPressed: () => _startVideoCall(
                  appt['id'],
                  appt['patientId'],
                  appt['patientName'],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
