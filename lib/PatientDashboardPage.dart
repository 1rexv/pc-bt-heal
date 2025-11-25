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

  // Speech-to-text
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speechAvailable = await _speech.initialize(
      onStatus: (status) {
        debugPrint("Speech status: $status");
      },
      onError: (error) {
        debugPrint("Speech error: $error");
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Speech error: ${error.errorMsg}')),
          );
        }
      },
    );

    if (!_speechAvailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Voice search is not available. Check microphone permission or device.'),
        ),
      );
    }
  }

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

  // Start or stop listening
  void _toggleVoiceSearch() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Speech recognition not available. Make sure mic permission is allowed.'),
        ),
      );
      return;
    }

    if (!_isListening) {
      setState(() => _isListening = true);

      _speech.listen(
        // You can set localeId if you want a specific language, e.g. 'en_US' or 'ar_SA'
        // localeId: 'en_US',
        onResult: (result) {
          setState(() {
            _searchController.text = result.recognizedWords;
            _searchQuery = result.recognizedWords.toLowerCase();
          });
        },
      );
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  bool _matchesSearch(Map<String, dynamic> doctor) {
    if (_searchQuery.isEmpty) return true;
    final name = (doctor["fullName"] ?? "").toString().toLowerCase();
    final address = (doctor["address"] ?? "").toString().toLowerCase();
    return name.contains(_searchQuery) || address.contains(_searchQuery);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Patient Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            tooltip: 'Sign Out',
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.purple),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Welcome Patient',
                      style: TextStyle(color: Colors.white, fontSize: 22)),
                  SizedBox(height: 8),
                  Text('Menu Options', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Personal Profile'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PatientProfilePage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.smart_toy),
              title: const Text('AI Chatbot'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AIChatbotPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.medical_services),
              title: const Text('Medication Info'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MedicationInfoPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.feedback),
              title: const Text('Send Feedback'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendFeedbackPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.warning_amber),
              title: const Text('Send Problem'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SendProblemPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_month),
              title: const Text('Booked Appointments'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BookedAppointmentsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.location_city),
              title: const Text('Location'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ClinicHospitalPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search + Voice search
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search doctor by name or address',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
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

            // Doctor List
            Expanded(
              child: StreamBuilder(
                stream: doctorsRef.onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading doctors"));
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Center(child: Text("No doctors found"));
                  }

                  final data = Map<String, dynamic>.from(
                    (snapshot.data! as DatabaseEvent).snapshot.value as Map,
                  );

                  // Only hide doctor if explicitly disabled
                  final doctors = data.entries
                      .map(
                        (e) =>
                        MapEntry(e.key, Map<String, dynamic>.from(e.value)),
                  )
                      .where((entry) {
                    final doctor = entry.value;
                    final hasEnabled = doctor.containsKey("enabled");
                    final isDisabled = hasEnabled && doctor["enabled"] == false;
                    return !isDisabled && _matchesSearch(doctor);
                  }).toList();

                  if (doctors.isEmpty) {
                    return const Center(
                        child: Text("No doctors match your search."));
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
                                    "assets/images/doctor_placeholder.png")
                                as ImageProvider,
                              ),
                              title: Text(
                                  doctor["fullName"] ?? "Unknown Doctor"),
                              subtitle: Text(doctor["address"] ??
                                  "Address not available"),
                              trailing:
                              const Icon(Icons.arrow_forward_ios, size: 16),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => DoctorDetailsPage(
                                      doctorName:
                                      doctor["fullName"] ?? "",
                                      description:
                                      doctor["description"] ?? "",
                                      staffId:
                                      doctor["staffId"] ?? "",
                                      address:
                                      doctor["address"] ?? "",
                                      lat: doctor["location"]?["lat"] != null
                                          ? double.tryParse(doctor["location"]
                                      ["lat"]
                                          .toString())
                                          : null,
                                      lng: doctor["location"]?["lng"] != null
                                          ? double.tryParse(doctor["location"]
                                      ["lng"]
                                          .toString())
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
