import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminDoctorListPage extends StatelessWidget {
  const AdminDoctorListPage({super.key});

  bool _isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(BuildContext context, String en, String ar) => _isArabic(context) ? ar : en;

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple;
    final isArabic = _isArabic(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'Doctors', 'الأطباء'),
            style: const TextStyle(color: Colors.white)),
        backgroundColor: purple,
        centerTitle: true,
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: FirebaseDatabase.instance.ref('doctors').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return Center(child: Text(_t(context, 'No doctors found.', 'لا يوجد أطباء.')));
          }

          final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final doctorList = data.entries.map((entry) {
            final uid = entry.key;
            final doc = Map<String, dynamic>.from(entry.value);
            doc['uid'] = uid;
            return doc;
          }).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: doctorList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doctor = doctorList[index];

              final fullName = (doctor['fullName'] ?? '') as String;
              final email = (doctor['email'] ?? '') as String;
              final phone = (doctor['phone'] ?? '') as String;
              final address = (doctor['address'] ?? '') as String;
              final profileImage = (doctor['profileImage'] ?? '') as String;

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => DoctorDetailsPage(doctor: doctor),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(16),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: purple.withOpacity(0.1),
                          backgroundImage: profileImage.isNotEmpty
                              ? NetworkImage(profileImage)
                              : null,
                          child: profileImage.isEmpty ? const Icon(Icons.person, size: 32) : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                            children: [
                              Text(
                                fullName.isEmpty ? _t(context, 'Unknown Doctor', 'طبيب غير معروف') : fullName,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                textAlign: isArabic ? TextAlign.right : TextAlign.left,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                children: [
                                  const Icon(Icons.email, size: 16),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      email,
                                      style: const TextStyle(fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              if (phone.isNotEmpty)
                                Row(
                                  mainAxisAlignment:
                                  isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.phone, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      phone,
                                      style: const TextStyle(fontSize: 13),
                                      textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 2),
                              if (address.isNotEmpty)
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment:
                                  isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.location_on, size: 16),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        address,
                                        style: const TextStyle(fontSize: 13),
                                        textAlign: isArabic ? TextAlign.right : TextAlign.left,
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 8),
                              Align(
                                alignment: isArabic ? Alignment.centerLeft : Alignment.centerRight,
                                child: TextButton.icon(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => DoctorDetailsPage(doctor: doctor),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.info_outline),
                                  label: Text(_t(context, 'View Details', 'عرض التفاصيل')),
                                  style: TextButton.styleFrom(foregroundColor: purple),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Detailed view for a single doctor
class DoctorDetailsPage extends StatelessWidget {
  final Map<String, dynamic> doctor;

  const DoctorDetailsPage({super.key, required this.doctor});

  LatLng? _getLatLngFromDoctor() {
    if (doctor['location'] == null) return null;
    final loc = Map<String, dynamic>.from(doctor['location']);
    final lat = loc['lat'];
    final lng = loc['lng'];
    if (lat == null || lng == null) return null;
    try {
      final dLat = double.tryParse(lat.toString()) ?? (lat as num).toDouble();
      final dLng = double.tryParse(lng.toString()) ?? (lng as num).toDouble();
      return LatLng(dLat, dLng);
    } catch (_) {
      return null;
    }
  }

  Future<void> _openCertificate(BuildContext context) async {
    final certUrl = (doctor['certificates'] ?? '') as String;
    final isArabic = Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');
    final t = (String en, String ar) => isArabic ? ar : en;

    if (certUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('No certificate uploaded', 'لم يتم رفع شهادة'))),
      );
      return;
    }

    final uri = Uri.tryParse(certUrl);
    if (uri == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Invalid certificate link', 'رابط الشهادة غير صالح'))),
      );
      return;
    }

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Could not open certificate link', 'تعذر فتح رابط الشهادة'))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple;
    final isArabic = Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');
    final t = (String en, String ar) => isArabic ? ar : en;

    final fullName = (doctor['fullName'] ?? '') as String;
    final email = (doctor['email'] ?? '') as String;
    final phone = (doctor['phone'] ?? '') as String;
    final staffId = (doctor['staffId'] ?? '') as String;
    final address = (doctor['address'] ?? '') as String;
    final description = (doctor['description'] ?? '') as String;
    final profileImage = (doctor['profileImage'] ?? '') as String;
    final userType = (doctor['userType'] ?? 'Doctor') as String;

    final location = _getLatLngFromDoctor();

    return Scaffold(
      appBar: AppBar(
        title: Text(t('Doctor Details', 'تفاصيل الطبيب'), style: const TextStyle(color: Colors.white)),
        backgroundColor: purple,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            // Top Card with avatar & main info
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: purple.withOpacity(0.1),
                      backgroundImage: profileImage.isNotEmpty ? NetworkImage(profileImage) : null,
                      child: profileImage.isEmpty ? const Icon(Icons.person, size: 40) : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          Text(
                            fullName.isEmpty ? t('Unknown Doctor', 'طبيب غير معروف') : fullName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            userType,
                            style: TextStyle(
                              fontSize: 14,
                              color: purple.shade300,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: isArabic ? TextAlign.right : TextAlign.left,
                          ),
                          const SizedBox(height: 8),
                          if (staffId.isNotEmpty)
                            Row(
                              mainAxisAlignment:
                              isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                              children: [
                                const Icon(Icons.badge, size: 18),
                                const SizedBox(width: 6),
                                Text('${t('Staff ID', 'الرقم الوظيفي')}: $staffId'),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Contact info card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Column(
                  crossAxisAlignment:
                  isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Text(t('Contact Information', 'معلومات الاتصال'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment:
                      isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                      children: [
                        const Icon(Icons.email_outlined, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(email, textAlign: isArabic ? TextAlign.right : TextAlign.left),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (phone.isNotEmpty)
                      Row(
                        mainAxisAlignment:
                        isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.phone_outlined, size: 20),
                          const SizedBox(width: 8),
                          Text(phone, textAlign: isArabic ? TextAlign.right : TextAlign.left),
                        ],
                      ),
                    const SizedBox(height: 6),
                    if (address.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment:
                        isArabic ? MainAxisAlignment.end : MainAxisAlignment.start,
                        children: [
                          const Icon(Icons.location_on_outlined, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(address, textAlign: isArabic ? TextAlign.right : TextAlign.left),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Description card
            if (description.isNotEmpty)
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment:
                    isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(t('Doctor Description', 'وصف الطبيب'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Text(description, textAlign: isArabic ? TextAlign.right : TextAlign.left),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 20),

            // Location map (if available)
            if (location != null)
              Column(
                crossAxisAlignment:
                isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: isArabic ? Alignment.centerRight : Alignment.centerLeft,
                    child: Text(t('Location', 'الموقع'),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: SizedBox(
                      height: 200,
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(target: location, zoom: 13),
                        markers: {
                          Marker(markerId: const MarkerId('doctor-location'), position: location),
                        },
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        onMapCreated: (controller) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),

            // Certificate button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _openCertificate(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: Text(t('View Certificate', 'عرض الشهادة')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
