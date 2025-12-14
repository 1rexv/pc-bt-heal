import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DoctorForgotPasswordPage extends StatefulWidget {
  final bool isArabic;

  const DoctorForgotPasswordPage({
    super.key,
    required this.isArabic,
  });

  @override
  State<DoctorForgotPasswordPage> createState() =>
      _DoctorForgotPasswordPageState();
}

class _DoctorForgotPasswordPageState
    extends State<DoctorForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final emailController = TextEditingController();

  String t(String en, String ar) => widget.isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      widget.isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.purple,
          centerTitle: true,
          title: Text(
            t("Forgot Password", "نسيت كلمة المرور"),
            style: const TextStyle(color: Colors.white),
          ),
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t(
                        "Enter your email to reset password",
                        "أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور",
                      ),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: emailController,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email),
                        border: const OutlineInputBorder(),
                        labelText: t("Email", "البريد الإلكتروني"),
                      ),
                      validator: (v) =>
                      v == null || !v.contains('@')
                          ? t(
                        "Enter a valid email",
                        "أدخل بريد إلكتروني صحيح",
                      )
                          : null,
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                        ),
                        child: Text(
                          t("Submit", "إرسال"),
                          style: const TextStyle(
                              color: Colors.white),
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
          onPressed: () => Navigator.pop(context),
          child:
          const Icon(Icons.arrow_back, color: Colors.white),
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    await FirebaseAuth.instance.sendPasswordResetEmail(
      email: emailController.text.trim(),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          t(
            "Reset link sent to your email",
            "تم إرسال رابط إعادة التعيين إلى بريدك",
          ),
        ),
      ),
    );
  }
}
