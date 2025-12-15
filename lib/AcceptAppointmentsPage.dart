import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';
import 'package:intl/intl.dart';

class AcceptAppointmentsPage extends StatefulWidget {
  const AcceptAppointmentsPage({super.key});

  @override
  State<AcceptAppointmentsPage> createState() => _AcceptAppointmentsPageState();
}

class _AcceptAppointmentsPageState extends State<AcceptAppointmentsPage>
    with WidgetsBindingObserver {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("appointments");

  final String? currentDoctorEmail = FirebaseAuth.instance.currentUser?.email;

  StreamSubscription<DatabaseEvent>? _apptSub;

  final JitsiMeet _jitsiMeet = JitsiMeet();

  List<Map<dynamic, dynamic>> pendingAppointments = [];
  List<Map<dynamic, dynamic>> acceptedAppointments = [];

  bool _meetingInProgress = false;
  String? _activeAppointmentKey;
  DatabaseReference? _activeCallRef;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchAppointments();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _apptSub?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _meetingInProgress) {
      _endMeetingCleanup();
    }
  }

  Future<void> _endMeetingCleanup() async {
    final apptKey = _activeAppointmentKey;
    try {
      if (apptKey != null) {
        await _dbRef.child(apptKey).update({"startMeeting": false});
      }
      await _activeCallRef?.remove();
    } catch (_) {
    }

    _meetingInProgress = false;
    _activeAppointmentKey = null;
    _activeCallRef = null;
  }

  String _safeEmail(String email) =>
      email.trim().toLowerCase().replaceAll('.', '_');

  DateTime _parseDateFlexible(String s) {
    s = s.trim();
    final d1 = DateTime.tryParse(s);
    if (d1 != null) return d1;

    return DateFormat('dd-MM-yyyy').parseStrict(s);
  }

  bool _isTodayDateString(String yyyyMmDd) {
    try {
      final d = _parseDateFlexible(yyyyMmDd);
      final now = DateTime.now();
      return d.year == now.year && d.month == now.month && d.day == now.day;
    } catch (_) {
      return false;
    }
  }

  void _fetchAppointments() {
    _apptSub = _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) {
        if (mounted) {
          setState(() {
            pendingAppointments = [];
            acceptedAppointments = [];
          });
        }
        return;
      }

      final List<Map<dynamic, dynamic>> pending = [];
      final List<Map<dynamic, dynamic>> accepted = [];

      data.forEach((key, value) {
        final appt = Map<dynamic, dynamic>.from(value);
        appt['id'] = key;

        if (currentDoctorEmail != null && appt['doctorEmail'] == currentDoctorEmail) {
          final status = (appt['status'] ?? '').toString().toLowerCase();
          if (status == 'pending') pending.add(appt);
          if (status == 'accepted') accepted.add(appt);
        }
      });

      if (mounted) {
        setState(() {
          pendingAppointments = pending;
          acceptedAppointments = accepted;
        });
      }
    });
  }

  // ================= ACCEPT (SET DATE/TIME + startMeeting false) =================
  void _acceptAppointment(Map<dynamic, dynamic> appointment) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Set Date & Time"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: "Date (YYYY-MM-DD or DD-MM-YYYY)",
                icon: Icon(Icons.calendar_today, color: Colors.purple),
              ),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: "Time (e.g. 7:30 AM)",
                icon: Icon(Icons.access_time, color: Colors.purple),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Allowed time: 7:30 AM – 3:00 PM",
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, color: Colors.white),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            label: const Text("Confirm"),
            onPressed: () async {
              try {
                final dateText = dateController.text.trim();
                final timeText = timeController.text.trim();

                if (dateText.isEmpty || timeText.isEmpty) {
                  throw "Please enter date and time";
                }

                final selectedDate = _parseDateFlexible(dateText);
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final onlyDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
                if (onlyDate.isBefore(today)) {
                  throw "Date must be today or later";
                }

                final savedDate = DateFormat('yyyy-MM-dd').format(selectedDate);

                final timeFormat = DateFormat("h:mm a");
                final selectedTime = timeFormat.parseStrict(timeText);
                final minTime = timeFormat.parseStrict("7:30 AM");
                final maxTime = timeFormat.parseStrict("9:00 PM");

                if (selectedTime.isBefore(minTime) || selectedTime.isAfter(maxTime)) {
                  throw "Time must be between 7:30 AM and 3:00 PM";
                }

                await _dbRef.child(appointment['id']).update({
                  "status": "accepted",
                  "date": savedDate,
                  "time": timeText,
                  "startMeeting": false,
                });

                if (mounted) Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Accepted appointment for ${appointment['patientName'] ?? 'patient'}")),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _rejectAppointment(Map<dynamic, dynamic> appointment) async {
    await _dbRef.child(appointment['id']).update({
      "status": "rejected",
      "startMeeting": false,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Rejected appointment with ${appointment['patientName'] ?? 'patient'}")),
    );
  }

  Future<void> _startMeetingForAppointment(Map<dynamic, dynamic> appt) async {
    final apptKey = (appt['id'] ?? '').toString();
    final patientEmail = (appt['patientEmail'] ?? '').toString().trim();
    final patientName = (appt['patientName'] ?? 'Patient').toString();
    final apptDate = (appt['date'] ?? '').toString().trim();

    if (apptKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Appointment ID missing"), backgroundColor: Colors.red),
      );
      return;
    }

    if (patientEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Patient email missing"), backgroundColor: Colors.red),
      );
      return;
    }

    // Must be today
    if (apptDate.isEmpty || !_isTodayDateString(apptDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Meeting can only start on the appointment date (today)."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final safePatientEmail = _safeEmail(patientEmail);
    final roomId = "appointment_$apptKey";

    final callRef = FirebaseDatabase.instance.ref("incomingCalls/$safePatientEmail");

    // ✅ Update DB flag
    await _dbRef.child(apptKey).update({"startMeeting": true});

    // ✅ Trigger patient popup node (also includes startMeeting)
    await callRef.set({
      "active": true,
      "startMeeting": true,
      "appointmentId": apptKey,
      "roomId": roomId,
      "doctorName": FirebaseAuth.instance.currentUser?.displayName ?? "Doctor",
      "doctorEmail": FirebaseAuth.instance.currentUser?.email ?? "",
      "ts": ServerValue.timestamp,
    });

    // Track for cleanup when we return from Jitsi
    _meetingInProgress = true;
    _activeAppointmentKey = apptKey;
    _activeCallRef = callRef;

    // Join Jitsi room
    _jitsiMeet.join(
      JitsiMeetConferenceOptions(
        room: roomId,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "enableWelcomePage": false,
          "startWithLobbyEnabled": false,
        },
        featureFlags: {
          "prejoinpage.enabled": false,
          "lobby-mode.enabled": false,
        },
        userInfo: JitsiMeetUserInfo(
          displayName: "Dr. ${FirebaseAuth.instance.currentUser?.displayName ?? 'Doctor'}",
          email: FirebaseAuth.instance.currentUser?.email,
        ),
      ),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Starting meeting with $patientName...")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (currentDoctorEmail == null) {
      return const Scaffold(
        body: Center(child: Text("Please login as a doctor first.")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Appointments", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("Pending Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (pendingAppointments.isEmpty)
            const Text("No pending appointments.")
          else
            ...pendingAppointments.map((appt) {
              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person, color: Colors.purple),
                  title: Text(appt['patientName'] ?? "Unknown"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${appt['patientEmail'] ?? '-'}"),
                      Text("Location: ${appt['location'] ?? '-'}"),
                      const Text("Status: Pending", style: TextStyle(color: Colors.orange)),
                    ],
                  ),
                  trailing: Wrap(
                    spacing: 8,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check_circle, color: Colors.green),
                        onPressed: () => _acceptAppointment(appt),
                      ),
                      IconButton(
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        onPressed: () => _rejectAppointment(appt),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),

          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          const Text("Accepted Appointments",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),

          if (acceptedAppointments.isEmpty)
            const Text("No accepted appointments yet.")
          else
            ...acceptedAppointments.map((appt) {
              final date = (appt['date'] ?? '').toString().trim();
              final canStart = date.isNotEmpty && _isTodayDateString(date);
              final started = (appt['startMeeting'] == true);

              return Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ListTile(
                  leading: const Icon(Icons.person_pin, color: Colors.green),
                  title: Text(appt['patientName'] ?? "Unknown"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Email: ${appt['patientEmail'] ?? '-'}"),
                      Text("Date: ${appt['date'] ?? '-'}"),
                      Text("Time: ${appt['time'] ?? '-'}"),
                      Text("Location: ${appt['location'] ?? '-'}"),
                      Text(
                        "startMeeting: $started",
                        style: TextStyle(color: started ? Colors.green : Colors.grey),
                      ),
                      if (!canStart)
                        const Text(" You can start only on appointment day (today)",
                            style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(
                      Icons.video_call,
                      size: 32,
                      color: canStart ? Colors.purple : Colors.grey,
                    ),
                    onPressed: canStart ? () => _startMeetingForAppointment(appt) : null,
                  ),
                ),
              );
            }).toList(),
        ],
      ),
    );
  }
}
