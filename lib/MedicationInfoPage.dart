import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicationInfoPage extends StatefulWidget {
  const MedicationInfoPage({super.key});

  @override
  State<MedicationInfoPage> createState() => _MedicationInfoPageState();
}

class _MedicationInfoPageState extends State<MedicationInfoPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _medications = [];
  List<Map<String, dynamic>> _filteredMedications = [];

  StreamSubscription<DatabaseEvent>? _notifSub;
  final Set<String> _existingNotificationKeys = {};
  final Set<String> _processedNotificationKeys = {};

  @override
  void initState() {
    super.initState();
    _fetchMedications();
    _listenToNotifications();
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  // Fetch Medications
  Future<void> _fetchMedications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseDatabase.instance.ref('medicines').get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      final meds = data.entries.map((e) {
        final m = Map<String, dynamic>.from(e.value);
        m['key'] = e.key;
        return m;
      }).where((m) => (m['patientEmail'] ?? '') == user.email).toList();

      setState(() {
        _medications = meds.reversed.toList();
        _filteredMedications = _medications;
      });
    } else {
      setState(() {
        _medications = [];
        _filteredMedications = [];
      });
    }
  }

  //  Real-time Notifications
  void _listenToNotifications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseDatabase.instance.ref('patientNotifications');

    try {
      // existing notifications
      final existingSnap =
      await ref.orderByChild('patientEmail').equalTo(user.email).get();

      if (existingSnap.exists) {
        final map = Map<String, dynamic>.from(existingSnap.value as Map);
        for (final entry in map.entries) {
          _existingNotificationKeys.add(entry.key);
        }
      }

      // Listen for NEW notifications only
      _notifSub = ref
          .orderByChild('patientEmail')
          .equalTo(user.email)
          .onChildAdded
          .listen((event) {
        if (!event.snapshot.exists) return;

        final key = event.snapshot.key;
        if (key == null) return;

        if (_existingNotificationKeys.contains(key)) {
          _processedNotificationKeys.add(key);
          return;
        }
        if (_processedNotificationKeys.contains(key)) return;

        _processedNotificationKeys.add(key);

        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        final type = (data['type'] ?? '').toString();

        if (type != 'medicine_added' && type != 'medicine_updated') return;

        final doctorName = data['doctorName'] ?? '';
        final medicineName = data['medicineName'] ?? '';

        final isArabic = Localizations.localeOf(context).languageCode.startsWith('ar');

        final title = isArabic ? "إشعار جديد" : "New Notification";
        final body = type == 'medicine_added'
            ? (isArabic
            ? "د. $doctorName أضاف/أضافت دواء جديد: $medicineName"
            : "Dr. $doctorName added a new medicine: $medicineName")
            : (isArabic
            ? "د. $doctorName حدّث/حدّثت الدواء: $medicineName"
            : "Dr. $doctorName updated the medicine: $medicineName");

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "$title\n$body",
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
            ),
            duration: const Duration(seconds: 4),
          ),
        );

        _fetchMedications();
      });
    } catch (e) {
      debugPrint("Notification error: $e");
    }
  }

  // Filter
  void _filterMedications(String query) {
    setState(() {
      _filteredMedications = _medications
          .where((med) =>
      (med['name'] ?? '').toString().toLowerCase().contains(query.toLowerCase()) ||
          (med['doctorName'] ?? '').toString().toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  
  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode.startsWith("ar");
    final direction = isArabic ? TextDirection.rtl : TextDirection.ltr;

    return Directionality(
      textDirection: direction,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            isArabic ? "الأدوية الموصوفة" : "My Prescribed Medications",
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          centerTitle: true,
        ),

        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Search
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: isArabic
                      ? "ابحث عن دواء أو اسم الطبيب"
                      : "Search medication or doctor",
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: _filterMedications,
              ),

              const SizedBox(height: 16),

              // List
              Expanded(
                child: _filteredMedications.isEmpty
                    ? Center(
                  child: Text(
                    isArabic ? "لا توجد أدوية." : "No medications found.",
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
                    : ListView.builder(
                  itemCount: _filteredMedications.length,
                  itemBuilder: (context, index) {
                    final med = _filteredMedications[index];
                    final date = DateTime.tryParse(med['timestamp'] ?? "");

                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title row
                            Row(
                              children: [
                                const Icon(Icons.medication, color: Colors.purple),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    med['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.purple,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),

                            // Doctor
                            Text(
                              isArabic
                                  ? "موصوف بواسطة: ${med['doctorEmail'] ?? 'غير معروف'}"
                                  : "Prescribed by: ${med['doctorEmail'] ?? 'Unknown'}",
                              style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.black87,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Dosage
                            Text(
                              "${isArabic ? 'الجرعة' : 'Dosage'}: ${med['dosage'] ?? '-'}",
                            ),

                            // Duration
                            Text(
                              "${isArabic ? 'المدة' : 'Duration'}: ${med['duration'] ?? '-'} ${med['durationType'] ?? ''}",
                              style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                            const SizedBox(height: 4),

                            // Date
                            Text(
                              "${isArabic ? 'التاريخ' : 'Date'}: ${date != null ? date.toLocal().toString().split(' ')[0] : (isArabic ? 'غير معروف' : 'Unknown')}",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
