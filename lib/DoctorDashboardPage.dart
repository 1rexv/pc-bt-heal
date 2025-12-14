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
    bool isArabic =
    Localizations.localeOf(context).languageCode.startsWith('ar');

    String t(String en, String ar) => isArabic ? ar : en;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            t("Doctor Dashboard", "لوحة تحكم الطبيب"),
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
              title: t(
                "Accept Appointments for Patients",
                "قبول مواعيد المرضى",
              ),
              page: const AcceptAppointmentsPage(),
              isArabic: isArabic,
            ),

            
            _buildCard(
              context,
              icon: Icons.comment,
              title: t(
                "Respond to Patient Problems",
                "الرد على مشاكل المرضى",
              ),
              page: const RespondToProblemsPage(),
              isArabic: isArabic,
            ),

           
            _buildCard(
              context,
              icon: Icons.medical_services,
              title: t(
                "Add / Update Medicine Details",
                "إضافة / تعديل بيانات الأدوية",
              ),
              page: const AddUpdateMedicinePage(),
              isArabic: isArabic,
            ),

            
            _buildCard(
              context,
              icon: Icons.feedback,
              title: t(
                "Send Feedback to Admin",
                "إرسال ملاحظات للإدارة",
              ),
              page: const DoctorFeedbackPage(),
              isArabic: isArabic,
            ),

            
            _buildCard(
              context,
              icon: Icons.report,
              title: t(
                "Report",
                "التقارير",
              ),
              page: DoctorReportPage(),
              isArabic: isArabic,
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
          isArabic
              ? Icons.arrow_back_ios
              : Icons.arrow_forward_ios,
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
