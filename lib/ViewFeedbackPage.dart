import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

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

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(String en, String ar) => _isArabic ? ar : en;

  Future<void> _loadFeedback() async {
    try {
      final db = FirebaseDatabase.instance.ref();

      // 1) Feedback from patients (node: feedback)
      final patientSnap = await db.child('feedback').get();

      final List<Map<String, dynamic>> loaded = [];

      if (patientSnap.exists && patientSnap.value != null) {
        final data = Map<String, dynamic>.from(patientSnap.value as Map);
        data.forEach((key, value) {
          final v = Map<String, dynamic>.from(value);
          loaded.add({
            'type': 'Patient',
            'name': v['patientEmail'] ?? 'Unknown patient',
            'feedback':
            '${_t("About Doctor:", "عن الطبيب:")} ${v['doctorName'] ?? _t("Unknown doctor", "طبيب غير معروف")}\n\n'
                '${_t("Doctor feedback:", "ملاحظات عن الطبيب:")} ${v['doctorFeedback'] ?? '-'}\n'
                '${_t("System feedback:", "ملاحظات عن النظام:")} ${v['systemFeedback'] ?? '-'}\n'
                '${_t("Rating:", "التقييم:")} ${v['rating'] ?? '-'} / 5',
            'createdAt': v['createdAt'] ?? 0,
          });
        });
      }

      // 2) Feedback from doctors (node: systemDoctorFeedback)
      final doctorSnap = await db.child('systemDoctorFeedback').get();

      if (doctorSnap.exists && doctorSnap.value != null) {
        final data = Map<String, dynamic>.from(doctorSnap.value as Map);
        data.forEach((key, value) {
          final v = Map<String, dynamic>.from(value);
          loaded.add({
            'type': 'Doctor',
            'name': v['doctorName'] ?? v['doctorEmail'] ?? _t('Unknown doctor', 'طبيب غير معروف'),
            'feedback': v['feedback'] ?? '',
            'createdAt': v['createdAt'] ?? 0,
          });
        });
      }

      // Sort by date (latest first)
      loaded.sort((a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int));

      if (!mounted) return;
      setState(() {
        _feedbackList = loaded;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t("Error loading feedback:", "خطأ في تحميل الملاحظات:")} $e')),
      );
    }
  }

  String _formatDate(int millis) {
    if (millis == 0) return '';
    try {
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      final locale = _isArabic ? 'ar' : 'en';
      return DateFormat.yMMMMd(locale).format(dt);
    } catch (_) {
      final dt = DateTime.fromMillisecondsSinceEpoch(millis);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple;
    final isArabic = _isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t('View Feedback', 'عرض الملاحظات'), style: const TextStyle(color: Colors.white)),
        backgroundColor: purple,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: purple))
          : _feedbackList.isEmpty
          ? Center(
        child: Text(
          _t('No feedback found', 'لا توجد ملاحظات'),
          style: const TextStyle(fontSize: 16, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
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

          final leadingIcon = type == 'Doctor' ? Icons.medical_services : Icons.person;
          final titlePrefix = type == 'Doctor' ? _t('Doctor', 'الطبيب') : _t('Patient', 'المريض');

          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 3,
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              leading: CircleAvatar(
                radius: 24,
                backgroundColor: purple.withOpacity(0.12),
                child: Icon(leadingIcon, color: purple),
              ),
              title: Text(
                '$titlePrefix: $name',
                style: const TextStyle(fontWeight: FontWeight.bold),
                textAlign: isArabic ? TextAlign.right : TextAlign.left,
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Column(
                  crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(
                      text,
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                    if (createdAt != 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${_t("Date", "التاريخ")}: ${_formatDate(createdAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
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
