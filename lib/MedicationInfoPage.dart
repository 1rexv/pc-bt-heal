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

  @override
  void initState() {
    super.initState();
    _fetchMedications();
  }

  Future<void> _fetchMedications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseDatabase.instance.ref('medicines').get();

    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);

      final meds = data.entries
          .map((e) => Map<String, dynamic>.from(e.value))
          .where((m) => (m['patientEmail'] ?? '') == user.email)
          .toList();

      setState(() {
        _medications = meds.reversed.toList();
        _filteredMedications = _medications;
      });
    }
  }

  void _filterMedications(String query) {
    setState(() {
      _filteredMedications = _medications
          .where((med) =>
      (med['name'] ?? '')
          .toString()
          .toLowerCase()
          .contains(query.toLowerCase()) ||
          (med['doctorName'] ?? '')
              .toString()
              .toLowerCase()
              .contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text("My Prescribed Medications", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: "Search medication or doctor name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterMedications,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: _filteredMedications.isEmpty
                  ? const Center(
                child: Text(
                  "No medication found.",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              )
                  : ListView.builder(
                itemCount: _filteredMedications.length,
                itemBuilder: (context, index) {
                  final med = _filteredMedications[index];
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
                          Text(
                            "Prescribed by: ${med['doctorEmail'] ?? 'Unknown Doctor'}",
                            style: const TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.black87),
                          ),
                          const SizedBox(height: 4),
                          Text("Dosage: ${med['dosage'] ?? '-'}"),
                          Text(
                            "Duration: ${med['duration'] ?? '-'} ${med['durationType'] ?? ''}",
                            style: const TextStyle(
                                color: Colors.black87,
                                fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Date: ${DateTime.tryParse(med['timestamp'] ?? '')?.toLocal().toString().split(' ')[0] ?? 'Unknown'}",
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 12),
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
    );
  }
}
