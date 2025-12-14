import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DoctorReportPage extends StatefulWidget {
  const DoctorReportPage({super.key});

  @override
  State<DoctorReportPage> createState() => _DoctorReportPageState();
}

class _DoctorReportPageState extends State<DoctorReportPage> {
  bool _isLoading = true;
  int _totalCases = 0;
  int _treatedCases = 0;
  int _pendingCases = 0;
  String doctorName = "";

  final FirebaseDatabase _database = FirebaseDatabase.instance;

  @override
  void initState() {
    super.initState();
    _loadDoctorReport();
  }

  Future<void> _loadDoctorReport() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final ref = _database.ref("appointments");

      final snapshot = await ref
          .orderByChild("doctorEmail")
          .equalTo(currentUser.email)
          .get();

      int total = 0;
      int treated = 0;
      int pending = 0;
      String name = "";

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        for (final value in data.values) {
          final appointment = Map<String, dynamic>.from(value);

          total++;

          final status = appointment["status"]?.toString().toLowerCase();

          if (status == "completed" || status == "treated") {
            treated++;
          } else {
            pending++;
          }

          name = appointment["doctorName"] ?? name;
        }
      }

      setState(() {
        _totalCases = total;
        _treatedCases = treated;
        _pendingCases = pending;
        doctorName = name;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error loading report: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = Directionality.of(context) == TextDirection.rtl;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? 'تقرير حالات الطبيب' : 'Doctor Case Report',
            style: const TextStyle(color: Colors.white),
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
                isArabic
                    ? '📊 تقرير الدكتور: ${doctorName.isNotEmpty ? doctorName : "غير معروف"}'
                    : '📊 Report for: ${doctorName.isNotEmpty ? doctorName : "Doctor"}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              _buildCard(
                icon: Icons.pregnant_woman,
                color: Colors.purple,
                title:
                isArabic ? 'إجمالي الحالات' : 'Total Cases',
                value: _totalCases,
              ),
              const SizedBox(height: 16),

              _buildCard(
                icon: Icons.check_circle,
                color: Colors.green,
                title: isArabic
                    ? 'الحالات المعالجة'
                    : 'Treated / Completed',
                value: _treatedCases,
              ),
              const SizedBox(height: 16),

              _buildCard(
                icon: Icons.pending_actions,
                color: Colors.orange,
                title:
                isArabic ? 'الحالات المعلقة' : 'Pending',
                value: _pendingCases,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required IconData icon,
    required Color color,
    required String title,
    required int value,
  }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: color, size: 28),
        title: Text(title),
        trailing: Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
