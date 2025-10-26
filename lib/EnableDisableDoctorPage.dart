import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EnableDisableDoctorPage extends StatefulWidget {
  const EnableDisableDoctorPage({super.key});

  @override
  State<EnableDisableDoctorPage> createState() => _EnableDisableDoctorPageState();
}

class _EnableDisableDoctorPageState extends State<EnableDisableDoctorPage> {
  final DatabaseReference doctorsRef = FirebaseDatabase.instance.ref("doctors");

  /// 🔄 Toggle enabled status in Firebase
  Future<void> _toggleDoctorStatus(String doctorId, bool currentStatus) async {
    try {
      await doctorsRef.child(doctorId).update({
        'enabled': !currentStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus
                ? "✅ Doctor account enabled"
                : "🚫 Doctor account disabled",
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to update status: $e")),
      );
    }
  }

  /// 🛠️ Ensure all doctors have `enabled: true` by default if it's missing
  Future<void> _ensureEnabledField(Map<String, dynamic> doctorsMap) async {
    for (var entry in doctorsMap.entries) {
      final doctorId = entry.key;
      final doctorData = Map<String, dynamic>.from(entry.value);

      if (doctorData['enabled'] == null) {
        await doctorsRef.child(doctorId).update({'enabled': true});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Enable / Disable Doctor Accounts',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: doctorsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text("⚠️ Error loading doctors"));
          }

          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            return const Center(child: Text("No doctors found"));
          }

          final doctorsMap = Map<String, dynamic>.from(
            (snapshot.data! as DatabaseEvent).snapshot.value as Map,
          );

          // ✅ Make sure all doctors have 'enabled: true' at first load
          _ensureEnabledField(doctorsMap);

          final doctors = doctorsMap.entries.toList();

          return ListView.builder(
            itemCount: doctors.length,
            itemBuilder: (context, index) {
              final doctorId = doctors[index].key;
              final doctorData = Map<String, dynamic>.from(doctors[index].value);

              final name = doctorData["fullName"] ?? "Unknown Doctor";
              final email = doctorData["email"] ?? "-";
              final profileImage = doctorData["profileImage"];
              final enabled = doctorData["enabled"] ?? true; // ✅ Default true

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 3,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 25,
                    backgroundColor: Colors.purple.shade100,
                    backgroundImage: profileImage != null && profileImage.isNotEmpty
                        ? NetworkImage(profileImage)
                        : null,
                    child: (profileImage == null || profileImage.isEmpty)
                        ? const Icon(Icons.person, color: Colors.purple)
                        : null,
                  ),
                  title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(email),
                  trailing: Switch(
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.red,
                    value: enabled,
                    onChanged: (_) => _toggleDoctorStatus(doctorId, enabled),
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
