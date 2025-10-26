import 'package:flutter/material.dart';

class ViewFeedbackPage extends StatelessWidget {
  const ViewFeedbackPage({super.key});

  final List<Map<String, String>> feedbackList = const [
    {
      'type': 'Patient',
      'name': 'Reem AlAli',
      'feedback': 'The app is easy to use and helps me track my appointments effectively.'
    },
    {
      'type': 'Doctor',
      'name': 'Dr. Sarah Johnson',
      'feedback': 'The system is useful but needs improvement in loading speed.'
    },
    {
      'type': 'Patient',
      'name': 'Mona Saleh',
      'feedback': 'I love the AI chatbot feature. Very responsive and helpful.'
    },
    {
      'type': 'Doctor',
      'name': 'Dr. Ahmed Hassan',
      'feedback': 'It would be great to have dark mode support in the doctor dashboard.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('View Feedback', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: ListView.builder(
        itemCount: feedbackList.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final feedback = feedbackList[index];
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              leading: Icon(
                feedback['type'] == 'Doctor' ? Icons.medical_services : Icons.person,
                color: Colors.purple,
              ),
              title: Text('${feedback['type']}: ${feedback['name']}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(feedback['feedback']!),
              ),
            ),
          );
        },
      ),
    );
  }
}
