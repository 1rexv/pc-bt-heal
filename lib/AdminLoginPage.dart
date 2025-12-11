import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'AdminDashboardPage.dart';
import 'main.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});

  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final isArabic = _isArabic;
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null && user.photoURL == "admin") {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? "تم تسجيل الدخول بنجاح!" : "Login successful!")),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AdminDashboardPage()),
        );
      } else {
        await FirebaseAuth.instance.signOut();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(isArabic ? "تم الرفض. ليس حساب مشرف." : "Access denied. Not an admin.")),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? (isArabic ? 'فشل تسجيل الدخول' : 'Login failed'))),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          title: Text(_t("Admin Login", "تسجيل دخول المشرف"), style: const TextStyle(color: Colors.white)),
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
                      _t("Admin Login", "تسجيل دخول المشرف"),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Email
                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                        labelText: _t('Email', 'البريد الإلكتروني'),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return _t('Enter your email', 'أدخل البريد الإلكتروني');
                        }
                        if (!value.contains('@') || !value.contains('.')) {
                          return _t('Enter valid email', 'أدخل بريدًا إلكترونيًا صحيحًا');
                        }
                        return null;
                      },
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: 16),

                    // Password
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        border: const OutlineInputBorder(),
                        labelText: _t('Password', 'كلمة المرور'),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return _t('Enter your password', 'أدخل كلمة المرور');
                        }
                        if (value.length < 6) {
                          return _t('Password must be >= 6 chars', 'يجب أن تكون كلمة المرور ٦ أحرف أو أكثر');
                        }
                        return null;
                      },
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                    const SizedBox(height: 24),

                    isLoading
                        ? const CircularProgressIndicator()
                        : SizedBox(
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
                          _t('Login', 'تسجيل الدخول'),
                          style: const TextStyle(color: Colors.white, fontSize: 16),
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
          onPressed: () {
            // navigate back to HealSystem (use current locale to determine language value)
            final currentLanguage = isArabic ? 'Arabic' : 'English';
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => HealSystem(
                  title: _t('Heal System', 'نظام شفاء'),
                  onThemeChanged: (val) {},
                  onLanguageChanged: (val) {},
                  currentLanguage: currentLanguage,
                  isDarkMode: false,
                ),
              ),
            );
          },
          backgroundColor: Colors.purple,
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }
}
