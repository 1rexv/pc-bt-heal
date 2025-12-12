import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PatientProfilePage extends StatefulWidget {
  const PatientProfilePage({super.key});

  @override
  State<PatientProfilePage> createState() => _PatientProfilePageState();
}

class _PatientProfilePageState extends State<PatientProfilePage> {
  final user = FirebaseAuth.instance.currentUser;
  final DatabaseReference _database = FirebaseDatabase.instance.ref();
  Map<String, dynamic> patientData = {};
  File? _profileImage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(String en, String ar) => _isArabic ? ar : en;

  TextAlign get _fieldAlign => _isArabic ? TextAlign.right : TextAlign.left;
  CrossAxisAlignment get _colAlign =>
      _isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start;

  Future<void> _loadUserData() async {
    if (user == null) return;
    final snapshot = await _database.child('users/${user!.uid}').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map<Object?, Object?>);

      // Format date if possible according to locale
      String formattedDob = (data['dateOfBirth'] ?? '').toString();
      if ((data['dateOfBirth'] ?? '').toString().isNotEmpty) {
        final raw = data['dateOfBirth'].toString();
        DateTime? parsed;
        try {
          parsed = DateTime.tryParse(raw);
        } catch (_) {
          parsed = null;
        }
        if (parsed != null) {
          try {
            formattedDob = DateFormat.yMMMMd(_isArabic ? 'ar' : 'en').format(parsed);
          } catch (_) {
            // fallback to ISO substring
            formattedDob = parsed.toLocal().toString().split(' ')[0];
          }
        } else {
          // maybe already formatted string — leave as is
          formattedDob = raw;
        }
      }

      setState(() {
        patientData = {
          "Full Name": data['name'] ?? '',
          "Email": data['email'] ?? '',
          "Phone Number": data['phone'] ?? '',
          "National ID": data['civilId'] ?? '',
          "Date of Birth": formattedDob,
          "Blood Type": data['bloodType'] ?? '',
          "Gender": data['gender'] ?? '',
          "Emergency Contact": data['emergencyContact'] ?? '',
          "Address": data['address'] ?? '',
        };
      });
    } else {
      setState(() {
        patientData = {};
      });
    }
  }

  Future<void> _pickImage() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_t("Profile Image", "صورة الملف الشخصي")),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.file_upload, size: 40, color: Colors.purple),
              onPressed: () async {
                final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
                if (pickedFile != null) {
                  setState(() {
                    _profileImage = File(pickedFile.path);
                  });
                }
                Navigator.of(context).pop();
              },
            ),
            const SizedBox(height: 10),
            Text(_t("Import Image", "استيراد صورة"), style: const TextStyle(fontSize: 16))
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String fieldKey) async {
    // controller initialised with current value
    final TextEditingController controller =
    TextEditingController(text: patientData[fieldKey]?.toString() ?? '');

    // Email not editable
    if (fieldKey == "Email") {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("Email cannot be updated.", "لايمكن تعديل البريد الإلكتروني."))),
      );
      return;
    }

    // Date of Birth -> use date picker
    if (fieldKey == "Date of Birth") {
      final initial = DateTime.tryParse(patientData['Date of Birth'] ?? '') ?? DateTime.now().subtract(const Duration(days: 365 * 20));
      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
        locale: Locale(_isArabic ? 'ar' : 'en'),
      );
      if (picked != null) {
        // Save ISO to DB (so it's machine-parseable) and display formatted to user
        await _updateFieldDb('dateOfBirth', picked.toIso8601String());
        await _loadUserData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_t("Date updated", "تم تحديث التاريخ"))),
          );
        }
      }
      return;
    }

    // Blood Type -> special dropdown
    if (fieldKey == "Blood Type") {
      String? selectedBloodType = patientData[fieldKey] as String?;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_t("Edit Blood Type", "تعديل فصيلة الدم")),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                value: (selectedBloodType ?? '').isEmpty ? null : selectedBloodType,
                items: ["O+", "O-", "A+", "A-", "B+", "B-", "AB+", "AB-"]
                    .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                    .toList(),
                onChanged: (value) => selectedBloodType = value,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  labelText: _t("Blood Type", "فصيلة الدم"),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (selectedBloodType != null) {
                      await _updateFieldDb('bloodType', selectedBloodType!);
                      await _loadUserData();
                      Navigator.of(context).pop(); // close dialog
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(_t("Blood type updated", "تم تعديل فصيلة الدم"))),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_t("Update", "تحديث"), style: const TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    // Default text edit dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(_t("Edit", "تعديل") + ' ' + _labelForKey(fieldKey)),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: controller,
              keyboardType: (fieldKey == "Phone Number" ||
                  fieldKey == "Emergency Contact" ||
                  fieldKey == "National ID")
                  ? TextInputType.number
                  : TextInputType.text,
              textAlign: _fieldAlign,
              decoration: InputDecoration(
                labelText: _labelForKey(fieldKey),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final value = controller.text.trim();
                  if (value.isEmpty) {
                    // small validation
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_t("Please enter a value", "الرجاء إدخال قيمة"))),
                    );
                    return;
                  }
                  // Save to DB using mapping
                  final dbKey = _mapFieldToDBKey(fieldKey);
                  await _updateFieldDb(dbKey, value);
                  await _loadUserData();
                  if (mounted) {
                    Navigator.of(context).pop(); // close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(_t("Updated successfully", "تم التحديث بنجاح"))),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(_t("Update", "تحديث"), style: const TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Write single field to DB (dbKey is actual key in 'users' node)
  Future<void> _updateFieldDb(String dbKey, String value) async {
    if (user == null) return;
    await _database.child('users/${user!.uid}/$dbKey').set(value);
  }

  String _mapFieldToDBKey(String field) {
    switch (field) {
      case "Full Name":
        return "name";
      case "Phone Number":
        return "phone";
      case "Date of Birth":
        return "dateOfBirth";
      case "Gender":
        return "gender";
      case "Address":
        return "address";
      case "National ID":
        return "civilId";
      case "Blood Type":
        return "bloodType";
      case "Emergency Contact":
        return "emergencyContact";
      default:
        return field;
    }
  }

  String _labelForKey(String key) {
    // Return translated label for display
    switch (key) {
      case "Full Name":
        return _t("Full Name", "الاسم الكامل");
      case "Email":
        return _t("Email", "البريد الإلكتروني");
      case "Phone Number":
        return _t("Phone Number", "رقم الهاتف");
      case "National ID":
        return _t("National ID", "الهوية الوطنية");
      case "Date of Birth":
        return _t("Date of Birth", "تاريخ الميلاد");
      case "Blood Type":
        return _t("Blood Type", "فصيلة الدم");
      case "Gender":
        return _t("Gender", "الجنس");
      case "Emergency Contact":
        return _t("Emergency Contact", "جهة الاتصال في حالة الطوارئ");
      case "Address":
        return _t("Address", "العنوان");
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple;

    return Scaffold(
      appBar: AppBar(
        title: Text(_t("My Profile", "ملفّي"), style: const TextStyle(color: Colors.white)),
        backgroundColor: purple,
        centerTitle: true,
      ),
      body: patientData.isEmpty
          ? Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(_t("Loading profile...", "جارٍ تحميل الملف..."))
        ],
      ))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar + edit
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.purple,
                  backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                  child: _profileImage == null
                      ? const Icon(Icons.person, size: 50, color: Colors.white)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Name + edit icon centered
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    patientData["Full Name"] ?? "",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.purple),
                    onPressed: () => _showEditDialog("Full Name"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Fields list
            ...[
              "Email",
              "Phone Number",
              "National ID",
              "Date of Birth",
              "Blood Type",
              "Gender",
              "Emergency Contact",
              "Address",
            ].map((key) {
              final value = patientData[key]?.toString() ?? '';
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 3,
                child: ListTile(
                  leading: const Icon(Icons.info_outline_rounded, color: Colors.purple),
                  title: Text(
                    _labelForKey(key),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  subtitle: Text(
                    value,
                    textAlign: _isArabic ? TextAlign.right : TextAlign.left,
                  ),
                  trailing: key != "Email"
                      ? IconButton(
                    icon: const Icon(Icons.edit, color: Colors.purple),
                    onPressed: () => _showEditDialog(key),
                  )
                      : null,
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }
}
