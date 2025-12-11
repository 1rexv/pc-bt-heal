import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';

class AddOrUpdateDoctorPage extends StatefulWidget {
  const AddOrUpdateDoctorPage({super.key});

  @override
  State<AddOrUpdateDoctorPage> createState() => _AddOrUpdateDoctorPageState();
}

class _AddOrUpdateDoctorPageState extends State<AddOrUpdateDoctorPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController staffIdController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();

  bool _isLoading = false;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  File? _profileImageFile;
  String? _profileImageUrl;

  File? _certificateFile;
  String? _certificateUrl;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(String en, String ar) => _isArabic ? ar : en;

  @override
  void dispose() {
    fullNameController.dispose();
    addressController.dispose();
    staffIdController.dispose();
    descriptionController.dispose();
    emailController.dispose();
    passwordController.dispose();
    phoneController.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_t("Doctor Registration", "تسجيل طبيب"),
              style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.purple,
          centerTitle: true,
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                const SizedBox(height: 16),
                _buildTextField(
                  fullNameController,
                  _t("Full Name", "الاسم الكامل"),
                  Icons.person,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  emailController,
                  _t("Email", "البريد الإلكتروني"),
                  Icons.email,
                  inputType: TextInputType.emailAddress,
                  validator: _emailValidator,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  passwordController,
                  _t("Password", "كلمة المرور"),
                  Icons.lock,
                  obscure: true,
                  validator: _passwordValidator,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  phoneController,
                  _t("Phone Number", "رقم الهاتف"),
                  Icons.phone,
                  inputType: TextInputType.phone,
                  validator: _phoneValidator,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image, color: Colors.white),
                  label: Text(_t("Upload Profile Image", "رفع صورة الملف الشخصي"),
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: _pickProfileImage,
                ),
                if (_profileImageFile != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.file(_profileImageFile!, height: 100),
                  ),
                const SizedBox(height: 16),
                _buildTextField(
                  addressController,
                  _t("Address", "العنوان"),
                  Icons.location_on,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  staffIdController,
                  _t("Staff ID", "الهوية الوظيفية"),
                  Icons.badge,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  descriptionController,
                  _t("Doctor Description", "وصف الطبيب"),
                  Icons.description,
                  maxLines: 4,
                ),
                const SizedBox(height: 24),
                Text(
                  _t("Doctor Location", "موقع الطبيب"),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(23.5859, 58.4059),
                      zoom: 7,
                    ),
                    onMapCreated: (controller) => _mapController = controller,
                    onTap: (LatLng position) {
                      setState(() => _selectedLocation = position);
                    },
                    markers: _selectedLocation != null
                        ? {
                      Marker(
                        markerId: const MarkerId("selected-location"),
                        position: _selectedLocation!,
                      ),
                    }
                        : {},
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.upload_file, color: Colors.white),
                  label: Text(_t("Upload Certificate", "رفع الشهادة"),
                      style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                  onPressed: _pickCertificate,
                ),
                if (_certificateFile != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "${_t("Selected:", "المحدد:")} ${_certificateFile!.path.split('/').last}",
                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                    ),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _submitForm,
                  child: Text(
                    _t("Submit", "إرسال"),
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _phoneValidator(String? value) {
    final isArabic = _isArabic;
    if (value == null || value.isEmpty) {
      return _t("Enter phone number", "أدخل رقم الهاتف");
    }

    final RegExp phoneRegex = RegExp(r'^[89][0-9]{7}$');
    if (!phoneRegex.hasMatch(value)) {
      return _t("Phone must be 8 digits and start with 9 or 8",
          "يجب أن يكون الهاتف ٨ أرقام ويبدأ بـ ٩ أو ٨");
    }
    return null;
  }

  Widget _buildTextField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool obscure = false,
        int maxLines = 1,
        TextInputType inputType = TextInputType.text,
        String? Function(String?)? validator,
      }) {
    final isArabic = _isArabic;
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: inputType,
      textAlign: isArabic ? TextAlign.right : TextAlign.left,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: validator ?? (value) => (value == null || value.isEmpty) ? _t("Enter $label", "أدخل $label") : null,
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return _t("Enter email", "أدخل البريد الإلكتروني");
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return _t("Enter valid email", "أدخل بريدًا إلكترونيًا صحيحًا");
    return null;
  }

  String? _passwordValidator(String? value) {
    return (value == null || value.length < 6) ? _t("Password must be at least 6 characters", "يجب أن تكون كلمة المرور ٦ أحرف على الأقل") : null;
  }

  String? _phoneValidatorWrapper(String? v) => _phoneValidator(v); // kept for compatibility

  Future<void> _pickProfileImage() async {
    try {
      final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() => _profileImageFile = File(picked.path));
      }
    } catch (e) {
      debugPrint("Profile pick error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t("Error picking image", "حدث خطأ أثناء اختيار الصورة"))));
      }
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _certificateFile = File(result.files.single.path!);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${_t("Selected:", "تم الاختيار:")} ${result.files.single.name}")));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t("No file selected", "لم يتم اختيار ملف"))));
        }
      }
    } catch (e) {
      debugPrint("File pick error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${_t("Error picking file:", "خطأ في اختيار الملف:")} $e")));
      }
    }
  }

  Future<String?> _uploadFile(File file, String path) async {
    try {
      final ref = FirebaseStorage.instance.ref().child(path);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      debugPrint("Upload error: $e");
      return null;
    }
  }

  Future<void> _submitForm() async {
    final isArabic = _isArabic;
    // custom validator mapping: make sure phone uses phone validator
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // create auth user
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      final uid = userCredential.user!.uid;

      if (_profileImageFile != null) {
        _profileImageUrl = await _uploadFile(_profileImageFile!, "doctors/$uid/profile.jpg");
      }

      if (_certificateFile != null) {
        final ext = _certificateFile!.path.split('.').last;
        _certificateUrl = await _uploadFile(_certificateFile!, "doctors/$uid/certificate.$ext");
      }

      await _db.child("doctors").child(uid).set({
        "fullName": fullNameController.text.trim(),
        "email": emailController.text.trim(),
        "phone": phoneController.text.trim(),
        "address": addressController.text.trim(),
        "staffId": staffIdController.text.trim(),
        "certificates": _certificateUrl ?? "",
        "description": descriptionController.text.trim(),
        "location": _selectedLocation != null
            ? {
          "lat": _selectedLocation!.latitude,
          "lng": _selectedLocation!.longitude,
        }
            : null,
        "profileImage": _profileImageUrl ?? "",
        "userType": "Doctor",
        "enabled": true,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(_t("Doctor registered successfully!", "تم تسجيل الطبيب بنجاح!"))));
      }

      _formKey.currentState!.reset();
      setState(() {
        _selectedLocation = null;
        _profileImageFile = null;
        _certificateFile = null;
      });
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${_t("Error:", "خطأ:")} ${e.message}")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${_t("Unexpected error:", "خطأ غير متوقع:")} $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
