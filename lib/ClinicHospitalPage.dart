import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:firebase_database/firebase_database.dart';

class ClinicHospitalPage extends StatefulWidget {
  const ClinicHospitalPage({super.key});

  @override
  State<ClinicHospitalPage> createState() => _ClinicHospitalPageState();
}

class _ClinicHospitalPageState extends State<ClinicHospitalPage> {
  GoogleMapController? _mapController;
  final DatabaseReference _doctorsRef =
  FirebaseDatabase.instance.ref().child("doctors");

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
        data.forEach((key, value) {
          final doctor = Map<String, dynamic>.from(value);

          final lat = doctor['location']?['lat'];
          final lng = doctor['location']?['lng'];

          if (lat != null && lng != null) {
            loadedMarkers.add(
              Marker(
                markerId: MarkerId(key),
                position: LatLng(
                  double.parse(lat.toString()),
                  double.parse(lng.toString()),
                ),
                infoWindow: InfoWindow(
                  title: doctor['fullName'] ?? 'Doctor',
                  snippet: doctor['description'] ?? '',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueViolet),
              ),
            );
          }
        });

        setState(() {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Doctors Locations",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GoogleMap(
        initialCameraPosition: CameraPosition(
          target: _initialPosition,
          zoom: 8,
        ),
        markers: _markers,
        onMapCreated: (controller) => _mapController = controller,
        zoomControlsEnabled: true,
        mapType: MapType.normal,
      ),
    );
  }
}
