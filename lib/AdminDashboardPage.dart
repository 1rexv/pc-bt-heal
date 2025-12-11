import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AdminLoginPage.dart';
import 'AddOrUpdateDoctorPage.dart';
import 'EnableDisableDoctorPage.dart';
import 'ViewFeedbackPage.dart';
import 'TrackProgressPage.dart';
import 'AdminViweDoctorDetails.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  bool _isArabicBuild(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(BuildContext context, String en, String ar) => _isArabicBuild(context) ? ar : en;

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabicBuild(context);

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t(context, 'Admin Dashboard', 'لوحة المشرف'),
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.purple,
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout, color: Colors.white),
              tooltip: _t(context, 'Sign out', 'تسجيل الخروج'),
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminLoginPage()),
                      (route) => false,
                );
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildOption(
                context,
                icon: Icons.person_add,
                title: _t(context, 'Add / Update Doctor Details', 'إضافة / تعديل بيانات الطبيب'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AddOrUpdateDoctorPage()),
                  );
                },
              ),
              _buildOption(
                context,
                icon: Icons.lock_open,
                title: _t(context, 'Enable / Disable Doctor Accounts', 'تفعيل / تعطيل حسابات الأطباء'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const EnableDisableDoctorPage()),
                  );
                },
              ),
              _buildOption(
                context,
                icon: Icons.feedback,
                title: _t(context, 'View Feedback', 'عرض الملاحظات'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ViewFeedbackPage()),
                  );
                },
              ),
              _buildOption(
                context,
                icon: Icons.list,
                title: _t(context, 'View Doctors', 'قائمة الأطباء'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminDoctorListPage()),
                  );
                },
              ),
              _buildOption(
                context,
                icon: Icons.bar_chart,
                title: _t(context, 'Track System Progress Report', 'تتبع تقرير تقدم النظام'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TrackProgressPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context,
      {required IconData icon, required String title, required VoidCallback onTap}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.purple),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
