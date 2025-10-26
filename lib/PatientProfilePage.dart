import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
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

  Future<void> _loadUserData() async {
    if (user == null) return;
    final snapshot = await _database.child('users/${user!.uid}').get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map<Object?, Object?>);
      setState(() {
        patientData = {
          "Full Name": data['name'] ?? '',
          "Email": data['email'] ?? '',
          "Phone Number": data['phone'] ?? '',
          "National ID": data['civilId'] ?? '',
          "Date of Birth": data['dateOfBirth'] ?? '',
          "Blood Type": data['bloodType'] ?? '',
          "Gender": data['gender'] ?? '',
          "Emergency Contact": data['emergencyContact'] ?? '',
          "Address": data['address'] ?? '',
        };
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
            const Text("Profile Image"),
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
            const Text("Import Image", style: TextStyle(fontSize: 16))
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String fieldKey) async {
    final TextEditingController controller = TextEditingController(text: patientData[fieldKey]?.toString() ?? '');

    if (fieldKey == "Email") {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Email cannot be updated.")),
      );
      return;
    }

    if (fieldKey == "Date of Birth") {
      final picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now().subtract(const Duration(days: 365 * 20)),
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );
      if (picked != null) {
        final formattedDate = DateFormat('MMMM d, yyyy').format(picked);
        _updateField(fieldKey, formattedDate);
      }
      return;
    }

    if (fieldKey == "Blood Type") {
      String? selectedBloodType = patientData[fieldKey];
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16),
          contentPadding: const EdgeInsets.all(16),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Edit Blood Type"),
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
                items: [
                  "O+","O-","A+","A-","B+","B-","AB+","AB-"
                ].map((type) => DropdownMenuItem(value: type, child: Text(type))).toList(),
                onChanged: (value) => selectedBloodType = value!,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: "Blood Type",
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedBloodType != null) {
                      _updateField(fieldKey, selectedBloodType!);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text("Update", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        titlePadding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("Edit $fieldKey"),
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
              keyboardType: fieldKey == "Phone Number" || fieldKey == "Emergency Contact" || fieldKey == "National ID"
                  ? TextInputType.number
                  : TextInputType.text,
              decoration: InputDecoration(
                labelText: fieldKey,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  final value = controller.text.trim();
                  _updateField(fieldKey, value);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text("Update", style: TextStyle(color: Colors.white)),
              ),
            )
          ],
        ),
      ),
    );
  }

  void _updateField(String key, String value) async {
    if (user == null) return;
    final dbKey = _mapFieldToDBKey(key);
    await _database.child('users/${user!.uid}/$dbKey').set(value);
    Navigator.of(context).pop();
    _loadUserData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Profile", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: patientData.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.purple,
                backgroundImage:
                _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  patientData["Full Name"] ?? "",
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.purple),
                  onPressed: () => _showEditDialog("Full Name"),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...[
              "Email",
              "Phone Number",
              "National ID",
              "Date of Birth",
              "Blood Type",
              "Gender",
              "Emergency Contact",
              "Address",
            ].map((key) => Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 3,
              child: ListTile(
                title: Text(key, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(patientData[key]?.toString() ?? ''),
                leading: const Icon(Icons.info_outline_rounded, color: Colors.purple),
                trailing: key != "Email"
                    ? IconButton(
                  icon: const Icon(Icons.edit, color: Colors.purple),
                  onPressed: () => _showEditDialog(key),
                )
                    : null,
              ),
            )),
          ],
        ),
      ),
    );
  }
}

