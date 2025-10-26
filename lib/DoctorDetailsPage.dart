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

  @override
  void initState() {
    super.initState();
    _loadDoctorImage();
  }

  Future<void> _loadDoctorImage() async {
    try {
      // Try to get doctor image from DB by staffId
      final doctorSnapshot = await FirebaseDatabase.instance
          .ref("doctors")
          .orderByChild("staffId")
          .equalTo(widget.staffId)
          .get();

      if (doctorSnapshot.exists) {
        final doctorData = Map<String, dynamic>.from(doctorSnapshot.value as Map);
        final firstDoctor = doctorData.values.first as Map;
        if (firstDoctor['profileImage'] != null && firstDoctor['profileImage'].toString().isNotEmpty) {
          setState(() => _doctorImageUrl = firstDoctor['profileImage']);
          return;
        }

        // Fallback: try to get from Firebase Storage if not found in DB
        final uid = doctorData.keys.first.toString();
        final ref = FirebaseStorage.instance.ref("doctors/$uid/profile.jpg");
        final url = await ref.getDownloadURL();
        setState(() => _doctorImageUrl = url);
      }
    } catch (e) {
      debugPrint("⚠️ Could not load doctor image: $e");
    }
  }

  Future<void> _saveAppointmentToDatabase(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must be logged in to book an appointment")),
      );
      return;
    }

    try {
      final doctorSnapshot = await FirebaseDatabase.instance
          .ref("doctors")
          .orderByChild("staffId")
          .equalTo(widget.staffId)
          .get();

      String doctorEmail = "";
      if (doctorSnapshot.exists) {
        final doctorData = Map<String, dynamic>.from(doctorSnapshot.value as Map);
        final firstDoctor = doctorData.values.first as Map;
        doctorEmail = firstDoctor['email'] ?? "";
      }

      final DatabaseReference ref = FirebaseDatabase.instance.ref("appointments").push();

      await ref.set({
        'appointmentId': ref.key,
        'doctorName': widget.doctorName,
        'doctorEmail': doctorEmail,
        'location': widget.address,
        'patientEmail': currentUser.email ?? '',
        'patientName': currentUser.displayName ?? 'Unknown Patient',
        'date': '',
        'time': '',
        'status': 'pending',
        'paid': false,
      });

      _showBookingDialog(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving appointment: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text(widget.doctorName, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: Colors.purple.shade100,
                backgroundImage: _doctorImageUrl != null
                    ? NetworkImage(_doctorImageUrl!)
                    : null,
                child: _doctorImageUrl == null
                    ? const Icon(Icons.person, size: 60, color: Colors.purple)
                    : null,
              ),

              const SizedBox(height: 16),
              Text(widget.doctorName,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 6),
              Text(widget.specialization,
                  style: const TextStyle(fontSize: 16, color: Colors.purple)),

              _buildDetailRow("Address", widget.address),
              _buildDetailRow("Description", widget.description),
              _buildDetailRow("Price", "6 OMR"),

              const SizedBox(height: 16),
              if (widget.lat != null && widget.lng != null) ...[
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Location:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(widget.lat!, widget.lng!),
                        zoom: 14,
                      ),
                      markers: {
                        Marker(
                          markerId: const MarkerId("doctorLocation"),
                          position: LatLng(widget.lat!, widget.lng!),
                          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRose),
                        ),
                      },
                      zoomControlsEnabled: false,
                      myLocationButtonEnabled: false,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await _saveAppointmentToDatabase(context);
                  },
                  icon: const Icon(Icons.calendar_month, color: Colors.white),
                  label: const Text("Book Appointment", style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$title: ",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 16, color: Colors.black54))),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.red),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 10),
                const CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.green,
                  child: Icon(Icons.check, color: Colors.white, size: 40),
                ),
                const SizedBox(height: 16),
                const Text("Booked Successfully!",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) => const BookedAppointmentsPage()));
                    },
                    icon: const Icon(Icons.visibility, color: Colors.white),
                    label: const Text("Show My Appointments",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
