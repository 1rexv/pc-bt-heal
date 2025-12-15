import 'package:flutter/material.dart';
import 'AcceptAppointmentsPage.dart';
import 'DoctorReportPage.dart';
import 'DoctorFeedbackPage.dart';
import 'AddUpdateMedicinePage.dart';
import 'RespondToProblemsPage.dart';
import 'SocialPostPage.dart';

class DoctorDashboardPage extends StatelessWidget {
  const DoctorDashboardPage({super.key});

  bool _isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(BuildContext context, String en, String ar) =>
      _isArabic(context) ? ar : en;

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic(context);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _t(context, "Doctor Dashboard", "لوحة تحكم الطبيب"),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          centerTitle: true,
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildCard(
              context,
              icon: Icons.calendar_today,
              title: _t(
                context,
                "Accept Appointments for Patients",
                "قبول مواعيد المرضى",
              ),
              page: const AcceptAppointmentsPage(),
              isArabic: isArabic,
            ),

            _buildCard(
              context,
              icon: Icons.comment,
              title: _t(
                context,
                "Respond to Patient Problems",
                "الرد على مشاكل المرضى",
              ),
              page: const RespondToProblemsPage(),
              isArabic: isArabic,
            ),

            _buildCard(
              context,
              icon: Icons.medical_services,
              title: _t(
                context,
                "Add / Update Medicine Details",
                "إضافة / تعديل بيانات الأدوية",
              ),
              page: const AddUpdateMedicinePage(),
              isArabic: isArabic,
            ),

            _buildCard(
              context,
              icon: Icons.feedback,
              title: _t(
                context,
                "Send Feedback to Admin",
                "إرسال ملاحظات للإدارة",
              ),
              page: const DoctorFeedbackPage(),
              isArabic: isArabic,
            ),

            _buildCard(
              context,
              icon: Icons.report,
              title: _t(
                context,
                "Report",
                "التقارير",
              ),
              page: DoctorReportPage(),
              isArabic: isArabic,
            ),

            // ⭐ Social Media Auto Post
            Card(
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
              child: ListTile(
                leading: const Icon(Icons.public, color: Colors.purple),
                title: Text(
                  _t(
                    context,
                    "Social Media Auto Post",
                    "نشر تلقائي على وسائل التواصل",
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  _t(
                    context,
                    "Send this post to LinkedIn & Instagram automatically",
                    "إرسال المنشور تلقائياً إلى لينكدإن وإنستغرام",
                  ),
                  style: const TextStyle(fontSize: 13),
                ),
                trailing: Icon(
                  isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
                  size: 16,
                ),
                onTap: () {
                  // EN + AR versions of the post
                  const postEn =
                      'I am using the Heal pregnancy app to support and advise women '
                      'for a healthy, safe pregnancy journey 💜.';
                  const postAr =
                      'أستخدم تطبيق Heal للحمل لدعم وإرشاد النساء '
                      'من أجل رحلة حمل صحية وآمنة 💜.';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SocialPostPage(
                        imageAssetPath: 'images/w2.png',
                        baseText: isArabic ? postAr : postEn,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Widget page,
    required bool isArabic,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: Icon(
          isArabic ? Icons.arrow_back_ios : Icons.arrow_forward_ios,
          size: 16,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => page),
          );
        },
      ),
    );
  }
}
