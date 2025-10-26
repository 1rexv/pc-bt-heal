import 'package:flutter/material.dart';

class MedicationInfoPage extends StatefulWidget {
  const MedicationInfoPage({super.key});

  @override
  State<MedicationInfoPage> createState() => _MedicationInfoPageState();
}

class _MedicationInfoPageState extends State<MedicationInfoPage> {
  final TextEditingController _searchController = TextEditingController();

  // Example medication data
  List<Map<String, String>> medications = [
    {
      "name": "Paracetamol",
      "usage": "Pain relief, fever reducer",
      "dosage": "500mg every 4-6 hours",
      "sideEffects": "Nausea, rash, liver issues (in high doses)"
    },
    {
      "name": "Amoxicillin",
      "usage": "Antibiotic for infections",
      "dosage": "500mg every 8 hours for 7 days",
      "sideEffects": "Diarrhea, nausea, allergic reaction"
    },
    {
      "name": "Folic Acid",
      "usage": "Supports fetal development, prevents birth defects",
      "dosage": "400-800 mcg daily",
      "sideEffects": "Rare: nausea, bloating"
    },
  ];

  List<Map<String, String>> filteredMedications = [];

  @override
  void initState() {
    super.initState();
    filteredMedications = medications;
  }

  void _filterMedications(String query) {
    setState(() {
      filteredMedications = medications
          .where((med) => med['name']!.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medication Info", style: TextStyle(color: Colors.white)),
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
                hintText: "Search medication by name",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: _filterMedications,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filteredMedications.isEmpty
                  ? const Center(child: Text("No medication found"))
                  : ListView.builder(
                itemCount: filteredMedications.length,
                itemBuilder: (context, index) {
                  final med = filteredMedications[index];
                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med['name']!,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          Text("Usage: ${med['usage']}"),
                          Text("Dosage: ${med['dosage']}"),
                          Text("Side Effects: ${med['sideEffects']}"),
                        ],
                      ),
                    ),
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
