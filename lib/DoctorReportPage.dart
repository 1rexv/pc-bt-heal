import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DoctorReportPage extends StatefulWidget {
  final FirebaseDatabase database; // allows mock injection for tests

  DoctorReportPage({super.key, FirebaseDatabase? database})
      : database = database ?? FirebaseDatabase.instance;

  @override
  State<DoctorReportPage> createState() => _DoctorReportPageState();
}

class _DoctorReportPageState extends State<DoctorReportPage> {
  bool _isLoading = true;
  int _totalCases = 0;
  int _treatedCases = 0;
  int _pendingCases = 0;
  String doctorName = "";

  @override
  void initState() {
    super.initState();
    _loadDoctorReport();
  }

  Future<void> _loadDoctorReport() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    try {
      final appointmentsRef = widget.database.ref("appointments");

      final snapshot = await appointmentsRef
          .orderByChild("doctorEmail")
          .equalTo(currentUser.email)
          .get();

      int total = 0;
      int treated = 0;
      int pending = 0;

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        data.forEach((key, value) {
          final appointment = Map<String, dynamic>.from(value);
          total++;

          if (appointment["status"] == "completed" ||
              appointment["status"] == "treated") {
            treated++;
          } else {
            pending++;
          }

          doctorName = appointment["doctorName"] ?? doctorName;
        });
      }

      setState(() {
        _totalCases = total;
        _treatedCases = treated;
        _pendingCases = pending;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading doctor report: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Doctor Case Report',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '📊 Report for: ${doctorName.isNotEmpty ? doctorName : "Doctor"}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // Total cases
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.pregnant_woman,
                    color: Colors.purple),
                title: const Text('Total Cases'),
                trailing: Text(
                  '$_totalCases',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Treated cases
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading:
                const Icon(Icons.check_circle, color: Colors.green),
                title: const Text('Treated / Completed'),
                trailing: Text(
                  '$_treatedCases',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Pending cases
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.pending_actions,
                    color: Colors.orange),
                title: const Text('Pending'),
                trailing: Text(
                  '$_pendingCases',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
