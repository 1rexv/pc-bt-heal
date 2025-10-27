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
  final DatabaseReference _problemsRef =
  FirebaseDatabase.instance.ref('problems');

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  ///Load all doctors from Firebase
  Future<void> _loadDoctors() async {
    final snapshot = await FirebaseDatabase.instance.ref('doctors').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _doctors = data.entries.map((e) {
          final doctor = Map<String, dynamic>.from(e.value);
          return {
            'id': e.key,
            'name': doctor['fullName'] ?? 'Unknown Doctor',
          };
        }).toList();
      });
    }
  }

  ///Submit problem to Firebase
  Future<void> _submitQuestion() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedDoctorId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a doctor")),
        );
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please login first.")),
        );
        return;
      }

      final patientId = user.uid;
      final problemRef = _problemsRef.push();

      await problemRef.set({
        'problemId': problemRef.key,
        'patientId': patientId,
        'doctorId': _selectedDoctorId,
        'problemText': questionController.text.trim(),
        'response': '',
        'timestamp': DateTime.now().toIso8601String(),
      });

      questionController.clear();
      setState(() => _selectedDoctorId = null);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text(" Message Sent"),
          content: const Text(
            "Your problem has been sent successfully. The doctor will respond soon.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("OK", style: TextStyle(color: Colors.purple)),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ask Your Doctor", style: TextStyle(color: Colors.white)),
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
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 6,
                              offset: const Offset(0, 3))
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Send a Medical Question",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: const InputDecoration(
                              labelText: "Select Doctor",
                              border: OutlineInputBorder(),
                            ),
                            value: _selectedDoctorId,
                            items: _doctors.map((doc) {
                              return DropdownMenuItem<String>(
                                value: doc['id'].toString(),
                                child: Text(doc['name']?.toString() ?? ''),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedDoctorId = val),
                            validator: (v) =>
                            v == null ? "Please select a doctor" : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: questionController,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              labelText: "Describe your problem",
                              border: OutlineInputBorder(),
                              alignLabelWithHint: true,
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? "Please enter your problem"
                                : null,
                          ),
                          const SizedBox(height: 20),
                          Center(
                            child: ElevatedButton.icon(
                              icon: const Icon(Icons.send, color: Colors.white),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.purple,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              onPressed: _submitQuestion,
                              label: const Text(
                                "Send Problem",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              const Text(
                "Your Previous Problems",
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple),
              ),
              const SizedBox(height: 12),
              StreamBuilder(
                stream: _problemsRef
                    .orderByChild('patientId')
                    .equalTo(user?.uid)
                    .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData ||
                      snapshot.data!.snapshot.value == null) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 30),
                      child: Center(
                          child: Text("No problems submitted yet.",
                              style: TextStyle(color: Colors.grey))),
                    );
                  }

                  final data = Map<String, dynamic>.from(
                      (snapshot.data! as DatabaseEvent).snapshot.value as Map);
                  final problems = data.values
                      .map((e) => Map<String, dynamic>.from(e))
                      .toList()
                      .reversed
                      .toList();

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: problems.length,
                    itemBuilder: (context, index) {
                      final p = problems[index];
                      final hasResponse = (p['response'] ?? '').toString().isNotEmpty;

                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_outline,
                                      color: Colors.purple),
                                  const SizedBox(width: 8),
                                  FutureBuilder(
                                    future: _getDoctorName(p['doctorId']),
                                    builder: (context, snapshot) {
                                      return Text(
                                        snapshot.data ?? "Doctor",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold),
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
                                  color: hasResponse
                                      ? Colors.green.shade50
                                      : Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: hasResponse
                                          ? Colors.green
                                          : Colors.orange),
                                ),
                                child: Text(
                                  hasResponse
                                      ? "Doctor’s Response: ${p['response']}"
                                      : "Waiting for doctor’s response...",
                                  style: TextStyle(
                                    color: hasResponse
                                        ? Colors.green.shade800
                                        : Colors.orange.shade800,
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
    );
  }

  //Fetch doctor’s name
  Future<String> _getDoctorName(String doctorId) async {
    final snapshot =
    await FirebaseDatabase.instance.ref('doctors/$doctorId').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      return data['fullName'] ?? 'Doctor';
    }
    return 'Doctor';
  }
}
