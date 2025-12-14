import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PatientForgotPasswordPage extends StatefulWidget {
  const PatientForgotPasswordPage({super.key});

  @override
  State<PatientForgotPasswordPage> createState() =>
      _PatientForgotPasswordPageState();
}

class _PatientForgotPasswordPageState
    extends State<PatientForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController emailController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool get isArabic =>
      Localizations.localeOf(context).languageCode.startsWith('ar');

  String _t(String ar, String en) => isArabic ? ar : en;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _t('نسيت كلمة المرور', 'Forgot Password'),
            style: const TextStyle(color: Colors.white),
          ),
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
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _t(
                        'أدخل بريدك الإلكتروني لإعادة تعيين كلمة المرور',
                        'Enter your email to reset password',
                      ),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.purple,
                        fontWeight: FontWeight.w600,
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
                        labelText: _t('البريد الإلكتروني', 'Email'),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return _t(
                              'الرجاء إدخال البريد الإلكتروني',
                              'Please enter your email');
                        }
                        if (!v.contains('@') || !v.contains('.')) {
                          return _t(
                              'الرجاء إدخال بريد إلكتروني صحيح',
                              'Enter a valid email');
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          _t('إرسال', 'Submit'),
                          style: const TextStyle(
                              fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        /// Back Button
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

    try {
      await _auth.sendPasswordResetEmail(
        email: emailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t(
              'تم إرسال رابط إعادة تعيين كلمة المرور، يرجى التحقق من بريدك الإلكتروني',
              'Password reset link sent. Please check your email.',
            ),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String errorMessage = _t(
        'حدث خطأ غير متوقع',
        'Something went wrong',
      );

      if (e.code == 'user-not-found') {
        errorMessage = _t(
          'لا يوجد حساب مرتبط بهذا البريد الإلكتروني',
          'No user found with this email',
        );
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
    }
  }
}
