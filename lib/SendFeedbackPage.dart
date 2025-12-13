import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class SendFeedbackPage extends StatefulWidget {
  const SendFeedbackPage({super.key});

  @override
  State<SendFeedbackPage> createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController systemFeedbackController =
  TextEditingController();
  final TextEditingController doctorFeedbackController =
  TextEditingController();

  String? selectedDoctorEmail;
  String? selectedDoctorName;

  double rating = 3;
  bool _loadingDoctors = true;
  bool _isSubmitting = false;

  List<Map<String, String>> doctorsList = [];

  bool get isArabic =>
      Localizations.localeOf(context).languageCode.startsWith('ar');

  @override
  void initState() {
    super.initState();
    _fetchDoctors();
  }

  @override
  void dispose() {
    systemFeedbackController.dispose();
    doctorFeedbackController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
    try {
      final ref = FirebaseDatabase.instance.ref("doctors");
      final snapshot = await ref.get();

      final List<Map<String, String>> loaded = [];

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (final entry in data.entries) {
          final v = Map<String, dynamic>.from(entry.value);
          final enabled = v['enabled'] == true ||
              v['enabled']?.toString().toLowerCase() == 'true';

          if (!enabled) continue;

          final email = (v['email'] ?? '').toString();
          final name = (v['fullName'] ?? '').toString();

          if (email.isEmpty) continue;

          loaded.add({
            'email': email,
            'name': name.isEmpty ? email : name,
          });
        }
      }

      setState(() {
        doctorsList = loaded;
        if (doctorsList.isNotEmpty) {
          selectedDoctorEmail = doctorsList.first['email'];
          selectedDoctorName = doctorsList.first['name'];
        }
        _loadingDoctors = false;
      });
    } catch (e) {
      debugPrint('Fetch doctors error: $e');
      _loadingDoctors = false;
    }
  }

  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSubmitting = true);

    try {
      await FirebaseDatabase.instance.ref("feedback").push().set({
        "doctorEmail": selectedDoctorEmail,
        "doctorName": selectedDoctorName,
        "doctorFeedback": doctorFeedbackController.text.trim(),
        "systemFeedback": systemFeedbackController.text.trim(),
        "rating": rating.round(),
        "patientEmail": user.email,
        "createdAt": ServerValue.timestamp,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إرسال الملاحظات بنجاح'
                : 'Feedback sent successfully',
          ),
        ),
      );

      doctorFeedbackController.clear();
      systemFeedbackController.clear();
      rating = 3;
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          centerTitle: true,
          title: Text(
            isArabic ? 'إرسال ملاحظات' : 'Send Feedback',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: _loadingDoctors
            ? const Center(
          child: CircularProgressIndicator(color: Colors.purple),
        )
            : Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                Text(
                  isArabic ? 'اختر الطبيب' : 'Select Doctor',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),

                /// Doctor Dropdown
                DropdownButtonFormField<String>(
                  value: selectedDoctorEmail,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: doctorsList
                      .map<DropdownMenuItem<String>>((doc) {
                    return DropdownMenuItem<String>(
                      value: doc['email'],
                      child: Text(doc['name']!),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() {
                      selectedDoctorEmail = v;
                      selectedDoctorName = doctorsList
                          .firstWhere(
                              (d) => d['email'] == v)['name'];
                    });
                  },
                  validator: (v) => v == null
                      ? (isArabic
                      ? 'الرجاء اختيار طبيب'
                      : 'Please select a doctor')
                      : null,
                ),

                const SizedBox(height: 20),

                /// Feedback about Doctor
                TextFormField(
                  controller: doctorFeedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: isArabic
                        ? 'ملاحظات عن الطبيب'
                        : 'Feedback about Doctor',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? (isArabic
                      ? 'الرجاء كتابة ملاحظاتك'
                      : 'Please enter your feedback')
                      : null,
                ),

                const SizedBox(height: 20),

                /// Feedback about System
                TextFormField(
                  controller: systemFeedbackController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: isArabic
                        ? 'ملاحظات عن النظام'
                        : 'Feedback about the System',
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  validator: (v) => v == null || v.isEmpty
                      ? (isArabic
                      ? 'الرجاء كتابة ملاحظاتك'
                      : 'Please enter your feedback')
                      : null,
                ),

                const SizedBox(height: 20),

                Text(
                  isArabic
                      ? 'قيّم تجربتك (1 - 5)'
                      : 'Rate your experience (1 - 5)',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold),
                ),

                Slider(
                  value: rating,
                  min: 1,
                  max: 5,
                  divisions: 4,
                  label: rating.round().toString(),
                  activeColor: Colors.purple,
                  onChanged: (v) => setState(() => rating = v),
                ),

                const SizedBox(height: 30),

                ElevatedButton(
                  onPressed:
                  _isSubmitting ? null : _submitFeedback,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : Text(
                    isArabic ? 'إرسال' : 'Submit',
                    style: const TextStyle(
                        color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
