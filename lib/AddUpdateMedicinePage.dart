import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddUpdateMedicinePage extends StatefulWidget {
  const AddUpdateMedicinePage({super.key});

  @override
  State<AddUpdateMedicinePage> createState() => _AddUpdateMedicinePageState();
}

class _AddUpdateMedicinePageState extends State<AddUpdateMedicinePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _durationController = TextEditingController();

  String _durationType = 'Days';
  Map<String, dynamic>? _selectedPatient;
  String? _editingMedicineId;

  final DatabaseReference _appointmentsRef =
  FirebaseDatabase.instance.ref('appointments');
  final DatabaseReference _medicinesRef =
  FirebaseDatabase.instance.ref('medicines');

  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _medicineHistory = [];

  @override
  void initState() {
    super.initState();
    _loadPatients();
    _loadMedicineHistory();
  }

  Future<void> _loadPatients() async {
    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) return;

    final snapshot = await _appointmentsRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);

    final doctorAppointments = data.entries
        .map((e) => Map<String, dynamic>.from(e.value))
        .where((a) =>
    (a['doctorEmail'] ?? '') == doctor.email &&
        (a['status'] ?? '').toString().toLowerCase() == 'accepted')
        .toList();

    final Map<String, Map<String, dynamic>> uniquePatients = {};

    for (var appointment in doctorAppointments) {
      final email = (appointment['patientEmail'] ?? '').toString();
      final name = (appointment['patientName'] ?? 'Unknown').toString();
      uniquePatients[email] = {'email': email, 'name': name};
    }

    setState(() {
      _patients = uniquePatients.values.toList();
    });
  }

  Future<void> _loadMedicineHistory() async {
    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) return;

    final snapshot = await _medicinesRef.get();
    if (!snapshot.exists) return;

    final data = Map<String, dynamic>.from(snapshot.value as Map);
    final doctorMeds = data.entries
        .map((e) => Map<String, dynamic>.from(e.value))
        .where((m) => (m['doctorEmail'] ?? '') == doctor.email)
        .toList();

    setState(() {
      _medicineHistory = doctorMeds;
    });
  }

  Future<void> _submitMedicineDetails() async {
    final name = _nameController.text.trim();
    final dosage = _dosageController.text.trim();
    final durationValue = _durationController.text.trim();

    if (_selectedPatient == null ||
        name.isEmpty ||
        dosage.isEmpty ||
        durationValue.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please fill in all required fields')),
      );
      return;
    }

    final doctor = FirebaseAuth.instance.currentUser;
    if (doctor == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Please login as doctor first')),
      );
      return;
    }

    if (_editingMedicineId != null) {
      await _medicinesRef.child(_editingMedicineId!).update({
        'name': name,
        'dosage': dosage,
        'duration': durationValue,
        'durationType': _durationType,
        'timestamp': DateTime.now().toIso8601String(),
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Medicine updated successfully!')),
      );
      _editingMedicineId = null;
    } else {
      // Add new medicine
      final newMedRef = _medicinesRef.push();
      await newMedRef.set({
        'medicineId': newMedRef.key,
        'doctorEmail': doctor.email,
        'doctorName': doctor.displayName ?? '',
        'patientEmail': _selectedPatient!['email'],
        'patientName': _selectedPatient!['name'],
        'name': name,
        'dosage': dosage,
        'duration': durationValue,
        'durationType': _durationType,
        'timestamp': DateTime.now().toIso8601String(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Medicine added successfully!')),
      );
    }

    _nameController.clear();
    _dosageController.clear();
    _durationController.clear();
    setState(() {
      _durationType = 'Days';
      _selectedPatient = null;
    });

    await _loadMedicineHistory();
  }

  Future<void> _deleteMedicine(String id) async {
    await _medicinesRef.child(id).remove();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Medicine deleted successfully!')),
    );
    await _loadMedicineHistory();
  }

  //Edit a medicine
  void _editMedicine(Map<String, dynamic> med) {
    setState(() {
      _editingMedicineId = med['medicineId'];
      _nameController.text = med['name'] ?? '';
      _dosageController.text = med['dosage'] ?? '';
      _durationController.text = med['duration'] ?? '';
      _durationType = med['durationType'] ?? 'Days';
      _selectedPatient = {
        'name': med['patientName'] ?? '',
        'email': med['patientEmail'] ?? ''
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
        const Text('Add / Update Medicine', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            //Input form
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: Column(
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedPatient,
                    decoration: InputDecoration(
                      labelText: 'Select Patient',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _patients.map((p) {
                      return DropdownMenuItem<Map<String, dynamic>>(
                        value: p,
                        child: Text('${p['name']}'),
                      );
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedPatient = val),
                  ),
                  const SizedBox(height: 20),

                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Medicine Name',
                      prefixIcon: const Icon(Icons.medication),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextField(
                    controller: _dosageController,
                    decoration: InputDecoration(
                      labelText: 'Dosage Instructions',
                      prefixIcon: const Icon(Icons.medical_information),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _durationController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Duration',
                            prefixIcon: const Icon(Icons.timer),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _durationType,
                          decoration: InputDecoration(
                            labelText: 'Unit',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'Days', child: Text('Days')),
                            DropdownMenuItem(value: 'Weeks', child: Text('Weeks')),
                            DropdownMenuItem(value: 'Months', child: Text('Months')),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _durationType = val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(_editingMedicineId == null ? Icons.save : Icons.update),
                    label: Text(
                      _editingMedicineId == null ? 'Submit' : 'Update',
                      style: const TextStyle(fontSize: 16),
                    ),
                    onPressed: _submitMedicineDetails,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            //History
            const Text(
              "Medicine History",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple),
            ),
            const SizedBox(height: 10),

            _medicineHistory.isEmpty
                ? const Text("No medicines found.")
                : ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _medicineHistory.length,
              itemBuilder: (context, index) {
                final med = _medicineHistory[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  child: ListTile(
                    title: Text(
                      med['name'] ?? 'Unnamed Medicine',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.purple),
                    ),
                    subtitle: Text(
                        "Patient: ${med['patientName']}\nDosage: ${med['dosage']}\nDuration: ${med['duration']} ${med['durationType']}"),
                    isThreeLine: true,
                    trailing: Wrap(
                      spacing: 8,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.green),
                          onPressed: () => _editMedicine(med),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteMedicine(med['medicineId']),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
