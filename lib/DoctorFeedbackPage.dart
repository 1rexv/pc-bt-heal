import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class DoctorFeedbackPage extends StatefulWidget {
  const DoctorFeedbackPage({super.key});

  @override
  State<DoctorFeedbackPage> createState() => _DoctorFeedbackPageState();
}

class _DoctorFeedbackPageState extends State<DoctorFeedbackPage> {
  final TextEditingController _feedbackController = TextEditingController();
  bool _isSubmitting = false;

  bool get isArabic =>
      Localizations.localeOf(context).languageCode.startsWith('ar');

  Future<void> _submitFeedback() async {
    final feedback = _feedbackController.text.trim();
    final user = FirebaseAuth.instance.currentUser;

    if (feedback.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'الرجاء كتابة ملاحظاتك'
                : 'Please enter your feedback',
          ),
        ),
      );
      return;
    }

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'يجب تسجيل الدخول أولاً'
                : 'You must be logged in',
          ),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final String uid = user.uid;

      String doctorEmail = user.email ?? "";
      String doctorName = user.displayName ?? "Unknown Doctor";

      final DatabaseReference doctorRef =
      FirebaseDatabase.instance.ref("doctors/$uid");
      final DataSnapshot doctorSnapshot = await doctorRef.get();

      if (doctorSnapshot.exists && doctorSnapshot.value is Map) {
        final data =
        Map<String, dynamic>.from(doctorSnapshot.value as Map);

        if ((data['email'] ?? '').toString().isNotEmpty) {
          doctorEmail = data['email'];
        }

        if ((data['fullName'] ?? '').toString().isNotEmpty) {
          doctorName = data['fullName'];
        }
      }

      final ref =
      FirebaseDatabase.instance.ref("systemDoctorFeedback").push();

      await ref.set({
        "doctorUid": uid,
        "doctorEmail": doctorEmail,
        "doctorName": doctorName,
        "feedback": feedback,
        "createdAt": ServerValue.timestamp,
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'تم إرسال الملاحظات بنجاح'
                : 'Feedback submitted successfully',
          ),
        ),
      );

      _feedbackController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? 'حدث خطأ: $e'
                : 'Error: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic
                ? 'ملاحظات الطبيب عن النظام'
                : 'Doctor System Feedback',
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: purple,
          centerTitle: true,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isArabic
                    ? 'نقدّر ملاحظاتك لتحسين النظام'
                    : 'We value your input!',
                style:
                const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feedbackController,
                maxLines: 6,
                decoration: InputDecoration(
                  hintText: isArabic
                      ? 'اكتب ملاحظاتك حول النظام...'
                      : 'Write your feedback about the system...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: purple,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.send),
                  label: Text(
                    _isSubmitting
                        ? (isArabic ? 'جاري الإرسال...' : 'Submitting...')
                        : (isArabic ? 'إرسال الملاحظات' : 'Submit Feedback'),
                  ),
                  onPressed: _isSubmitting ? null : _submitFeedback,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
