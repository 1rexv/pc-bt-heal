import 'package:flutter/material.dart';

class SendFeedbackPage extends StatefulWidget {
  const SendFeedbackPage({super.key});

  @override
  State<SendFeedbackPage> createState() => _SendFeedbackPageState();
}

class _SendFeedbackPageState extends State<SendFeedbackPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController systemFeedbackController = TextEditingController();
  final TextEditingController doctorFeedbackController = TextEditingController();
  String? selectedDoctor;
  double rating = 3;

  final List<String> doctors = [
    'Dr. Amina Hassan',
    'Dr. Sarah Ali',
    'Dr. Lina Kareem',
  ];

  void _submitFeedback() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feedback submitted successfully!')),
      );
      // TODO: Send data to backend or store locally

      // Clear form
      setState(() {
        selectedDoctor = null;
        systemFeedbackController.clear();
        doctorFeedbackController.clear();
        rating = 3;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Send Feedback", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const Text("Select Doctor", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedDoctor,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: doctors.map((doctor) {
                  return DropdownMenuItem<String>(
                    value: doctor,
                    child: Text(doctor),
                  );
                }).toList(),
                onChanged: (value) => setState(() => selectedDoctor = value),
                validator: (value) => value == null ? "Please select a doctor" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: doctorFeedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Feedback about Doctor",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? "Enter feedback about doctor" : null,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: systemFeedbackController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Feedback about the System",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? "Enter system feedback" : null,
              ),
              const SizedBox(height: 20),
              const Text("Rate your experience (1-5 stars)", style: TextStyle(fontWeight: FontWeight.bold)),
              Slider(
                value: rating,
                min: 1,
                max: 5,
                divisions: 4,
                label: rating.toStringAsFixed(0),
                activeColor: Colors.purple,
                onChanged: (value) => setState(() => rating = value),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _submitFeedback,
                child: const Text("Submit Feedback", style: TextStyle(color: Colors.white)),
              )
            ],
          ),
        ),
      ),
    );
  }
}
