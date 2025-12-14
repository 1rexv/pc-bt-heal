import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'DoctorForgotPasswordPage.dart';
import 'DoctorDashboardPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AddOrUpdateDoctorPage.dart';
import 'main.dart';

class DoctorLoginPage extends StatefulWidget {
  const DoctorLoginPage({super.key});

  @override
  State<DoctorLoginPage> createState() => _DoctorLoginPageState();
}

class _DoctorLoginPageState extends State<DoctorLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
          title: Text(
            t("Doctor Login", "تسجيل دخول الطبيب"),
            style: const TextStyle(color: Colors.white),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 24),
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
                      width: 120,
                    ),
                    const SizedBox(height: 24),

                    Text(
                      t("Doctor Login", "تسجيل دخول الطبيب"),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                        labelText: t("Email", "البريد الإلكتروني"),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t(
                            "Please enter your email",
                            "الرجاء إدخال البريد الإلكتروني",
                          );
                        } else if (!value.contains('@') ||
                            !value.contains('.')) {
                          return t(
                            "Please enter a valid email",
                            "الرجاء إدخال بريد إلكتروني صحيح",
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        labelText: t("Password", "كلمة المرور"),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return t(
                            "Please enter your password",
                            "الرجاء إدخال كلمة المرور",
                          );
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),

                    
                    Align(
                      alignment:
                      isArabic ? Alignment.centerLeft : Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                              const DoctorForgotPasswordPage(),
                            ),
                          );
                        },
                        child: Text(
                          t("Forgot Password?", "نسيت كلمة المرور؟"),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          t("Login", "تسجيل الدخول"),
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddOrUpdateDoctorPage(),
                          ),
                        );
                      },
                      child: Text(
                        t(
                          "Register as New Doctor",
                          "تسجيل طبيب جديد",
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        
        floatingActionButton: FloatingActionButton(
          backgroundColor: Colors.purple,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HealSystem(
                  title: 'Heal System',
                  onThemeChanged: (_) {},
                  onLanguageChanged: (_) {},
                  currentLanguage: isArabic ? 'Arabic' : 'English',
                  isDarkMode: false,
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

    String email = emailController.text.trim();
    String password = passwordController.text.trim();

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        final ref =
        FirebaseDatabase.instance.ref("doctors").child(user.uid);
        final snapshot = await ref.get();

        if (snapshot.exists) {
          final data = snapshot.value as Map<dynamic, dynamic>;
          bool enabled = data['enabled'] == true;

          if (!enabled) {
            await FirebaseAuth.instance.signOut();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  t(
                    "Sorry, your account is disabled.",
                    "عذرًا، تم تعطيل حسابك.",
                  ),
                ),
              ),
            );
            return;
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t("Login successful!", "تم تسجيل الدخول بنجاح"),
              ),
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => const DoctorDashboardPage(),
            ),
          );
        } else {
          await FirebaseAuth.instance.signOut();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                t(
                  "Access denied. Not a doctor.",
                  "غير مصرح لك بالدخول كطبيب.",
                ),
              ),
            ),
          );
        }
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ??
                t("Login failed", "فشل تسجيل الدخول"),
          ),
        ),
      );
    }
  }
}
