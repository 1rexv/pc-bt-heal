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
  final TextEditingController systemFeedbackController = TextEditingController();
  final TextEditingController doctorFeedbackController = TextEditingController();

  String? selectedDoctorEmail;
  String? selectedDoctorName;

  double rating = 3;
  bool _loadingDoctors = true;
  bool _isSubmitting = false;

  List<Map<String, String>> doctorsList = [];


  Future<void> fetchDoctors() async {
    final ref = FirebaseDatabase.instance.ref("doctors");

    final snapshot = await ref.get();

    if (snapshot.exists) {
      final data = snapshot.value as Map;

      doctorsList = data.entries
          .map((e) => {
        "email": e.value["email"].toString(),
        "name": e.value["fullName"].toString(),
        "enabled": e.value["enabled"].toString(),
      })
          .where((doc) => doc["enabled"] == "true")
          .toList();
    }

    setState(() => _loadingDoctors = false);
  }

  @override
  void initState() {
    super.initState();
    fetchDoctors();
  }


  Future<void> _submitFeedback() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in.")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final ref = FirebaseDatabase.instance.ref("feedback").push();

      await ref.set({
        "doctorEmail": selectedDoctorEmail,     
        "doctorName": selectedDoctorName,      
        "doctorFeedback": doctorFeedbackController.text.trim(),
        "systemFeedback": systemFeedbackController.text.trim(),
        "rating": rating,
        "patientEmail": user.email,
        "createdAt": DateTime.now().millisecondsSinceEpoch,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Feedback sent successfully!")),
      );

      setState(() {
        selectedDoctorEmail = null;
        selectedDoctorName = null;
        doctorFeedbackController.clear();
        systemFeedbackController.clear();
        rating = 3;
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error sending: $e")),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Feedback", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: purple,
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
              const Text(
                "Select Doctor",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                value: selectedDoctorEmail,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: doctorsList.map((doc) {
                  return DropdownMenuItem(
                    value: doc["email"],
                    child: Text("${doc['name']}  (${doc['email']})"),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedDoctorEmail = value;
                    selectedDoctorName = doctorsList
                        .firstWhere((d) => d["email"] == value)["name"];
                  });
                },
                validator: (value) =>
                value == null ? "Please select a doctor" : null,
              ),

              const SizedBox(height: 20),

              // Doctor feedback
              TextFormField(
                controller: doctorFeedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Feedback about Doctor",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Enter feedback" : null,
              ),

              const SizedBox(height: 20),

              // System feedback
              TextFormField(
                controller: systemFeedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Feedback about the System",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                value == null || value.isEmpty ? "Enter system feedback" : null,
              ),

              const SizedBox(height: 20),

              const Text(
                "Rate your experience (1-5 stars)",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),

              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: rating.toStringAsFixed(0),
                activeColor: purple,
                onChanged: (v) => setState(() => rating = v),
              ),

              const SizedBox(height: 30),

              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitFeedback,
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Feedback",
                    style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
