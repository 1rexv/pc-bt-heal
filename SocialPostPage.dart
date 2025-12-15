import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class TrackProgressPage extends StatefulWidget {
  const TrackProgressPage({super.key});

  @override
  State<TrackProgressPage> createState() => _TrackProgressPageState();
}

class _TrackProgressPageState extends State<TrackProgressPage> {
  final DatabaseReference db = FirebaseDatabase.instance.ref();

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(String en, String ar) => _isArabic ? ar : en;

  Future<int> _getCount(String path) async {
    final snapshot = await db.child(path).get();
    if (snapshot.exists) {
      final data = snapshot.value;
      if (data is Map) return data.length;
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
    final purple = Colors.purple;
    final isArabic = _isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('System Progress Report', 'تقرير تقدم النظام'),
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: purple,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFutureCard(
            _t('Total Registered Doctors', 'إجمالي الأطباء المسجلين'),
            Icons.medical_services,
            _getCount("doctors"),
            isArabic,
          ),
          _buildFutureCard(
            _t('Total Registered Patients', 'إجمالي المرضى المسجلين'),
            Icons.people,
            _getCount("patients"),
            isArabic,
          ),
          _buildFutureCard(
            _t('Appointments Scheduled', 'المواعيد المجدولة'),
            Icons.calendar_today,
            _getAppointmentsCount(),
            isArabic,
          ),
          _buildFutureCard(
            _t('Medicines Added', 'الأدوية المضافة'),
            Icons.medication,
            _getCount("medicines"),
            isArabic,
          ),
          _buildFutureCard(
            _t('Total Feedbacks Received', 'إجمالي الملاحظات المستلمة'),
            Icons.feedback,
            _getFeedbackCount(),
            isArabic,
          ),
          _buildFutureCard(
            _t('AI Chatbot Interactions', 'تفاعلات الشات بوت'),
            Icons.chat,
            _getChatCount(),
            isArabic,
          ),
          _buildFutureCard(
            _t('Scans Uploaded', 'الفحوصات المرفوعة'),
            Icons.image,
            _getScansCount(),
            isArabic,
          ),
        ],
      ),
    );
  }

  Widget _buildFutureCard(String title, IconData icon, Future<int> futureCount, bool isArabic) {
    return FutureBuilder<int>(
      future: futureCount,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildReportCard(title, _tStatic('Loading...', 'جاري التحميل...'), icon, isArabic);
        }
        if (snapshot.hasError) {
          return _buildReportCard(title, _tStatic('Error', 'خطأ'), icon, isArabic);
        }
        final value = (snapshot.data ?? 0).toString();
        return _buildReportCard(title, value, icon, isArabic);
      },
    );
  }

  // helper that doesn't access context (used from places where context may be different)
  String _tStatic(String en, String ar) {
    try {
      return _t(en, ar);
    } catch (_) {
      // fallback if context not available
      return en;
    }
  }

  Widget _buildReportCard(String title, String value, IconData icon, bool isArabic) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: ListTile(
        leading: Icon(icon, color: Colors.purple, size: 30),
        title: Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          textAlign: isArabic ? TextAlign.right : TextAlign.left,
        ),
        trailing: Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.purple),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}
