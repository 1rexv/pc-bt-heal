import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RespondToProblemsPage extends StatefulWidget {
  const RespondToProblemsPage({super.key});

  @override
  State<RespondToProblemsPage> createState() => _RespondToProblemsPageState();
}

class _RespondToProblemsPageState extends State<RespondToProblemsPage> {
  final DatabaseReference _problemsRef =
  FirebaseDatabase.instance.ref('problems');

  bool _showHistory = false;

  @override
  Widget build(BuildContext context) {
    final currentDoctor = FirebaseAuth.instance.currentUser;

    final isArabic = Localizations.localeOf(context)
        .languageCode
        .toLowerCase()
        .startsWith('ar');

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'الرد على مشاكل المرضى' : 'Respond to Patient Problems',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(
                _showHistory ? Icons.forum : Icons.history,
                color: Colors.white,
              ),
              tooltip: _showHistory
                  ? (isArabic ? 'عرض المشاكل الحالية' : 'Show Active Problems')
                  : (isArabic ? 'عرض سجل الردود' : 'Show Message History'),
              onPressed: () {
                setState(() => _showHistory = !_showHistory);
              },
            ),
          ],
        ),
        body: StreamBuilder(
          stream: _problemsRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData ||
                (snapshot.data! as DatabaseEvent).snapshot.value == null) {
              return Center(
                child: Text(
                  isArabic ? 'لا توجد مشاكل' : 'No problems found.',
                ),
              );
            }

            final data = Map<String, dynamic>.from(
              (snapshot.data! as DatabaseEvent).snapshot.value as Map,
            );

            final doctorProblems = data.values
                .map((e) => Map<String, dynamic>.from(e))
                .where((p) => p['doctorId'] == currentDoctor?.uid)
                .toList();

            final pendingProblems = doctorProblems
                .where((p) => (p['response'] ?? '').toString().isEmpty)
                .toList();

            final historyProblems = doctorProblems
                .where((p) => (p['response'] ?? '').toString().isNotEmpty)
                .toList();

            final displayList =
            _showHistory ? historyProblems : pendingProblems;

            if (displayList.isEmpty) {
              return Center(
                child: Text(
                  _showHistory
                      ? (isArabic
                      ? 'لا يوجد سجل ردود بعد'
                      : 'No message history yet.')
                      : (isArabic
                      ? 'لا توجد مشاكل بانتظار الرد'
                      : 'No pending problems.'),
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: displayList.length,
              itemBuilder: (context, index) {
                final problem = displayList[index];
                final responseController =
                TextEditingController(text: problem['response'] ?? '');

                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FutureBuilder<String>(
                          future: _getPatientName(problem['patientId']),
                          builder: (context, snap) {
                            final name = snap.data ??
                                (isArabic ? 'غير معروف' : 'Unknown');
                            return Row(
                              children: [
                                const Icon(Icons.person,
                                    color: Colors.purple),
                                const SizedBox(width: 6),
                                Text(
                                  isArabic ? 'المريضة: $name' : 'Patient: $name',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 10),
                        Text(
                          isArabic ? 'المشكلة:' : 'Problem:',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(problem['problemText'] ?? ''),
                        ),
                        const SizedBox(height: 12),

                        /// HISTORY
                        if (_showHistory)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic
                                    ? 'رد الطبيب:'
                                    : "Doctor's Response:",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  problem['response'],
                                  style: const TextStyle(
                                      color: Colors.green),
                                ),
                              ),
                            ],
                          )

                        /// ACTIVE
                        else
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isArabic ? 'ردك:' : 'Your Response:',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 6),
                              TextField(
                                controller: responseController,
                                maxLines: 3,
                                decoration: InputDecoration(
                                  hintText: isArabic
                                      ? 'اكتب ردك هنا...'
                                      : 'Type your response...',
                                  filled: true,
                                  fillColor: Colors.grey.shade100,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Align(
                                alignment: isArabic
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.send,
                                      color: Colors.white),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                  ),
                                  label: Text(
                                    isArabic ? 'إرسال الرد' : 'Send Response',
                                    style:
                                    const TextStyle(color: Colors.white),
                                  ),
                                  onPressed: () async {
                                    final text =
                                    responseController.text.trim();
                                    if (text.isEmpty) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(isArabic
                                              ? 'لا يمكن إرسال رد فارغ'
                                              : 'Response cannot be empty'),
                                        ),
                                      );
                                      return;
                                    }

                                    await _problemsRef
                                        .child(problem['problemId'])
                                        .update({'response': text});

                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(
                                      SnackBar(
                                        content: Text(isArabic
                                            ? 'تم إرسال الرد بنجاح'
                                            : 'Response sent successfully'),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<String> _getPatientName(String patientId) async {
    final snap =
    await FirebaseDatabase.instance.ref('users/$patientId').get();
    if (snap.exists) {
      final data = Map<String, dynamic>.from(snap.value as Map);
      return data['name'] ?? '';
    }
    return '';
  }
}
