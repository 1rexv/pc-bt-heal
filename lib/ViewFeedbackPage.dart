import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ViewFeedbackPage extends StatefulWidget {
  const ViewFeedbackPage({super.key});

  @override
  State<ViewFeedbackPage> createState() => _ViewFeedbackPageState();
}

class _ViewFeedbackPageState extends State<ViewFeedbackPage> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _feedbackList = [];

  @override
  void initState() {
    super.initState();
    _loadFeedback();
  }

  Future<void> _loadFeedback() async {
    try {
      final db = FirebaseDatabase.instance.ref();

      // 🔹 1) Feedback from patients (node: feedback)
      final patientSnap = await db.child('feedback').get();

      final List<Map<String, dynamic>> loaded = [];

      if (patientSnap.exists) {
        final data = patientSnap.value as Map;

        data.forEach((key, value) {
          final v = Map<String, dynamic>.from(value);

          loaded.add({
            'type': 'Patient',
            'name': v['patientEmail'] ?? 'Unknown patient',
            'feedback':
            'About Doctor: ${v['doctorName'] ?? 'Unknown doctor'}\n\n'
                'Doctor feedback: ${v['doctorFeedback'] ?? '-'}\n'
                'System feedback: ${v['systemFeedback'] ?? '-'}\n'
                'Rating: ${v['rating'] ?? '-'} / 5',
            'createdAt': v['createdAt'] ?? 0,
          });
        });
      }

      // 🔹 2) Feedback from doctors (node: systemDoctorFeedback)
      final doctorSnap = await db.child('systemDoctorFeedback').get();

      if (doctorSnap.exists) {
        final data = doctorSnap.value as Map;

        data.forEach((key, value) {
          final v = Map<String, dynamic>.from(value);

          loaded.add({
            'type': 'Doctor',
            'name': v['doctorName'] ??
                v['doctorEmail'] ??
                'Unknown doctor',
            'feedback': v['feedback'] ?? '',
            'createdAt': v['createdAt'] ?? 0,
          });
        });
      }

      // 🔹 Sort by date (latest first)
      loaded.sort((a, b) =>
          (b['createdAt'] as int).compareTo(a['createdAt'] as int));

      setState(() {
        _feedbackList = loaded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading feedback: $e')),
      );
    }
  }

  String _formatDate(int millis) {
    if (millis == 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple;

    return Scaffold(
      appBar: AppBar(
        title: const Text('View Feedback', style: TextStyle(color: Colors.white)),
        backgroundColor: purple,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.purple),
      )
          : _feedbackList.isEmpty
          ? const Center(
        child: Text('No feedback found'),
      )
          : ListView.builder(
        itemCount: _feedbackList.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final feedback = _feedbackList[index];
          final type = feedback['type'] as String;
          final name = feedback['name'] as String;
          final text = feedback['feedback'] as String;
          final createdAt = feedback['createdAt'] as int;

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 3,
            child: ListTile(
              leading: Icon(
                type == 'Doctor' ? Icons.medical_services : Icons.person,
                color: purple,
              ),
              title: Text(
                '$type: $name',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(text),
                    if (createdAt != 0) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Date: ${_formatDate(createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
