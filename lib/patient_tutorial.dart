import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'PatientDashboardPage.dart';

class PatientTutorialPage extends StatefulWidget {
  const PatientTutorialPage({super.key});

  @override
  State<PatientTutorialPage> createState() => _PatientTutorialPageState();
}

class _TutorialItem {
  final IconData icon;
  final String titleEn;
  final String descEn;
  final String titleAr;
  final String descAr;

  _TutorialItem({
    required this.icon,
    required this.titleEn,
    required this.descEn,
    required this.titleAr,
    required this.descAr,
  });
}

class _PatientTutorialPageState extends State<PatientTutorialPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  late final List<_TutorialItem> _tutorialPages;

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  @override
  void initState() {
    super.initState();

    // Define tutorial content (both languages)
    _tutorialPages = [
      _TutorialItem(
        icon: Icons.pregnant_woman,
        titleEn: "Welcome, Mama 💕",
        descEn: "This app supports you throughout your pregnancy and health journey.",
        titleAr: "أهلاً بكِ يا أمِّي 💕",
        descAr: "التطبيق يدعمك طوال رحلة الحمل والعناية الصحيّة.",
      ),
      _TutorialItem(
        icon: Icons.person,
        titleEn: "Your Profile",
        descEn: "Add your details so the app can personalize your care and reminders.",
        titleAr: "الملف الشخصي",
        descAr: "أدخلي بياناتك حتى يقوم التطبيق بتخصيص الرعاية والتذكيرات.",
      ),
      _TutorialItem(
        icon: Icons.smart_toy,
        titleEn: "AI Chat Support",
        descEn: "Ask questions anytime. Our AI assistant helps with safe guidance.",
        titleAr: "المساعد الذكي",
        descAr: "استخدمي المساعد لطرح الأسئلة؛ يقدم إرشادات عامة وآمنة.",
      ),
      _TutorialItem(
        icon: Icons.medical_services,
        titleEn: "Medication Info",
        descEn: "Check ingredients, risks, and safe medication information.",
        titleAr: "معلومات الأدوية",
        descAr: "تحققي من المكونات والمخاطر ومعلومات الأدوية الآمنة.",
      ),
      _TutorialItem(
        icon: Icons.calendar_month,
        titleEn: "Appointments",
        descEn: "Track your pregnancy checkups and doctor visits in one place.",
        titleAr: "المواعيد",
        descAr: "تابعي مواعيد المتابعة وزيارات الطبيب في مكان واحد.",
      ),
      _TutorialItem(
        icon: Icons.feedback,
        titleEn: "Feedback",
        descEn: "Share your experience so we can improve and support other women.",
        titleAr: "الملاحظات",
        descAr: "شاركي تجربتك لنعمل على تحسين التطبيق ودعم أخريات.",
      ),
      _TutorialItem(
        icon: Icons.warning_amber,
        titleEn: "Report Problems",
        descEn: "Report any issues so we can help you better.",
        titleAr: "الإبلاغ عن المشاكل",
        descAr: "أبلِغِي عن أي مشكلة لنتمكن من مساعدتك بشكل أسرع.",
      ),
      _TutorialItem(
        icon: Icons.local_hospital,
        titleEn: "Clinics & Hospitals",
        descEn: "Find nearby health centers whenever you need care.",
        titleAr: "العيادات والمستشفيات",
        descAr: "ابحثي عن المراكز الصحية القريبة عند الحاجة للرعاية.",
      ),
    ];
  }

  Future<void> _completeTutorial() async {
    final prefs = await SharedPreferences.getInstance();
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      final key = "tutorial_completed_${user.uid}";
      await prefs.setBool(key, true);
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PatientDashboardPage()),
    );
  }

  Widget _buildPage(_TutorialItem item, bool isLast) {
    final title = _isArabic ? item.titleAr : item.titleEn;
    final desc = _isArabic ? item.descAr : item.descEn;

    // Buttons' text
    final startText = _isArabic ? "ابدئي رحلتي" : "Start My Journey";
    final skipText = _isArabic ? "تخطي" : "Skip";
    final nextText = _isArabic ? "التالي" : "Next";

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Circle Icon
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFEAD7FF),
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.withOpacity(0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(
              item.icon,
              size: 70,
              color: const Color(0xFFB616DF),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA346F3),
            ),
            textAlign: TextAlign.center,
            textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            desc,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF555555),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
            textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
          ),
          const SizedBox(height: 32),

          // Navigation Buttons
          if (isLast)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _completeTutorial,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF9E24EA),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  startText,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _completeTutorial,
                  child: Text(
                    skipText,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFB01AE4),
                      fontWeight: FontWeight.w600,
                    ),
                    textDirection: TextDirection.ltr,
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAD26E3),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(
                    nextText,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _tutorialPages.length;
    final stepText = _isArabic ? "الخطوة" : "Step";
    final ofText = _isArabic ? "من" : "of";

    return Directionality(
      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFFF0F7), Color(0xFFEAD7FF)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Top step indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Align(
                    alignment: _isArabic ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(
                      // e.g. "Step 1 of 8" or arabic "الخطوة 1 من 8"
                      _isArabic
                          ? "$stepText ${_currentIndex + 1} $ofText $total"
                          : "$stepText ${_currentIndex + 1} $ofText $total",
                      style: const TextStyle(
                        color: Color(0xFF8A2BE2),
                        fontWeight: FontWeight.w600,
                      ),
                      textDirection: _isArabic ? TextDirection.rtl : TextDirection.ltr,
                    ),
                  ),
                ),

                // Pages
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: total,
                    onPageChanged: (index) {
                      setState(() => _currentIndex = index);
                    },
                    itemBuilder: (context, index) {
                      final item = _tutorialPages[index];
                      final isLast = index == total - 1;
                      return _buildPage(item, isLast);
                    },
                  ),
                ),

                // Dots
                Padding(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      total,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIndex == index ? 22 : 8,
                        decoration: BoxDecoration(
                          color: _currentIndex == index ? const Color(0xFF8A2BE2) : const Color(0xFFD2B6FF),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
