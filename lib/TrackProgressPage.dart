import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TrackProgressPage extends StatefulWidget {
  const TrackProgressPage({super.key});

  @override
  State<TrackProgressPage> createState() => _TrackProgressPageState();
}

class _TrackProgressPageState extends State<TrackProgressPage> {
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  Future<int> _getCount(String path) async {
    final snapshot = await db.child(path).get();
    if (snapshot.exists) {
      final data = snapshot.value;
      if (data is Map) return data.length; // count number of children
    }
    return 0;
  }

  Future<int> _getAppointmentsCount() async {
    final snapshot = await db.child("appointments").get();
    if (snapshot.exists) {
      final data = snapshot.value;
      if (data is Map) return data.length;
    }
    return 0;
  }

  Future<int> _getFeedbackCount() async {
    final snapshot = await db.child("feedback").get();
    if (snapshot.exists) {
      final data = snapshot.value;
      if (data is Map) return data.length;
    }
    return 0;
  }

  Future<int> _getChatCount() async {
    final snapshot = await db.child("chatLogs").get();
    if (snapshot.exists) {
      final data = snapshot.value;
      if (data is Map) return data.length;
    }
    return 0;
  }

  Future<int> _getScansCount() async {
    final snapshot = await db.child("scans").get();
    if (snapshot.exists) {
      final data = snapshot.value;
      if (data is Map) return data.length;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('System Progress Report', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFutureCard('Total Registered Doctors', Icons.medical_services, _getCount("doctors")),
          _buildFutureCard('Total Registered Patients', Icons.people, _getCount("patients")),
          _buildFutureCard('Appointments Scheduled', Icons.calendar_today, _getAppointmentsCount()),
          _buildFutureCard('Medicines Added', Icons.medication, _getCount("medicines")),
          _buildFutureCard('Total Feedbacks Received', Icons.feedback, _getFeedbackCount()),
          _buildFutureCard('AI Chatbot Interactions', Icons.chat, _getChatCount()),],
      ),
    );
  }

  Widget _buildFutureCard(String title, IconData icon, Future<int> futureCount) {
    return FutureBuilder<int>(
      future: futureCount,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildReportCard(title, "Loading...", icon);
        }
        if (snapshot.hasError) {
          return _buildReportCard(title, "Error", icon);
        }
        return _buildReportCard(title, snapshot.data.toString(), icon);
      },
    );
  }

  Widget _buildReportCard(String title, String value, IconData icon) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple, size: 30),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
        ),
      ),
    );
  }
}
