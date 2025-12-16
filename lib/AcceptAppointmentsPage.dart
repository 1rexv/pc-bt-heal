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

class _AcceptAppointmentsPageState extends State<AcceptAppointmentsPage> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref("appointments");

  StreamSubscription<DatabaseEvent>? _apptSub;

  List<Map<dynamic, dynamic>> pendingAppointments = [];
  List<Map<dynamic, dynamic>> acceptedAppointments = [];

  String _normEmail(String? email) => (email ?? '').trim().toLowerCase();
  String _safeEmail(String email) => email.trim().toLowerCase().replaceAll('.', '_');

  bool _isToday(String yyyyMmDd) {
    final d = DateTime.tryParse(yyyyMmDd);
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  @override
  void dispose() {
    _apptSub?.cancel();
    super.dispose();
  }

  // ================= FETCH APPOINTMENTS =================
  void _fetchAppointments() {
    _apptSub = _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      final currentDoctorEmail = _normEmail(FirebaseAuth.instance.currentUser?.email);

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

        final apptDoctorEmail = _normEmail(appt['doctorEmail']?.toString());

        // ✅ robust match (trim + lowercase)
        if (currentDoctorEmail.isNotEmpty && apptDoctorEmail == currentDoctorEmail) {
          final status = (appt['status'] ?? '').toString().toLowerCase();

          if (status == 'pending') {
            pending.add(appt);
          } else if (status == 'accepted') {
            accepted.add(appt);
          }
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

  // ================= ACCEPT APPOINTMENT (WITH VALIDATION) =================
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
                labelText: "Date (YYYY-MM-DD)",
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

                // date validation
                final selectedDate = DateTime.parse(dateText);
                final now = DateTime.now();
                final today = DateTime(now.year, now.month, now.day);
                final onlyDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
                if (onlyDate.isBefore(today)) throw "Date must be today or later";

                // time validation
                final timeFormat = DateFormat("h:mm a");
                final selectedTime = timeFormat.parse(timeText);
                final minTime = timeFormat.parse("7:30 AM");
                final maxTime = timeFormat.parse("3:00 PM");
                if (selectedTime.isBefore(minTime) || selectedTime.isAfter(maxTime)) {
                  throw "Time must be between 7:30 AM and 3:00 PM";
                }

                final apptKey = appointment['id'].toString();
                final patientEmail = _normEmail(appointment['patientEmail']?.toString());
                if (patientEmail.isEmpty) throw "Patient email missing in appointment";

                // ✅ Unique room per appointment + patient email
                final roomId = "appt_${_safeEmail(patientEmail)}_$apptKey";

                await _dbRef.child(apptKey).update({
                  "status": "accepted",
                  "date": dateText,
                  "time": timeText,
                  "startMeeting": false,
                  "roomId": roomId, // ✅ store room for both sides
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

  // ================= REJECT =================
  Future<void> _rejectAppointment(Map<dynamic, dynamic> appointment) async {
    final id = appointment['id']?.toString() ?? '';
    if (id.isEmpty) return;

    await _dbRef.child(id).update({
      "status": "rejected",
      "startMeeting": false,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Rejected appointment with ${appointment['patientName'] ?? 'patient'}")),
    );
  }

  // ================= START MEETING =================
  Future<void> _startMeetingForAppointment(Map<dynamic, dynamic> appt) async {
    final appointmentId = (appt['id'] ?? '').toString();
    final patientEmail = _normEmail(appt['patientEmail']?.toString());
    final patientName = (appt['patientName'] ?? 'Patient').toString();
    final apptDate = (appt['date'] ?? '').toString().trim();

    if (appointmentId.isEmpty) {
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

    // ✅ keep your rule (today only)
    if (apptDate.isEmpty || !_isToday(apptDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Meeting can only start on the appointment date"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // ✅ IMPORTANT: use the stored roomId (unique + same for both)
    final roomId = (appt['roomId'] ?? '').toString().trim().isNotEmpty
        ? (appt['roomId'] ?? '').toString().trim()
        : "appt_${_safeEmail(patientEmail)}_$appointmentId";

    final safePatientEmail = _safeEmail(patientEmail);

    final callRef = FirebaseDatabase.instance.ref("incomingCalls/$safePatientEmail");

    // ✅ flip startMeeting in appointment
    await _dbRef.child(appointmentId).update({"startMeeting": true});

    // ✅ send to patient listener
    await callRef.set({
      "active": true,
      "appointmentId": appointmentId, // ✅ required for patient to check startMeeting
      "roomId": roomId,               // ✅ same room on both sides
      "doctorName": FirebaseAuth.instance.currentUser?.displayName ?? "Doctor",
      "doctorEmail": FirebaseAuth.instance.currentUser?.email ?? "",
      "ts": ServerValue.timestamp,
    });

    final jitsiMeet = JitsiMeet();

    final listener = JitsiMeetEventListener(
      conferenceJoined: (url) => debugPrint("Doctor joined: $url"),
      conferenceTerminated: (url, error) async {
        debugPrint("Doctor terminated: $url error=$error");
        await _dbRef.child(appointmentId).update({"startMeeting": false});
        await callRef.remove();
      },
      readyToClose: () async {
        debugPrint("Doctor readyToClose");
        await _dbRef.child(appointmentId).update({"startMeeting": false});
        await callRef.remove();
      },
    );

    jitsiMeet.join(
      JitsiMeetConferenceOptions(
        room: roomId,
        configOverrides: {
          "startWithAudioMuted": false,
          "startWithVideoMuted": false,
          "startWithLobbyEnabled": false,
          "enableWelcomePage": false,
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
      listener,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Starting meeting with $patientName...")),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    final currentDoctorEmail = _normEmail(FirebaseAuth.instance.currentUser?.email);

    if (currentDoctorEmail.isEmpty) {
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
          const Text(
            "Pending Appointments",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
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

          const Text(
            "Accepted Appointments",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (acceptedAppointments.isEmpty)
            const Text("No accepted appointments yet.")
          else
            ...acceptedAppointments.map((appt) {
              final date = (appt['date'] ?? '').toString();
              final canStart = date.isNotEmpty && _isToday(date);
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
                    ],
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.video_call, size: 32, color: canStart ? Colors.purple : Colors.grey),
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
