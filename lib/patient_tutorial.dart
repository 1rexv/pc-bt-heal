import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'PatientDashboardPage.dart';

class PatientTutorialPage extends StatefulWidget {
  const PatientTutorialPage({super.key});

  @override
  State<PatientTutorialPage> createState() => _PatientTutorialPageState();
}

class _PatientTutorialPageState extends State<PatientTutorialPage> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  final List<_TutorialItem> _tutorialPages = [
    _TutorialItem(
      icon: Icons.pregnant_woman,
      title: "Welcome, Mama 💕",
      desc: "This app supports you throughout your pregnancy and health journey.",
    ),
    _TutorialItem(
      icon: Icons.person,
      title: "Your Profile",
      desc: "Add your details so the app can personalize your care and reminders.",
    ),
    _TutorialItem(
      icon: Icons.smart_toy,
      title: "AI Chat Support",
      desc: "Ask questions anytime. Our AI assistant helps with safe guidance.",
    ),
    _TutorialItem(
      icon: Icons.medical_services,
      title: "Medication Info",
      desc: "Check ingredients, risks, and safe medication information.",
    ),
    _TutorialItem(
      icon: Icons.calendar_month,
      title: "Appointments",
      desc: "Track your pregnancy checkups and doctor visits in one place.",
    ),
    _TutorialItem(
      icon: Icons.feedback,
      title: "Feedback",
      desc: "Share your experience so we can improve and support other women.",
    ),
    _TutorialItem(
      icon: Icons.warning_amber,
      title: "Report Problems",
      desc: "Report any issues so we can help you better.",
    ),
    _TutorialItem(
      icon: Icons.local_hospital,
      title: "Clinics & Hospitals",
      desc: "Find nearby health centers whenever you need care.",
    ),
  ];

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
            item.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA346F3),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            item.desc,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF555555),
              height: 1.4,
            ),
            textAlign: TextAlign.center,
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
                child: const Text(
                  "Start My Journey",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: _completeTutorial,
                  child: const Text(
                    "Skip",
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFFB01AE4),
                      fontWeight: FontWeight.w600,
                    ),
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
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  child: const Text(
                    "Next",
                    style: TextStyle(color: Colors.white),
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

    return Scaffold(
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
                padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Step ${_currentIndex + 1} of $total",
                    style: const TextStyle(
                      color: Color(0xFF8A2BE2),
                      fontWeight: FontWeight.w600,
                    ),
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
                        color: _currentIndex == index
                            ? const Color(0xFF8A2BE2)
                            : const Color(0xFFD2B6FF),
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
    );
  }
}

class _TutorialItem {
  final IconData icon;
  final String title;
  final String desc;

  _TutorialItem({
    required this.icon,
    required this.title,
    required this.desc,
  });
}
