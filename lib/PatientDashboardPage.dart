import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:jitsi_meet_flutter_sdk/jitsi_meet_flutter_sdk.dart';

import 'PatientLoginPage.dart';
import 'DoctorDetailsPage.dart';
import 'PatientProfilePage.dart';
import 'AIChatbotPage.dart';
import 'MedicationInfoPage.dart';
import 'SendFeedbackPage.dart';
import 'SendProblemPage.dart';
import 'BookedAppointmentsPage.dart';
import 'ClinicHospitalPage.dart';
import 'patient_tutorial.dart';

class PatientDashboardPage extends StatefulWidget {
  const PatientDashboardPage({super.key});

  @override
  State<PatientDashboardPage> createState() => _PatientDashboardPageState();
}

class _PatientDashboardPageState extends State<PatientDashboardPage> {
  final DatabaseReference doctorsRef =
  FirebaseDatabase.instance.ref().child("doctors");

  DatabaseReference? _incomingCallRef;
  StreamSubscription<DatabaseEvent>? _callSubscription;
  bool _callDialogShown = false;

  final Map<String, String?> _imageCache = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  String _safeEmail(String email) =>
      email.trim().toLowerCase().replaceAll('.', '_');

  @override
  void initState() {
    super.initState();
    _listenForIncomingCall();
  }

  void _listenForIncomingCall() {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null || email.trim().isEmpty) return;

    final safe = _safeEmail(email);

    _incomingCallRef = FirebaseDatabase.instance.ref("incomingCalls/$safe");

    _callSubscription = _incomingCallRef!.onValue.listen((event) async {
      if (!mounted) return;

      if (event.snapshot.value == null) {
        _callDialogShown = false;
        return;
      }

      final data = Map<String, dynamic>.from(event.snapshot.value as Map);

      final bool active = data["active"] == true;
      final String roomId = (data["roomId"] ?? "").toString();
      final String doctorName = (data["doctorName"] ?? "Doctor").toString();
      final String appointmentId = (data["appointmentId"] ?? "").toString();

      if (!active) {
        _callDialogShown = false;
        return;
      }

      if (roomId.isEmpty) return;

      // ✅ Do not show popup if already shown
      if (_callDialogShown) return;

      if (appointmentId.isNotEmpty) {
        final apptSnap =
        await FirebaseDatabase.instance.ref("appointments/$appointmentId").get();

        if (!apptSnap.exists || apptSnap.value == null) {
          return; 
        }

        final appt = Map<dynamic, dynamic>.from(apptSnap.value as Map);
        final bool startMeeting = appt["startMeeting"] == true;

        if (!startMeeting) return; 
      } else {
        return;
      }

      _callDialogShown = true;
      _showIncomingCallDialog(roomId, doctorName);
    });
  }

  void _showIncomingCallDialog(String roomId, String doctorName) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(isArabic ? "مكالمة واردة" : "Incoming Call"),
        content: Text(
          isArabic
              ? "الطبيب $doctorName يدعوك للانضمام إلى الموعد"
              : "Dr. $doctorName is inviting you to join the meeting",
        ),
        actions: [
          TextButton(
            child: Text(isArabic ? "رفض" : "Reject"),
            onPressed: () async {
              await _incomingCallRef?.remove();
              _callDialogShown = false;
              if (mounted) Navigator.pop(context);
            },
          ),
          ElevatedButton(
            child: Text(isArabic ? "انضمام" : "Join"),
            onPressed: () async {
              await _incomingCallRef?.remove();
              _callDialogShown = false;
              if (mounted) Navigator.pop(context);

              final jitsiMeet = JitsiMeet();

              final listener = JitsiMeetEventListener(
                conferenceTerminated: (url, error) {
                  debugPrint("Patient terminated: $url error=$error");
                },
                readyToClose: () {
                  debugPrint("Patient readyToClose");
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
                    "lobby-mode.enabled": false,
                    "prejoinpage.enabled": false,
                  },
                  userInfo: JitsiMeetUserInfo(
                    displayName:
                    FirebaseAuth.instance.currentUser?.displayName ?? "Patient",
                    email: FirebaseAuth.instance.currentUser?.email,
                  ),
                ),
                listener,
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
    _callSubscription?.cancel();
    super.dispose();
  }

  void _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PatientLoginPage()),
          (route) => false,
    );
  }

  Future<String?> _getDoctorImage(String uid, Map<String, dynamic> doctor) async {
    if (_imageCache.containsKey(uid)) return _imageCache[uid];

    try {
      if (doctor["profileImage"] != null &&
          doctor["profileImage"].toString().isNotEmpty) {
        _imageCache[uid] = doctor["profileImage"];
        return doctor["profileImage"];
      }

      final ref = FirebaseStorage.instance.ref("doctors/$uid/profile.jpg");
      final url = await ref.getDownloadURL();
      _imageCache[uid] = url;
      return url;
    } catch (_) {
      _imageCache[uid] = null;
      return null;
    }
  }

  Future<void> _toggleVoiceSearch() async {
    if (_isListening) {
      await _speech.stop();
      setState(() => _isListening = false);
      return;
    }

    bool available = await _speech.initialize();
    if (!available) return;

    setState(() => _isListening = true);

    await _speech.listen(
      listenFor: const Duration(seconds: 8),
      onResult: (result) {
        final words = result.recognizedWords;
        if (words.isNotEmpty) {
          setState(() {
            _searchController.text = words;
            _searchQuery = words.toLowerCase();
          });
        }
        if (result.finalResult) {
          _speech.stop();
          setState(() => _isListening = false);
        }
      },
    );
  }

  bool _matchesSearch(Map<String, dynamic> doctor) {
    if (_searchQuery.isEmpty) return true;
    final name = (doctor["fullName"] ?? "").toLowerCase();
    final address = (doctor["address"] ?? "").toLowerCase();
    return name.contains(_searchQuery) || address.contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic = Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isArabic ? "لوحة تحكم المريض" : "Patient Dashboard",
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => _signOut(context),
          ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.purple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isArabic ? "مرحباً بالمريض" : "Welcome Patient",
                    style: const TextStyle(color: Colors.white, fontSize: 22),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isArabic ? "خيارات القائمة" : "Menu Options",
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            _drawerItem(Icons.school,
                isArabic ? "عرض الشرح التعليمي" : "View Tutorial",
                    () => _go(const PatientTutorialPage())),
            _drawerItem(Icons.person,
                isArabic ? "الملف الشخصي" : "Personal Profile",
                    () => _go(const PatientProfilePage())),
            _drawerItem(Icons.smart_toy, isArabic ? "المساعد الذكي" : "AI Chatbot",
                    () => _go(const AIChatbotPage())),
            _drawerItem(Icons.medical_services,
                isArabic ? "الأدوية" : "Medication Info",
                    () => _go(const MedicationInfoPage())),
            _drawerItem(Icons.feedback,
                isArabic ? "إرسال ملاحظة" : "Send Feedback",
                    () => _go(const SendFeedbackPage())),
            _drawerItem(Icons.warning_amber,
                isArabic ? "إرسال مشكلة" : "Send Problem",
                    () => _go(const SendProblemPage())),
            _drawerItem(Icons.calendar_month,
                isArabic ? "المواعيد" : "Booked Appointments",
                    () => _go(const BookedAppointmentsPage())),
            _drawerItem(Icons.location_city, isArabic ? "الموقع" : "Location",
                    () => _go(const ClinicHospitalPage())),
          ],
        ),
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: isArabic
                          ? "ابحث عن طبيب بالاسم أو العنوان"
                          : "Search doctor by name or address",
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (v) =>
                        setState(() => _searchQuery = v.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening ? Colors.red : Colors.purple,
                  ),
                  onPressed: _toggleVoiceSearch,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder(
                stream: doctorsRef.onValue,
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(
                      child: Text(isArabic ? "لا يوجد أطباء" : "No doctors"),
                    );
                  }

                  final data = Map<String, dynamic>.from(
                    snapshot.data!.snapshot.value as Map,
                  );

                  final doctors = data.entries
                      .map((e) => MapEntry(
                      e.key, Map<String, dynamic>.from(e.value)))
                      .where((e) => _matchesSearch(e.value))
                      .toList();

                  if (doctors.isEmpty) {
                    return Center(
                      child: Text(
                        isArabic
                            ? "لا يوجد أطباء يطابقون بحثك"
                            : "No doctors match your search",
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final uid = doctors[index].key;
                      final doctor = doctors[index].value;

                      return FutureBuilder<String?>(
                        future: _getDoctorImage(uid, doctor),
                        builder: (context, snap) {
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                            child: ListTile(
                              leading: CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.purple.shade100,
                                backgroundImage:
                                snap.data != null ? NetworkImage(snap.data!) : null,
                                child: snap.data == null
                                    ? const Icon(Icons.person,
                                    color: Colors.purple, size: 28)
                                    : null,
                              ),
                              title: Text(doctor["fullName"] ?? ""),
                              subtitle: Text(doctor["address"] ?? ""),
                              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                final location = doctor["location"];
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DoctorDetailsPage(
                                      doctorName: doctor["fullName"] ?? "",
                                      description: doctor["description"] ?? "",
                                      staffId: doctor["staffId"] ?? "",
                                      address: doctor["address"] ?? "",
                                      specialization: doctor["specialization"] ?? "",
                                      lat: location != null && location["lat"] != null
                                          ? double.tryParse(location["lat"].toString())
                                          : null,
                                      lng: location != null && location["lng"] != null
                                          ? double.tryParse(location["lng"].toString())
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  ListTile _drawerItem(IconData icon, String text, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(text),
      onTap: onTap,
    );
  }

  void _go(Widget page) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}
