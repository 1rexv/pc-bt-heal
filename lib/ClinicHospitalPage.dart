import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:url_launcher/url_launcher.dart';

class ClinicHospitalPage extends StatefulWidget {
  const ClinicHospitalPage({super.key});

  @override
  State<ClinicHospitalPage> createState() => _ClinicHospitalPageState();
}

class _ClinicHospitalPageState extends State<ClinicHospitalPage> {
  GoogleMapController? _mapController;
  final DatabaseReference _doctorsRef =
  FirebaseDatabase.instance.ref().child("doctors");

  // store loaded doctors to use in bottom sheet
  final Map<String, Map<String, dynamic>> _doctorsMap = {};
  Set<Marker> _markers = {};
  bool _isLoading = true;
  LatLng _initialPosition = const LatLng(23.5859, 58.4059); // Default Oman location

  @override
  void initState() {
    super.initState();
    _loadDoctorLocations();
  }

  Future<void> _loadDoctorLocations() async {
    try {
      final snapshot = await _doctorsRef.get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);

        Set<Marker> loadedMarkers = {};
        final Map<String, Map<String, dynamic>> loadedDoctors = {};

        data.forEach((key, value) {
          final doctor = Map<String, dynamic>.from(value);

          final lat = doctor['location']?['lat'];
          final lng = doctor['location']?['lng'];

          if (lat != null && lng != null) {
            final position = LatLng(
              double.parse(lat.toString()),
              double.parse(lng.toString()),
            );

            loadedDoctors[key] = doctor;

            loadedMarkers.add(
              Marker(
                markerId: MarkerId(key),
                position: position,
                infoWindow: InfoWindow(
                  title: (doctor['fullName'] ?? 'Doctor').toString(),
                  snippet: (doctor['description'] ?? '').toString(),
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueViolet),
                onTap: () {
                  // show bottom sheet with details
                  _onMarkerTapped(key);
                },
              ),
            );
          }
        });

        setState(() {
          _doctorsMap.clear();
          _doctorsMap.addAll(loadedDoctors);

          _markers = loadedMarkers;
          if (loadedMarkers.isNotEmpty) {
            _initialPosition = loadedMarkers.first.position;
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      debugPrint("❌ Error loading doctor locations: $e");
    }
  }

  Future<void> _onMarkerTapped(String doctorId) async {
    final doctor = _doctorsMap[doctorId];
    if (doctor == null) return;

    final isArabic =
    Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

    final name = (isArabic && (doctor['fullNameAr'] ?? '').toString().isNotEmpty)
        ? doctor['fullNameAr']
        : (doctor['fullName'] ?? (isArabic ? 'طبيب' : 'Doctor'));

    final address = (isArabic && (doctor['addressAr'] ?? '').toString().isNotEmpty)
        ? doctor['addressAr']
        : (doctor['address'] ?? (isArabic ? 'العنوان غير متوفر' : 'Address not available'));

    final description = (isArabic && (doctor['descriptionAr'] ?? '').toString().isNotEmpty)
        ? doctor['descriptionAr']
        : (doctor['description'] ?? '');

    final lat = doctor['location']?['lat'];
    final lng = doctor['location']?['lng'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Directionality(
          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              isArabic ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  name ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16, color: Colors.purple),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        address ?? '',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
                if ((description ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(color: Colors.black87),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: Text(isArabic ? 'الاتجاهات' : 'Get Directions'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                        ),
                        onPressed: (lat != null && lng != null)
                            ? () {
                          _openMaps(double.parse(lat.toString()),
                              double.parse(lng.toString()));
                        }
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.close),
                      label: Text(isArabic ? 'إغلاق' : 'Close'),
                      style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMaps(double lat, double lng) async {
    final googleUrl = Uri.parse('google.navigation:q=$lat,$lng&mode=d');
    final appleUrl = Uri.parse('http://maps.apple.com/?daddr=$lat,$lng');

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl);
    } else if (await canLaunchUrl(appleUrl)) {
      await launchUrl(appleUrl);
    } else {
      // last resort open geo:
      final geo = Uri.parse('geo:$lat,$lng');
      if (await canLaunchUrl(geo)) {
        await launchUrl(geo);
      } else {
        if (mounted) {
          final isArabic =
          Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isArabic
                    ? 'لا يمكن فتح تطبيق الخرائط على هذا الجهاز.'
                    : 'Could not open maps on this device.',
              ),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic =
    Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

    final titleText = isArabic ? "مواقع الأطباء" : "Doctors Locations";
    final loadingText = isArabic ? "جاري تحميل المواقع..." : "Loading locations...";
    final errorText = isArabic ? "حدث خطأ أثناء تحميل المواقع" : "Error loading locations";

    return Scaffold(
      appBar: AppBar(
        title: Text(titleText, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 12),
          Text(loadingText),
        ],
      ))
          : (_markers.isEmpty
          ? Center(child: Text(isArabic ? 'لا توجد مواقع متاحة' : 'No locations available'))
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 10,
        ),
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
      )),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}
