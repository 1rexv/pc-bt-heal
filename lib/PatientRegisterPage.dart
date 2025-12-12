import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class PatientRegisterPage extends StatefulWidget {
  const PatientRegisterPage({super.key});

  @override
  State<PatientRegisterPage> createState() => _PatientRegisterPageState();
}

class _PatientRegisterPageState extends State<PatientRegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController civilIdController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isLoading = false;

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(String en, String ar) => _isArabic ? ar : en;

  TextAlign get _alignment => _isArabic ? TextAlign.right : TextAlign.left;
  CrossAxisAlignment get _colAlignment =>
      _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    civilIdController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple;
    final isArabic = _isArabic;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t("Patient Register", "تسجيل المريضة"),
            style: const TextStyle(color: Colors.white)),
        backgroundColor: purple,
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: _colAlignment,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ===== centered title =====
                  Center(
                    child: Text(
                      _t("Register New Patient", "تسجيل مريضة جديدة"),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.purple),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name
                  TextFormField(
                    controller: nameController,
                    textAlign: _alignment,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.person),
                      border: const OutlineInputBorder(),
                      labelText: _t('Full Name', 'الاسم الكامل'),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return _t('Please enter your name', 'الرجاء إدخال الاسم');
                      final words = v.trim().split(RegExp(r'\s+'));
                      if (words.length < 4) return _t('Full name must be at least 4 words', 'يجب أن يتكون الاسم الكامل من 4 كلمات على الأقل');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Email
                  TextFormField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    textAlign: _alignment,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.email),
                      border: const OutlineInputBorder(),
                      labelText: _t('Email', 'البريد الإلكتروني'),
                    ),
                    validator: (v) => (v == null || v.isEmpty)
                        ? _t('Please enter your email', 'الرجاء إدخال البريد الإلكتروني')
                        : (!v.contains('@') || !v.contains('.'))
                        ? _t('Enter a valid email', 'أدخل بريدًا إلكترونيًا صالحًا')
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    textAlign: _alignment,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.phone),
                      border: const OutlineInputBorder(),
                      labelText: _t('Phone Number', 'رقم الهاتف'),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return _t('Please enter your phone number', 'الرجاء إدخال رقم الهاتف');
                      if (!RegExp(r'^[97][0-9]{7}$').hasMatch(v)) {
                        return _t('Phone must be 8 digits and start with 9 or 7', 'يجب أن يكون الهاتف ٨ أرقام ويبدأ بـ 9 أو 7');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Civil ID
                  TextFormField(
                    controller: civilIdController,
                    keyboardType: TextInputType.number,
                    textAlign: _alignment,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.badge),
                      border: const OutlineInputBorder(),
                      labelText: _t('Civil ID Number', 'رقم الهوية المدنية'),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return _t('Please enter your Civil ID', 'الرجاء إدخال رقم الهوية');
                      if (!RegExp(r'^\d+$').hasMatch(v)) return _t('Civil ID must contain numbers only', 'يجب أن يحتوي رقم الهوية على أرقام فقط');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password
                  TextFormField(
                    controller: passwordController,
                    obscureText: true,
                    textAlign: _alignment,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      labelText: _t('Password', 'كلمة المرور'),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return _t('Please enter your password', 'الرجاء إدخال كلمة المرور');
                      if (v.length < 8) return _t('Password must be at least 8 characters', 'يجب أن تكون كلمة المرور ٨ حروف على الأقل');
                      if (!RegExp(r'[A-Z]').hasMatch(v)) return _t('Password must contain at least one uppercase letter', 'يجب أن تحتوي كلمة المرور على حرف كبير واحد على الأقل');
                      if (!v.contains('@')) return _t('Password must contain "@" symbol', 'يجب أن تحتوي كلمة المرور على الرمز "@"');
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password
                  TextFormField(
                    controller: confirmPasswordController,
                    obscureText: true,
                    textAlign: _alignment,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      labelText: _t('Confirm Password', 'تأكيد كلمة المرور'),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return _t('Please confirm your password', 'الرجاء تأكيد كلمة المرور');
                      if (v != passwordController.text) return _t('Passwords do not match', 'كلمتا المرور غير متطابقتين');
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Register button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _register,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isLoading
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(_t('Register', 'تسجيل'), style: const TextStyle(fontSize: 16, color: Colors.white)),
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
        child: const Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }

  void _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final civilId = civilIdController.text.trim();
    final password = passwordController.text.trim();

    try {
      // Create user in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      if (user != null) {
        // Update displayName in FirebaseAuth
        await user.updateDisplayName(name);
        await user.reload(); // Refresh user info
      }

      // Save additional patient data in Realtime Database
      DatabaseReference userRef = FirebaseDatabase.instance.ref('users/${user!.uid}');
      await userRef.set({
        'name': name,
        'email': email,
        'phone': phone,
        'civilId': civilId,
        'userType': 'Patient',
        'createdAt': DateTime.now().toIso8601String(),
        'dateOfBirth': '',
        'gender': 'Women',
        'address': '',
        'bloodType': '',
        'emergencyContact': '',
        'pimage': '',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('Registration successful!', 'تم التسجيل بنجاح!'))),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? _t('Authentication failed.', 'فشل التوثيق.'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_t('Unexpected error', 'خطأ غير متوقع')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
