import 'package:flutter/material.dart';
import 'AcceptAppointmentsPage.dart';
import 'DoctorReportPage.dart';
import 'DoctorFeedbackPage.dart';
import 'AddUpdateMedicinePage.dart';
import 'RespondToProblemsPage.dart';

class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Doctor Dashboard', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.calendar_today, color: Colors.purple),
              title: const Text('Accept Appointments for Patients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AcceptAppointmentsPage()),
                );
                },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.comment, color: Colors.purple),
              title: const Text('Respond to Patient Problems', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RespondToProblemsPage()),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.medical_services, color: Colors.purple),
              title: const Text('Add / Update Medicine Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddUpdateMedicinePage()),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.feedback, color: Colors.purple),
              title: const Text('Send Feedback to Admin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DoctorFeedbackPage()),
                );
              },
            ),
          ),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.report, color: Colors.purple),
              title: const Text('Report', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => DoctorReportPage()),
                );
              },

            ),
          ),
        ],
      ),
    );
  }
}
