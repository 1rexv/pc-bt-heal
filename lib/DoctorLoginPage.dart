import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'DoctorForgotPasswordPage.dart';
import 'DoctorDashboardPage.dart';
import 'AddOrUpdateDoctorPage.dart';
import 'main.dart';

class DoctorLoginPage extends StatefulWidget {
  const DoctorLoginPage({super.key});

  @override
  State<DoctorLoginPage> createState() => _DoctorLoginPageState();
}

class _DoctorLoginPageState extends State<DoctorLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool get isArabic =>
      Localizations.localeOf(context).languageCode.startsWith('ar');

  String t(String en, String ar) => isArabic ? ar : en;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          centerTitle: true,
          title: Text(
            t("Doctor Login", "تسجيل دخول الطبيب"),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Image(
                      image: AssetImage('images/logo.png'),
                      height: 120,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      t("Doctor Login", "تسجيل دخول الطبيب"),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 24),

                    /// Email
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                        labelText: t("Email", "البريد الإلكتروني"),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return t(
                            "Please enter your email",
                            "الرجاء إدخال البريد الإلكتروني",
                          );
                        }
                        if (!v.contains('@')) {
                          return t(
                            "Enter a valid email",
                            "أدخل بريد إلكتروني صحيح",
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    /// Password
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        labelText: t("Password", "كلمة المرور"),
                      ),
                      validator: (v) =>
                      v == null || v.isEmpty
                          ? t(
                        "Please enter your password",
                        "الرجاء إدخال كلمة المرور",
                      )
                          : null,
                    ),

                    /// Forgot Password
                    Align(
                      alignment: isArabic
                          ? Alignment.centerLeft
                          : Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  DoctorForgotPasswordPage(isArabic: isArabic),
                            ),
                          );
                        },
                        child: Text(
                          t("Forgot Password?", "نسيت كلمة المرور؟"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    /// Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding:
                          const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(
                          t("Login", "تسجيل الدخول"),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    /// Register
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                            const AddOrUpdateDoctorPage(),
                          ),
                        );
                      },
                      child: Text(
                        t("Register as New Doctor", "تسجيل طبيب جديد"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// Back
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.purple,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HealSystem(
                  title: 'Heal System',
                  currentLanguage: isArabic ? 'Arabic' : 'English',
                  isDarkMode: false,
                  onThemeChanged: (_) {},
                  onLanguageChanged: (_) {},
                ),
              ),
            );
          },
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }

  void _login() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final cred = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final user = cred.user;
      if (user == null) return;

      final ref =
      FirebaseDatabase.instance.ref("doctors/${user.uid}");
      final snapshot = await ref.get();

      if (!snapshot.exists) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t("Access denied", "غير مصرح بالدخول"),
            ),
          ),
        );
        return;
      }

      final data = snapshot.value as Map;
      if (data['enabled'] != true) {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              t("Account disabled", "الحساب معطل"),
            ),
          ),
        );
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const DoctorDashboardPage(),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t("Login failed", "فشل تسجيل الدخول"),
          ),
        ),
      );
    }
  }
}
