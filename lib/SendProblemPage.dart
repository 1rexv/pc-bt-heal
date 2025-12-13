import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SendProblemPage extends StatefulWidget {
  const SendProblemPage({super.key});

  @override
  State<SendProblemPage> createState() => _SendProblemPageState();
}

class _SendProblemPageState extends State<SendProblemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController questionController = TextEditingController();

  String? _selectedDoctorId;
  List<Map<String, dynamic>> _doctors = [];
  final DatabaseReference _problemsRef = FirebaseDatabase.instance.ref('problems');
  final DatabaseReference _doctorsRef = FirebaseDatabase.instance.ref('doctors');
  final DatabaseReference _doctorNotificationsRef = FirebaseDatabase.instance.ref('doctorNotifications');

  bool _loadingDoctors = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  @override
  void dispose() {
    questionController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctors() async {
    setState(() => _loadingDoctors = true);
    try {
      final snapshot = await _doctorsRef.get();
      final List<Map<String, dynamic>> loaded = [];

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        for (final entry in data.entries) {
          try {
            final id = entry.key;
            final v = Map<String, dynamic>.from(entry.value as Map);
            final enabledRaw = v['enabled'];
            final enabled = (enabledRaw == true) || (enabledRaw?.toString().toLowerCase() == 'true');

            if (!enabled) continue;

            final fullName = (v['fullName'] ?? '').toString();
            loaded.add({
              'id': id,
              'name': fullName.isEmpty ? (v['email'] ?? 'Doctor') : fullName,
            });
          } catch (_) {
            // skip malformed entry
            continue;
          }
        }
      }

      setState(() {
        _doctors = loaded;
        if (_doctors.isNotEmpty && _selectedDoctorId == null) {
          _selectedDoctorId = _doctors.first['id'] as String?;
        }
      });
    } catch (e) {
      debugPrint('Error loading doctors: $e');
    } finally {
      if (mounted) setState(() => _loadingDoctors = false);
    }
  }

  Future<void> _submitQuestion() async {
    final isArabic =
    Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

    if (!_formKey.currentState!.validate()) return;

    if (_selectedDoctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'الرجاء اختيار طبيب.' : 'Please select a doctor.')),
      );
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'الرجاء تسجيل الدخول أولاً.' : 'Please login first.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // create problem entry
      final problemRef = _problemsRef.push();
      final problemId = problemRef.key;

      final payload = {
        'problemId': problemId,
        'patientId': user.uid,
        'patientEmail': user.email ?? '',
        'doctorId': _selectedDoctorId,
        'problemText': questionController.text.trim(),
        'response': '',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await problemRef.set(payload);

      // send a simple notification record for the doctor (so doctor's UI / service can pick it up)
      // structure: doctorNotifications/{doctorId}/{pushId}
      final notifRef = _doctorNotificationsRef.child(_selectedDoctorId!).push();
      final notifTitle = isArabic ? 'سؤال طبي جديد' : 'New patient question';
      final notifBodyAr = 'مريضة أرسلت سؤالاً. افتح القائمة للرد.';
      final notifBodyEn = 'A patient has asked a question. Open the problems list to respond.';

      await notifRef.set({
        'doctorId': _selectedDoctorId,
        'patientId': user.uid,
        'patientEmail': user.email ?? '',
        'problemId': problemId,
        'type': 'patient_question',
        'title': notifTitle,
        'body': isArabic ? notifBodyAr : notifBodyEn,
        'createdAt': ServerValue.timestamp,
        'read': false,
      });

      // clear form and show success dialog
      questionController.clear();
      setState(() => _selectedDoctorId = null);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(isArabic ? 'تم الإرسال' : 'Message Sent'),
          content: Text(isArabic
              ? 'تم إرسال مشكلتك بنجاح. سيقوم الطبيب بالرد قريبًا.'
              : 'Your problem has been sent successfully. The doctor will respond soon.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(isArabic ? 'حسناً' : 'OK', style: const TextStyle(color: Colors.purple)),
            )
          ],
        ),
      );
    } catch (e) {
      debugPrint('Submit question error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isArabic ? 'حدث خطأ أثناء الإرسال.' : 'Error while sending.')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<String> _getDoctorName(String? doctorId) async {
    if (doctorId == null) return '';
    try {
      final snap = await _doctorsRef.child(doctorId).get();
      if (snap.exists) {
        final data = Map<String, dynamic>.from(snap.value as Map);
        return (data['fullName'] ?? data['email'] ?? 'Doctor').toString();
      }
    } catch (_) {}
    return 'Doctor';
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
    Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

    final titleText = isArabic ? 'اسأل طبيبك' : 'Ask Your Doctor';
    final selectDoctorLabel = isArabic ? 'اختيار الطبيب' : 'Select Doctor';
    final describeLabel = isArabic ? 'صف مشكلتك' : 'Describe your problem';
    final sendButton = isArabic ? 'إرسال المشكلة' : 'Send Problem';
    final previousProblems = isArabic ? 'مشاكلك السابقة' : 'Your Previous Problems';
    final noProblemsText = isArabic ? 'لا توجد مشكلات سابقة.' : 'No problems submitted yet.';
    final loadingDoctorsText = isArabic ? 'جارٍ تحميل الأطباء...' : 'Loading doctors...';
    final noDoctorsText = isArabic ? 'لا يوجد أطباء متاحين حالياً.' : 'No available doctors right now.';

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(titleText, style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.purple,
          centerTitle: true,
        ),
        body: Container(
          color: Colors.grey.shade100,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                                color: Colors.black.withOpacity(0.08),
                                blurRadius: 6,
                                offset: const Offset(0, 3))
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isArabic ? 'أرسل سؤالًا طبيًا' : 'Send a Medical Question',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple,
                              ),
                            ),
                            const SizedBox(height: 16),

                            // Doctors dropdown or message
                            _loadingDoctors
                                ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Row(
                                children: [
                                  const SizedBox(width: 4),
                                  const CircularProgressIndicator(color: Colors.purple),
                                  const SizedBox(width: 12),
                                  Text(loadingDoctorsText),
                                ],
                              ),
                            )
                                : _doctors.isEmpty
                                ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Card(
                                color: Colors.yellow[50],
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(noDoctorsText),
                                ),
                              ),
                            )
                                : DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: selectDoctorLabel,
                                border: OutlineInputBorder(),
                              ),
                              value: _selectedDoctorId,
                              items: _doctors.map((doc) {
                                return DropdownMenuItem<String>(
                                  value: doc['id'].toString(),
                                  child: Text(doc['name']?.toString() ?? ''),
                                );
                              }).toList(),
                              onChanged: (val) => setState(() => _selectedDoctorId = val),
                              validator: (v) => v == null ? (isArabic ? 'الرجاء اختيار طبيب' : 'Please select a doctor') : null,
                            ),

                            const SizedBox(height: 16),

                            TextFormField(
                              controller: questionController,
                              maxLines: 5,
                              decoration: InputDecoration(
                                labelText: describeLabel,
                                border: const OutlineInputBorder(),
                                alignLabelWithHint: true,
                              ),
                              validator: (value) => value == null || value.isEmpty
                                  ? (isArabic ? 'الرجاء إدخال المشكلة' : 'Please enter your problem')
                                  : null,
                            ),

                            const SizedBox(height: 20),
                            Center(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.send, color: Colors.white),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                ),
                                onPressed: (_isSubmitting || _loadingDoctors || _doctors.isEmpty) ? null : _submitQuestion,
                                label: _isSubmitting
                                    ? SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                                    : Text(sendButton, style: const TextStyle(color: Colors.white, fontSize: 16)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  previousProblems,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
                ),
                const SizedBox(height: 12),

                StreamBuilder(
                  stream: _problemsRef.orderByChild('patientId').equalTo(FirebaseAuth.instance.currentUser?.uid).onValue,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || (snapshot.data! as DatabaseEvent).snapshot.value == null) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 30),
                        child: Center(child: Text(noProblemsText, style: const TextStyle(color: Colors.grey))),
                      );
                    }

                    final data = Map<String, dynamic>.from((snapshot.data! as DatabaseEvent).snapshot.value as Map);
                    final problems = data.values.map((e) => Map<String, dynamic>.from(e)).toList().reversed.toList();

                    return ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: problems.length,
                      itemBuilder: (context, index) {
                        final p = problems[index];
                        final hasResponse = (p['response'] ?? '').toString().isNotEmpty;
                        final doctorId = p['doctorId']?.toString();

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.person_outline, color: Colors.purple),
                                    const SizedBox(width: 8),
                                    FutureBuilder(
                                      future: _getDoctorName(doctorId),
                                      builder: (context, snap) {
                                        return Text(
                                          snap.data?.toString() ?? (isArabic ? 'طبيب' : 'Doctor'),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "${p['problemText']}",
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 10),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: hasResponse ? Colors.green.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: hasResponse ? Colors.green : Colors.orange),
                                  ),
                                  child: Text(
                                    hasResponse
                                        ? "${isArabic ? 'رد الطبيب:' : "Doctor's Response:"} ${p['response']}"
                                        : (isArabic ? 'في انتظار رد الطبيب...' : "Waiting for doctor's response..."),
                                    style: TextStyle(
                                      color: hasResponse ? Colors.green.shade800 : Colors.orange.shade800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
