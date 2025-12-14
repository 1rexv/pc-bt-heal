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
  final DatabaseReference _notificationsRef =
  FirebaseDatabase.instance.ref('patientNotifications');

  List<Map<String, dynamic>> _patients = [];
  List<Map<String, dynamic>> _medicineHistory = [];

  // 🌍 Translation helper
  late bool isArabic;

  String t(String key) {
    const map = {
      'title': {'en': 'Add / Update Medicine', 'ar': 'إضافة / تعديل دواء'},
      'selectPatient': {'en': 'Select Patient', 'ar': 'اختر المريض'},
      'medicineName': {'en': 'Medicine Name', 'ar': 'اسم الدواء'},
      'dosage': {'en': 'Dosage Instructions', 'ar': 'تعليمات الجرعة'},
      'duration': {'en': 'Duration', 'ar': 'المدة'},
      'unit': {'en': 'Unit', 'ar': 'الوحدة'},
      'days': {'en': 'Days', 'ar': 'أيام'},
      'weeks': {'en': 'Weeks', 'ar': 'أسابيع'},
      'months': {'en': 'Months', 'ar': 'أشهر'},
      'submit': {'en': 'Submit', 'ar': 'حفظ'},
      'update': {'en': 'Update', 'ar': 'تحديث'},
      'history': {'en': 'Medicine History', 'ar': 'سجل الأدوية'},
      'noData': {'en': 'No medicines found.', 'ar': 'لا توجد أدوية'},
      'patient': {'en': 'Patient', 'ar': 'المريض'},
      'durationLabel': {'en': 'Duration', 'ar': 'المدة'},
      'dosageLabel': {'en': 'Dosage', 'ar': 'الجرعة'},
      'fillAll': {
        'en': 'Please fill in all required fields',
        'ar': 'يرجى تعبئة جميع الحقول'
      },
      'added': {
        'en': 'Medicine added successfully!',
        'ar': 'تمت إضافة الدواء بنجاح'
      },
      'updated': {
        'en': 'Medicine updated successfully!',
        'ar': 'تم تحديث الدواء بنجاح'
      },
      'deleted': {
        'en': 'Medicine deleted successfully!',
        'ar': 'تم حذف الدواء'
      },
    };
    return map[key]![isArabic ? 'ar' : 'en']!;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isArabic = Localizations.localeOf(context).languageCode == 'ar';
  }

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
      final email = appointment['patientEmail'];
      uniquePatients[email] = {
        'email': email,
        'name': appointment['patientName'] ?? 'Unknown'
      };
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

    setState(() {
      _medicineHistory = data.entries
          .map((e) => {...Map<String, dynamic>.from(e.value), 'key': e.key})
          .where((m) => m['doctorEmail'] == doctor.email)
          .toList();
    });
  }

  Future<void> _submitMedicineDetails() async {
    if (_selectedPatient == null ||
        _nameController.text.isEmpty ||
        _dosageController.text.isEmpty ||
        _durationController.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('fillAll'))));
      return;
    }

    final doctor = FirebaseAuth.instance.currentUser!;
    final isEdit = _editingMedicineId != null;

    final data = {
      'doctorEmail': doctor.email,
      'doctorName': doctor.displayName ?? '',
      'patientEmail': _selectedPatient!['email'],
      'patientName': _selectedPatient!['name'],
      'name': _nameController.text,
      'dosage': _dosageController.text,
      'duration': _durationController.text,
      'durationType': _durationType,
      'timestamp': DateTime.now().toIso8601String(),
    };

    if (isEdit) {
      await _medicinesRef.child(_editingMedicineId!).update(data);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('updated'))));
    } else {
      await _medicinesRef.push().set(data);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(t('added'))));
    }

    _nameController.clear();
    _dosageController.clear();
    _durationController.clear();
    _editingMedicineId = null;
    _selectedPatient = null;

    _loadMedicineHistory();
  }

  Future<void> _deleteMedicine(String id) async {
    await _medicinesRef.child(id).remove();
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(t('deleted'))));
    _loadMedicineHistory();
  }

  void _editMedicine(Map<String, dynamic> med) {
    setState(() {
      _editingMedicineId = med['key'];
      _nameController.text = med['name'];
      _dosageController.text = med['dosage'];
      _durationController.text = med['duration'];
      _durationType = med['durationType'];
      _selectedPatient =
          _patients.firstWhere((p) => p['email'] == med['patientEmail']);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('title'), style: const TextStyle(color: Colors.white)),
          backgroundColor: Colors.purple,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(children: [
            _buildForm(),
            const SizedBox(height: 30),
            Text(t('history'),
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple)),
            const SizedBox(height: 10),
            _medicineHistory.isEmpty
                ? Text(t('noData'))
                : _buildHistory()
          ]),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 10)
          ]),
      child: Column(children: [
        DropdownButtonFormField<Map<String, dynamic>>(
          value: _selectedPatient,
          decoration: InputDecoration(labelText: t('selectPatient')),
          items: _patients
              .map((p) =>
              DropdownMenuItem(value: p, child: Text(p['name'])))
              .toList(),
          onChanged: (v) => setState(() => _selectedPatient = v),
        ),
        const SizedBox(height: 16),
        TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: t('medicineName'))),
        const SizedBox(height: 16),
        TextField(
            controller: _dosageController,
            decoration: InputDecoration(labelText: t('dosage'))),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: TextField(
                controller: _durationController,
                decoration: InputDecoration(labelText: t('duration'))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: _durationType,
              decoration: InputDecoration(labelText: t('unit')),
              items: ['Days', 'Weeks', 'Months']
                  .map((e) =>
                  DropdownMenuItem(value: e, child: Text(t(e.toLowerCase()))))
                  .toList(),
              onChanged: (v) => setState(() => _durationType = v!),
            ),
          )
        ]),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: _submitMedicineDetails,
          child: Text(_editingMedicineId == null ? t('submit') : t('update')),
        )
      ]),
    );
  }

  Widget _buildHistory() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _medicineHistory.length,
      itemBuilder: (_, i) {
        final m = _medicineHistory[i];
        return Card(
          child: ListTile(
            title: Text(m['name'], style: const TextStyle(color: Colors.purple)),
            subtitle: Text(
                "${t('patient')}: ${m['patientName']}\n${t('dosageLabel')}: ${m['dosage']}\n${t('durationLabel')}: ${m['duration']} ${t(m['durationType'].toLowerCase())}"),
            trailing: Wrap(children: [
              IconButton(
                  icon: const Icon(Icons.edit, color: Colors.green),
                  onPressed: () => _editMedicine(m)),
              IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteMedicine(m['key']))
            ]),
          ),
        );
      },
    );
  }
}
