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
  final TextEditingController phoneController = TextEditingController(); //

  bool _isLoading = false;
  LatLng? _selectedLocation;
  GoogleMapController? _mapController;

  File? _profileImageFile;
  String? _profileImageUrl;

  File? _certificateFile;
  String? _certificateUrl;

  final _auth = FirebaseAuth.instance;
  final _db = FirebaseDatabase.instance.ref();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Doctor Registration", style: TextStyle(color: Colors.white)),
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
              _buildTextField(fullNameController, "Full Name", Icons.person),
              const SizedBox(height: 16),
              _buildTextField(emailController, "Email", Icons.email,
                  inputType: TextInputType.emailAddress, validator: _emailValidator),
              const SizedBox(height: 16),
              _buildTextField(passwordController, "Password", Icons.lock,
                  obscure: true, validator: _passwordValidator),
              const SizedBox(height: 16),


              _buildTextField(
                phoneController,
                "Phone Number",
                Icons.phone,
                inputType: TextInputType.phone,
                validator: _phoneValidator,
              ),

              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.image, color: Colors.white),
                label: const Text("Upload Profile Image", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: _pickProfileImage,
              ),
              if (_profileImageFile != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Image.file(_profileImageFile!, height: 100),
                ),

              const SizedBox(height: 16),
              _buildTextField(addressController, "Address", Icons.location_on),
              const SizedBox(height: 16),

              _buildTextField(staffIdController, "Staff ID", Icons.badge),
              const SizedBox(height: 16),

              _buildTextField(descriptionController, "Doctor Description", Icons.description, maxLines: 4),
              const SizedBox(height: 24),

              const Text("Doctor Location",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
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
                label: const Text("Upload Certificate", style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple),
                onPressed: _pickCertificate,
              ),
              if (_certificateFile != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text("Selected: ${_certificateFile!.path.split('/').last}"),
                ),
              const SizedBox(height: 16),

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _submitForm,
                child: const Text("Submit",
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) {
      return "Enter phone number";
    }

    final RegExp phoneRegex = RegExp(r'^[89][0-9]{7}$');
    if (!phoneRegex.hasMatch(value)) {
      return "Phone must be 8 digits and start with 9 or 8";
    }
    return null;
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon,
      {bool obscure = false,
        int maxLines = 1,
        TextInputType inputType = TextInputType.text,
        String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      maxLines: maxLines,
      keyboardType: inputType,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        prefixIcon: Icon(icon),
      ),
      validator: validator ?? (value) => value == null || value.isEmpty ? "Enter $label" : null,
    );
  }

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return "Enter email";
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) return "Enter valid email";
    return null;
  }

  String? _passwordValidator(String? value) {
    if (value == null || value.length < 6) return "Password must be at least 6 characters";
    return null;
  }

  Future<void> _pickProfileImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _profileImageFile = File(picked.path));
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Selected: ${result.files.single.name}")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("No file selected")),
        );
      }
    } catch (e) {
      debugPrint("File pick error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error picking file: $e")),
      );
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
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
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
          "phone": phoneController.text.trim(), //
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
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Doctor registered successfully!")),
        );

        _formKey.currentState!.reset();
        setState(() {
          _selectedLocation = null;
          _profileImageFile = null;
          _certificateFile = null;
        });
      } on FirebaseAuthException catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: ${e.message}")),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }
}
