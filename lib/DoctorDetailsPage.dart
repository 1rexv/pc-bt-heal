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
      final snapshot = await FirebaseDatabase.instance
          .ref("doctors")
          .orderByChild("staffId")
          .equalTo(widget.staffId)
          .get();

      if (!snapshot.exists) return;

      final data = Map<String, dynamic>.from(snapshot.value as Map);
      final doctor = data.values.first as Map;

      if (doctor['profileImage'] != null &&
          doctor['profileImage'].toString().isNotEmpty) {
        setState(() => _doctorImageUrl = doctor['profileImage']);
        return;
      }

      final uid = data.keys.first.toString();
      final ref =
      FirebaseStorage.instance.ref("doctors/$uid/profile.jpg");
      final url = await ref.getDownloadURL();
      setState(() => _doctorImageUrl = url);
    } catch (e) {
      debugPrint("⚠️ Image load failed: $e");
    }
  }

  Future<void> _saveAppointmentToDatabase(BuildContext context) async {
    final currentUser = FirebaseAuth.instance.currentUser;
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic
                ? "يجب تسجيل الدخول لحجز موعد"
                : "You must be logged in to book an appointment",
          ),
        ),
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
        final data =
        Map<String, dynamic>.from(doctorSnapshot.value as Map);
        doctorEmail = data.values.first['email'] ?? "";
      }

      final ref =
      FirebaseDatabase.instance.ref("appointments").push();

      await ref.set({
        'appointmentId': ref.key,
        'doctorName': widget.doctorName,
        'doctorEmail': doctorEmail.trim().toLowerCase(),
        'location': widget.address,
        'patientEmail': (currentUser.email ?? '').trim().toLowerCase(),
        'patientName': currentUser.displayName ?? 'Unknown Patient',
        'date': '',
        'time': '',
        'status': 'pending',
        'paid': false,
        'startMeeting': false,
        'roomId': '',
      });


      _showBookingDialog(context);
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isArabic ? "حدث خطأ أثناء الحجز" : "Booking failed",
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text(
          widget.doctorName,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Container(
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
                backgroundImage:
                _doctorImageUrl != null ? NetworkImage(_doctorImageUrl!) : null,
                child: _doctorImageUrl == null
                    ? const Icon(Icons.person,
                    size: 60, color: Colors.purple)
                    : null,
              ),

              const SizedBox(height: 16),

              Text(
                widget.doctorName,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                widget.specialization,
                style: const TextStyle(
                    fontSize: 16, color: Colors.purple),
              ),

              const SizedBox(height: 12),

              _detailRow(
                  isArabic ? "العنوان" : "Address", widget.address),
              _detailRow(isArabic ? "الوصف" : "Description",
                  widget.description),
              _detailRow(
                  isArabic ? "السعر" : "Price", "6 OMR"),

              const SizedBox(height: 16),

              // ===== LOCATION MAP =====
              if (widget.lat != null && widget.lng != null) ...[
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    isArabic ? "الموقع:" : "Location:",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target:
                        LatLng(widget.lat!, widget.lng!),
                        zoom: 14,
                      ),
                      markers: {
                        Marker(
                          markerId:
                          const MarkerId("doctorLocation"),
                          position:
                          LatLng(widget.lat!, widget.lng!),
                          icon: BitmapDescriptor
                              .defaultMarkerWithHue(
                              BitmapDescriptor.hueRose),
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
                  onPressed: () =>
                      _saveAppointmentToDatabase(context),
                  icon: const Icon(Icons.calendar_month,
                      color: Colors.white),
                  label: Text(
                    isArabic ? "حجز موعد" : "Book Appointment",
                    style:
                    const TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding:
                    const EdgeInsets.symmetric(vertical: 14),
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

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$title: ",
            style: const TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showBookingDialog(BuildContext context) {
    final bool isArabic =
        Localizations.localeOf(context).languageCode == 'ar';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 35,
                backgroundColor: Colors.green,
                child:
                Icon(Icons.check, color: Colors.white),
              ),
              const SizedBox(height: 16),
              Text(
                isArabic
                    ? "تم الحجز بنجاح!"
                    : "Booked Successfully!",
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                      const BookedAppointmentsPage(),
                    ),
                  );
                },
                child: Text(isArabic
                    ? "عرض مواعيدي"
                    : "Show My Appointments"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
