import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'BookedAppointmentsPage.dart';

class DoctorDetailsPage extends StatefulWidget {
  final String doctorName;
  final String specialization;
  final String staffId;
  final String address;
  final String description;
  final double? lat;
  final double? lng;
  final String? profileImage;

  const DoctorDetailsPage({
    super.key,
    required this.doctorName,
    required this.specialization,
    required this.staffId,
    required this.address,
    required this.description,
    this.lat,
    this.lng,
    this.profileImage,
  });

  @override
  State<DoctorDetailsPage> createState() => _DoctorDetailsPageState();
}

class _DoctorDetailsPageState extends State<DoctorDetailsPage> {
  String? _doctorImageUrl;

  bool get isArabic =>
      Directionality.of(context) == TextDirection.rtl;

  String _t(String ar, String en) => isArabic ? ar : en;

  @override
  void initState() {
    super.initState();
    _loadDoctorImage();
  }

  Future<void> _loadDoctorImage() async {
    try {
      final snapshot = await FirebaseDatabase.instance
          .ref("doctors")
          .orderByChild("staffId")
          .equalTo(widget.staffId)
          .get();

      if (snapshot.exists && snapshot.value is Map) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        final first = Map<String, dynamic>.from(data.values.first);

        if (first['profileImage'] != null &&
            first['profileImage'].toString().isNotEmpty) {
          setState(() => _doctorImageUrl = first['profileImage']);
          return;
        }

        final uid = data.keys.first.toString();
        final ref =
        FirebaseStorage.instance.ref("doctors/$uid/profile.jpg");
        final url = await ref.getDownloadURL();
        setState(() => _doctorImageUrl = url);
      }
    } catch (e) {
      debugPrint("Image load error: $e");
    }
  }

  Future<void> _saveAppointment(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("يجب تسجيل الدخول", "You must login"))),
      );
      return;
    }

    try {
      String doctorEmail = "";

      final doctorSnap = await FirebaseDatabase.instance
          .ref("doctors")
          .orderByChild("staffId")
          .equalTo(widget.staffId)
          .get();

      if (doctorSnap.exists && doctorSnap.value is Map) {
        final data = Map<String, dynamic>.from(doctorSnap.value as Map);
        doctorEmail =
            Map<String, dynamic>.from(data.values.first)['email'] ?? "";
      }

      final ref =
      FirebaseDatabase.instance.ref("appointments").push();

      await ref.set({
        'appointmentId': ref.key,
        'doctorName': widget.doctorName,
        'doctorEmail': doctorEmail,
        'location': widget.address,
        'patientEmail': user.email,
        'patientName': user.displayName ?? "Patient",
        'status': 'pending',
        'paid': false,
      });

      _showSuccessDialog(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("$e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection:
      isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.purple.shade50,
        appBar: AppBar(
          title: Text(widget.doctorName),
          backgroundColor: Colors.purple,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CircleAvatar(
                radius: 60,
                backgroundImage: _doctorImageUrl != null
                    ? NetworkImage(_doctorImageUrl!)
                    : null,
                child: _doctorImageUrl == null
                    ? const Icon(Icons.person, size: 60)
                    : null,
              ),
              const SizedBox(height: 16),

              Text(widget.doctorName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),

              Text(widget.specialization,
                  style: const TextStyle(
                      fontSize: 16, color: Colors.purple)),

              const SizedBox(height: 16),

              _infoRow(_t("العنوان", "Address"), widget.address),
              _infoRow(_t("الوصف", "Description"), widget.description),
              _infoRow(_t("السعر", "Price"), "6 OMR"),

              if (widget.lat != null && widget.lng != null) ...[
                const SizedBox(height: 20),
                Align(
                  alignment: isArabic
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Text(
                    _t("الموقع", "Location"),
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target:
                      LatLng(widget.lat!, widget.lng!),
                      zoom: 14,
                    ),
                    markers: {
                      Marker(
                        markerId:
                        const MarkerId("doctor"),
                        position: LatLng(
                            widget.lat!, widget.lng!),
                      ),
                    },
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _saveAppointment(context),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                      _t("حجز موعد", "Book Appointment")),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ",
              style:
              const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_t("تم بنجاح", "Success")),
        content: Text(_t(
            "تم حجز الموعد بنجاح",
            "Appointment booked successfully")),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const BookedAppointmentsPage()),
              );
            },
            child:
            Text(_t("عرض مواعيدي", "My Appointments")),
          ),
        ],
      ),
    );
  }
}
