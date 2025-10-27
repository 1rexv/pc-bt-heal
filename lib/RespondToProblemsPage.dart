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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Respond to Patient Problems',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showHistory ? Icons.forum : Icons.history,
              color: Colors.white,
            ),
            tooltip: _showHistory ? "Show Active Problems" : "Show Message History",
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
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text('No problems found.'));
          }

          final data = Map<String, dynamic>.from(
              (snapshot.data! as DatabaseEvent).snapshot.value as Map);

          // Filter by doctor
          final doctorProblems = data.entries
              .map((e) => Map<String, dynamic>.from(e.value))
              .where((p) => p['doctorId'] == currentDoctor?.uid)
              .toList();

          // Separate pending and responded
          final pendingProblems =
          doctorProblems.where((p) => (p['response'] ?? '').isEmpty).toList();
          final historyProblems =
          doctorProblems.where((p) => (p['response'] ?? '').isNotEmpty).toList();

          final displayList = _showHistory ? historyProblems : pendingProblems;

          if (displayList.isEmpty) {
            return Center(
              child: Text(
                _showHistory
                    ? 'No message history yet.'
                    : 'No pending problems to respond to.',
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
                    borderRadius: BorderRadius.circular(14)),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.purple.shade50, Colors.white],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FutureBuilder(
                        future: _getPatientName(problem['patientId']),
                        builder: (context, snapshot) {
                          final patientName = snapshot.data ?? 'Unknown Patient';
                          return Row(
                            children: [
                              const Icon(Icons.person,
                                  color: Colors.purple, size: 22),
                              const SizedBox(width: 6),
                              Text(
                                "Patient: $patientName",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "🩺 Problem:",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          problem['problemText'] ?? '',
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (_showHistory)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "👨‍⚕️ Doctor’s Response:",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
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
                                  fontSize: 15,
                                  color: Colors.green,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        )
                      else
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "💬 Your Response:",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: responseController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: 'Type your response here...',
                                filled: true,
                                fillColor: Colors.grey.shade100,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                      color: Colors.purple.shade200),
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.purple,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24, vertical: 10),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                icon: const Icon(Icons.send,
                                    color: Colors.white, size: 18),
                                label: const Text(
                                  'Send Response',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15),
                                ),
                                onPressed: () async {
                                  final responseText =
                                  responseController.text.trim();
                                  if (responseText.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content:
                                          Text('Response cannot be empty')),
                                    );
                                    return;
                                  }

                                  await _problemsRef
                                      .child(problem['problemId'])
                                      .update({'response': responseText});

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                        Text('Response sent successfully!')),
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
    );
  }

  //Fetch patient's name from Firebase
  Future<String> _getPatientName(String patientId) async {
    final snapshot =
    await FirebaseDatabase.instance.ref('users/$patientId').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data['name'] ?? 'Unknown';
    }
    return 'Unknown';
  }
}
