import 'package:flutter/material.dart';
import 'package:pc_bt_heal/main.dart';
import 'PatientRegisterPage.dart';
import 'PatientForgotPasswordPage.dart';
import 'PatientDashboardPage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PatientLoginPage extends StatefulWidget {
  final String currentLanguage;
  const PatientLoginPage({super.key, this.currentLanguage = 'English'});

  @override
  State<PatientLoginPage> createState() => _PatientLoginPageState();
}

class _PatientLoginPageState extends State<PatientLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final bool isArabic = widget.currentLanguage == 'Arabic';

    final titleText = isArabic ? "تسجيل دخول المريض" : "Patient Login";
    final emailLabel = isArabic ? "البريد الإلكتروني" : "Email";
    final passwordLabel = isArabic ? "كلمة المرور" : "Password";
    final emailEmptyError =
    isArabic ? "الرجاء إدخال البريد الإلكتروني" : "Please enter your email";
    final emailInvalidErr =
    isArabic ? "الرجاء إدخال بريد إلكتروني صالح" : "Enter a valid email";
    final passEmptyError =
    isArabic ? "الرجاء إدخال كلمة المرور" : "Please enter your password";
    final forgotText = isArabic ? "هل نسيت كلمة المرور؟" : "Forgot Password?";
    final loginBtnText = isArabic ? "تسجيل الدخول" : "Login";
    final registerText = isArabic ? "تسجيل كمريض جديد" : "Register as New Patient";
    final accessDeniedText = isArabic
        ? "تم رفض الوصول: هذا الحساب ليس حساب مريض."
        : "Access denied: Not a patient account.";
    final unknownUserIdErr =
    isArabic ? "لم يتم العثور على رقم المستخدم." : "User ID not found.";
    final noUserDataErr =
    isArabic ? "لم يتم العثور على بيانات المستخدم في قاعدة البيانات." : "User data not found in database.";
    final loginFailedText =
    isArabic ? "فشل تسجيل الدخول. الرجاء التأكد من البيانات." : "Login failed. Please check your credentials.";
    final unexpectedErr = isArabic ? "حدث خطأ غير متوقع: " : "Unexpected error: ";

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
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
                )
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Image(
                    image: AssetImage('images/logo.png'),
                    height: 100,
                    width: 100,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                      labelText: emailLabel,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return emailEmptyError;
                      if (!v.contains('@') || !v.contains('.')) return emailInvalidErr;
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
                      labelText: passwordLabel,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return passEmptyError;
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PatientForgotPasswordPage()),
                        );
                      },
                      child: Text(forgotText),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _login(
                        isArabic: isArabic,
                        unknownUserIdErr: unknownUserIdErr,
                        noUserDataErr: noUserDataErr,
                        accessDeniedText: accessDeniedText,
                        loginFailedText: loginFailedText,
                        unexpectedErr: unexpectedErr,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(loginBtnText, style: const TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PatientRegisterPage()),
                      );
                    },
                    child: Text(registerText),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => HealSystem(
                title: isArabic ? 'نظام شفاء' : 'Heal System',
                onThemeChanged: (val) {},
                onLanguageChanged: (val) {},
                currentLanguage: widget.currentLanguage,
                isDarkMode: false,
              ),
            ),
          );
        },
        backgroundColor: Colors.purple,
        child: const Icon(Icons.home),
      ),

    );
  }

  void _login({
    required bool isArabic,
    required String unknownUserIdErr,
    required String noUserDataErr,
    required String accessDeniedText,
    required String loginFailedText,
    required String unexpectedErr,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    final email = emailController.text.trim();
    final password = passwordController.text;

    try {
      UserCredential userCredential =
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);

      final uid = userCredential.user?.uid;
      if (uid == null) throw FirebaseAuthException(code: 'unknown', message: unknownUserIdErr);

      DatabaseReference userRef = FirebaseDatabase.instance.ref('users/$uid');
      DatabaseEvent event = await userRef.once();

      final Map<dynamic, dynamic>? userData = event.snapshot.value as Map<dynamic, dynamic>?;

      if (userData == null) throw Exception(noUserDataErr);

      if (userData['userType'] == 'Patient') {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PatientDashboardPage()));
      } else {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(accessDeniedText)));
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.message ?? loginFailedText, textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("$unexpectedErr$e", textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr),
        ),
      );
    }
  }
}
