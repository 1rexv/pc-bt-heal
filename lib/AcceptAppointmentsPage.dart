import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

class AcceptAppointmentsPage extends StatefulWidget {
  const AcceptAppointmentsPage({super.key});

  @override
  State<AcceptAppointmentsPage> createState() => _AcceptAppointmentsPageState();
}

class _AcceptAppointmentsPageState extends State<AcceptAppointmentsPage> {
  final DatabaseReference _dbRef =
  FirebaseDatabase.instance.ref("appointments");
  final String? currentDoctorEmail = FirebaseAuth.instance.currentUser?.email;

  List<Map<dynamic, dynamic>> pendingAppointments = [];
  List<Map<dynamic, dynamic>> acceptedAppointments = [];

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  /// 🔹 Fetch appointments for the logged-in doctor only
  void _fetchAppointments() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data != null) {
        List<Map<dynamic, dynamic>> pending = [];
        List<Map<dynamic, dynamic>> accepted = [];

        data.forEach((key, value) {
          final appointment = Map<dynamic, dynamic>.from(value);
          appointment['id'] = key;

          if (appointment['doctorEmail'] == currentDoctorEmail) {
            if (appointment['status'] == 'pending') {
              pending.add(appointment);
            } else if (appointment['status'] == 'accepted') {
              accepted.add(appointment);
            }
          }
        });

        setState(() {
          pendingAppointments = pending;
          acceptedAppointments = accepted;
        });
      }
    });
  }

  /// 🔹 Accept appointment and set date/time
  void _acceptAppointment(Map<dynamic, dynamic> appointment) {
    TextEditingController dateController = TextEditingController();
    TextEditingController timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Set Date & Time"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: dateController,
              decoration: const InputDecoration(
                labelText: "Enter Date (e.g., 2025-10-10)",
                icon: Icon(Icons.calendar_today, color: Colors.purple),
              ),
            ),
            TextField(
              controller: timeController,
              decoration: const InputDecoration(
                labelText: "Enter Time (e.g., 10:00 AM)",
                icon: Icon(Icons.access_time, color: Colors.purple),
              ),
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
            onPressed: () async {
              if (dateController.text.isNotEmpty &&
                  timeController.text.isNotEmpty) {
                await _dbRef.child(appointment['id']).update({
                  "status": "accepted",
                  "date": dateController.text,
                  "time": timeController.text,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(
                          'Accepted appointment for ${appointment['patientName']}')),
                );
              }
            },
            label: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  /// 🔹 Reject appointment
  void _rejectAppointment(Map<dynamic, dynamic> appointment) async {
    await _dbRef.child(appointment['id']).update({"status": "rejected"});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(
              'Rejected appointment with ${appointment['patientName']}')),
    );
  }

  /// 📹 Start a Jitsi video call — auto joins with appointment ID as room name
  void _startVideoCall(String appointmentId, String patientName) {
    final jitsiMeet = JitsiMeet();
    var options = JitsiMeetConferenceOptions(
      room: "appointment_$appointmentId", // unique room
      configOverrides: {
        "startWithAudioMuted": false,
        "startWithVideoMuted": false,
      },
      featureFlags: {
        "chat.enabled": true,
        "invite.enabled": false,
      },
      userInfo: JitsiMeetUserInfo(
        displayName: "Dr. ${FirebaseAuth.instance.currentUser?.displayName ?? "Doctor"}",
        email: currentDoctorEmail,
      ),
    );

    jitsiMeet.join(options);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Joining video call with $patientName...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patient Appointments',
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text('Pending Appointments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 🔹 PENDING APPOINTMENTS
            if (pendingAppointments.isEmpty)
              const Text('No pending appointments.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: pendingAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = pendingAppointments[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading: const Icon(Icons.person, color: Colors.purple),
                        title: Text(appointment['patientName'] ?? "Unknown"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email: ${appointment['patientEmail'] ?? '-'}"),
                            Text("Location: ${appointment['location'] ?? '-'}"),
                            const Text("Status: Pending",
                                style: TextStyle(color: Colors.orange)),
                          ],
                        ),
                        trailing: Wrap(
                          spacing: 8,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.check_circle,
                                  color: Colors.green),
                              onPressed: () => _acceptAppointment(appointment),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _rejectAppointment(appointment),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 16),
            const Divider(),

            const Text('Accepted Appointments',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // 🔹 ACCEPTED APPOINTMENTS
            if (acceptedAppointments.isEmpty)
              const Text('No accepted appointments yet.')
            else
              Expanded(
                child: ListView.builder(
                  itemCount: acceptedAppointments.length,
                  itemBuilder: (context, index) {
                    final appointment = acceptedAppointments[index];
                    return Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        leading:
                        const Icon(Icons.person_pin, color: Colors.green),
                        title: Text(appointment['patientName'] ?? "Unknown"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Email: ${appointment['patientEmail'] ?? '-'}"),
                            Text("Date: ${appointment['date'] ?? '-'}"),
                            Text("Time: ${appointment['time'] ?? '-'}"),
                            Text("Location: ${appointment['location'] ?? '-'}"),
                            const Text("Status: Accepted",
                                style: TextStyle(color: Colors.green)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.video_call,
                              size: 32, color: Colors.purple),
                          onPressed: () => _startVideoCall(
                              appointment['id'], appointment['patientName']),
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
