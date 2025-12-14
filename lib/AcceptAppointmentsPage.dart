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

  List<Map<dynamic, dynamic>> pendingAppointments = [];
  List<Map<dynamic, dynamic>> acceptedAppointments = [];

  bool get isArabic =>
      Localizations.localeOf(context).languageCode.startsWith('ar');

  String t(String en, String ar) => isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  
  void _fetchAppointments() {
    _dbRef.onValue.listen((event) {
      final data = event.snapshot.value as Map<dynamic, dynamic>?;

      if (data == null) return;

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
    });
  }

  
  void _acceptAppointment(Map<dynamic, dynamic> appointment) {
    final dateController = TextEditingController();
    final timeController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Directionality(
        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
        child: AlertDialog(
          title: Text(t("Set Date & Time", "تحديد التاريخ والوقت")),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: dateController,
                decoration: InputDecoration(
                  labelText: t(
                    "Enter Date (YYYY-MM-DD)",
                    "أدخل التاريخ (YYYY-MM-DD)",
                  ),
                  icon: const Icon(Icons.calendar_today, color: Colors.purple),
                ),
              ),
              TextField(
                controller: timeController,
                decoration: InputDecoration(
                  labelText: t(
                    "Enter Time (e.g. 10:00 AM)",
                    "أدخل الوقت (مثال 10:00)",
                  ),
                  icon: const Icon(Icons.access_time, color: Colors.purple),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(t("Cancel", "إلغاء")),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.check, color: Colors.white),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
              label: Text(t("Confirm", "تأكيد")),
              onPressed: () async {
                if (dateController.text.isEmpty ||
                    timeController.text.isEmpty) return;

                await _dbRef.child(appointment['id']).update({
                  "status": "accepted",
                  "date": dateController.text,
                  "time": timeController.text,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      t(
                        "Appointment accepted for ${appointment['patientName']}",
                        "تم قبول موعد ${appointment['patientName']}",
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  
  void _rejectAppointment(Map<dynamic, dynamic> appointment) async {
    await _dbRef.child(appointment['id']).update({"status": "rejected"});

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t(
            "Appointment rejected with ${appointment['patientName']}",
            "تم رفض موعد ${appointment['patientName']}",
          ),
        ),
      ),
    );
  }

  
  void _startVideoCall(String appointmentId, String patientName) {
    final jitsiMeet = JitsiMeet();

    var options = JitsiMeetConferenceOptions(
      room: "appointment_$appointmentId",
      configOverrides: {
        "startWithAudioMuted": false,
        "startWithVideoMuted": false,
      },
      featureFlags: {
        "chat.enabled": true,
        "invite.enabled": false,
      },
      userInfo: JitsiMeetUserInfo(
        displayName:
        "Dr. ${FirebaseAuth.instance.currentUser?.displayName ?? "Doctor"}",
        email: currentDoctorEmail,
      ),
    );

    jitsiMeet.join(options);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t(
            "Joining video call with $patientName...",
            "جاري الانضمام لمكالمة فيديو مع $patientName...",
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            t("Patient Appointments", "مواعيد المرضى"),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              
              Text(
                t("Pending Appointments", "المواعيد المعلقة"),
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (pendingAppointments.isEmpty)
                Text(t(
                  "No pending appointments.",
                  "لا توجد مواعيد معلقة.",
                ))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: pendingAppointments.length,
                    itemBuilder: (_, index) {
                      final a = pendingAppointments[index];
                      return _appointmentCard(
                        appointment: a,
                        isAccepted: false,
                      );
                    },
                  ),
                ),

              const Divider(height: 32),

              
              Text(
                t("Accepted Appointments", "المواعيد المقبولة"),
                style:
                const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              if (acceptedAppointments.isEmpty)
                Text(t(
                  "No accepted appointments yet.",
                  "لا توجد مواعيد مقبولة بعد.",
                ))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: acceptedAppointments.length,
                    itemBuilder: (_, index) {
                      final a = acceptedAppointments[index];
                      return _appointmentCard(
                        appointment: a,
                        isAccepted: true,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _appointmentCard({
    required Map<dynamic, dynamic> appointment,
    required bool isAccepted,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(
          isAccepted ? Icons.person_pin : Icons.person,
          color: isAccepted ? Colors.green : Colors.purple,
        ),
        title: Text(appointment['patientName'] ?? "-"),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${t("Email", "البريد")}: ${appointment['patientEmail'] ?? '-'}"),
            if (isAccepted)
              Text("${t("Date", "التاريخ")}: ${appointment['date'] ?? '-'}"),
            if (isAccepted)
              Text("${t("Time", "الوقت")}: ${appointment['time'] ?? '-'}"),
            Text(
              isAccepted
                  ? t("Status: Accepted", "الحالة: مقبول")
                  : t("Status: Pending", "الحالة: معلق"),
              style: TextStyle(
                color: isAccepted ? Colors.green : Colors.orange,
              ),
            ),
          ],
        ),
        trailing: isAccepted
            ? IconButton(
          icon: const Icon(Icons.video_call,
              size: 32, color: Colors.purple),
          onPressed: () => _startVideoCall(
            appointment['id'],
            appointment['patientName'],
          ),
        )
            : Wrap(
          children: [
            IconButton(
              icon: const Icon(Icons.check_circle,
                  color: Colors.green),
              onPressed: () => _acceptAppointment(appointment),
            ),
            IconButton(
              icon:
              const Icon(Icons.cancel, color: Colors.red),
              onPressed: () => _rejectAppointment(appointment),
            ),
          ],
        ),
      ),
    );
  }
}
