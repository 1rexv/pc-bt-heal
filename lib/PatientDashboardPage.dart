import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
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

  final Map<String, String?> _imageCache = {};
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  @override
  void dispose() {
    _speech.stop();
    _searchController.dispose();
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
    } catch (e) {
      debugPrint("Could not load image for $uid: $e");
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

    bool available = await _speech.initialize(
      onStatus: (status) => debugPrint("Status: $status"),
      onError: (error) => debugPrint("Speech error: ${error.errorMsg}"),
    );

    if (!available) {
      if (mounted) {
        final isArabic =
            Localizations.localeOf(context).languageCode == 'ar';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isArabic
                  ? "البحث الصوتي غير متوفر، يرجى التحقق من صلاحيات الميكروفون."
                  : "Voice search not available. Check mic permissions.",
            ),
          ),
        );
      }
      return;
    }

    setState(() => _isListening = true);

    await _speech.listen(
      listenFor: const Duration(seconds: 8),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      cancelOnError: true,
      onResult: (result) {
        final recognized = result.recognizedWords;

        if (recognized.isNotEmpty) {
          setState(() {
            _searchController.text = recognized;
            _searchQuery = recognized.toLowerCase();
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

    final name = (doctor["fullName"] ?? "").toString().toLowerCase();
    final address = (doctor["address"] ?? "").toString().toLowerCase();

    return name.contains(_searchQuery) || address.contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    final appBarTitle =
    isArabic ? "لوحة تحكم المريض" : "Patient Dashboard";
    final drawerHeaderTitle =
    isArabic ? "مرحباً بالمريض" : "Welcome Patient";
    final drawerHeaderSubtitle =
    isArabic ? "خيارات القائمة" : "Menu Options";

    final viewTutorialText =
    isArabic ? "عرض الشرح التعليمي" : "View Tutorial";
    final personalProfileText =
    isArabic ? "الملف الشخصي" : "Personal Profile";
    final aiChatbotText = isArabic ? "المساعد الذكي" : "AI Chatbot";
    final medicationInfoText =
    isArabic ? "الأدوية الموصوفة" : "Medication Info";
    final sendFeedbackText =
    isArabic ? "إرسال ملاحظة" : "Send Feedback";
    final sendProblemText =
    isArabic ? "إرسال مشكلة" : "Send Problem";
    final bookedAppointmentsText =
    isArabic ? "المواعيد المحجوزة" : "Booked Appointments";
    final locationText = isArabic ? "الموقع" : "Location";

    final searchHint = isArabic
        ? "ابحث عن طبيب بالاسم أو العنوان"
        : "Search doctor by name or address";

    final loadingDoctorsText =
    isArabic ? "جاري تحميل الأطباء..." : "Loading doctors...";
    final errorDoctorsText =
    isArabic ? "حدث خطأ أثناء تحميل الأطباء" : "Error loading doctors";
    final noDoctorsText =
    isArabic ? "لا يوجد أطباء متاحون" : "No doctors found";
    final noMatchDoctorsText = isArabic
        ? "لا يوجد أطباء يطابقون بحثك."
        : "No doctors match your search.";

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: isArabic ? "تسجيل الخروج" : "Sign Out",
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
                    drawerHeaderTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    drawerHeaderSubtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            
            ListTile(
              leading: const Icon(Icons.school),
              title: Text(viewTutorialText),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientTutorialPage(),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.person),
              title: Text(personalProfileText),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PatientProfilePage(),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: Text(aiChatbotText),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AIChatbotPage(),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.medical_services),
              title: Text(medicationInfoText),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationInfoPage(),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.feedback),
              title: Text(sendFeedbackText),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SendFeedbackPage(),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: Text(sendProblemText),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SendProblemPage(),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: Text(bookedAppointmentsText),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BookedAppointmentsPage(),
                ),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.location_city),
              title: Text(locationText),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ClinicHospitalPage(),
                ),
              ),
            ),
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
                      hintText: searchHint,
                      prefixIcon: const Icon(Icons.search),
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: (value) =>
                        setState(() => _searchQuery = value.toLowerCase()),
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
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: Text(loadingDoctorsText));
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text(errorDoctorsText));
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return Center(child: Text(noDoctorsText));
                  }

                  final data = Map<String, dynamic>.from(
                    (snapshot.data! as DatabaseEvent).snapshot.value as Map,
                  );

                  final doctors = data.entries
                      .map(
                        (e) => MapEntry(
                      e.key,
                      Map<String, dynamic>.from(e.value),
                    ),
                  )
                      .where((entry) {
                    final doctor = entry.value;
                    final isDisabled = doctor["enabled"] != null &&
                        doctor["enabled"] == false;
                    return !isDisabled && _matchesSearch(doctor);
                  }).toList();

                  if (doctors.isEmpty) {
                    return Center(child: Text(noMatchDoctorsText));
                  }

                  return ListView.builder(
                    itemCount: doctors.length,
                    itemBuilder: (context, index) {
                      final uid = doctors[index].key;
                      final doctor = doctors[index].value;

                      return FutureBuilder<String?>(
                        future: _getDoctorImage(uid, doctor),
                        builder: (context, snapshot) {
                          final imageUrl = snapshot.data;

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
                                backgroundImage: imageUrl != null
                                    ? NetworkImage(imageUrl)
                                    : const AssetImage(
                                    "images/doctor_placeholder.png")
                                as ImageProvider,
                              ),
                              title: Text(
                                doctor["fullName"] ??
                                    (isArabic
                                        ? "طبيب غير معروف"
                                        : "Unknown Doctor"),
                              ),
                              subtitle: Text(
                                doctor["address"] ??
                                    (isArabic
                                        ? "العنوان غير متوفر"
                                        : "Address not available"),
                              ),
                              trailing: const Icon(
                                Icons.arrow_forward_ios,
                                size: 16,
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DoctorDetailsPage(
                                      doctorName: doctor["fullName"] ?? "",
                                      description:
                                      doctor["description"] ?? "",
                                      staffId: doctor["staffId"] ?? "",
                                      address: doctor["address"] ?? "",
                                      lat: doctor["location"]?["lat"] != null
                                          ? double.tryParse(
                                        doctor["location"]["lat"]
                                            .toString(),
                                      )
                                          : null,
                                      lng: doctor["location"]?["lng"] != null
                                          ? double.tryParse(
                                        doctor["location"]["lng"]
                                            .toString(),
                                      )
                                          : null,
                                      specialization:
                                      doctor["specialization"] ?? "",
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
}
