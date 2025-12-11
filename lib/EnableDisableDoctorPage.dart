import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class EnableDisableDoctorPage extends StatefulWidget {
  const EnableDisableDoctorPage({super.key});

  @override
  State<EnableDisableDoctorPage> createState() => _EnableDisableDoctorPageState();
}

class _EnableDisableDoctorPageState extends State<EnableDisableDoctorPage> {
  final DatabaseReference doctorsRef = FirebaseDatabase.instance.ref("doctors");

  bool get _isArabic =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(String en, String ar) => _isArabic ? ar : en;

  /// Toggle enabled status in Firebase
  Future<void> _toggleDoctorStatus(String doctorId, bool currentStatus) async {
    try {
      await doctorsRef.child(doctorId).update({
        'enabled': !currentStatus,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus
                ? _t("✅ Doctor account enabled", "✅ تم تفعيل حساب الطبيب")
                : _t("🚫 Doctor account disabled", "🚫 تم تعطيل حساب الطبيب"),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t("❌ Failed to update status: $e", "❌ فشل تحديث الحالة: $e"))),
      );
    }
  }

  
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
    final isArabic = _isArabic;

    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _t('Enable / Disable Doctor Accounts', 'تفعيل / تعطيل حسابات الأطباء'),
            style: const TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.purple,
          centerTitle: true,
        ),
        body: StreamBuilder(
          stream: doctorsRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator(color: Colors.purple));
            }

            if (snapshot.hasError) {
              return Center(child: Text(_t('⚠️ Error loading doctors', '⚠️ خطأ في جلب الأطباء')));
            }

            if (!snapshot.hasData || (snapshot.data! as DatabaseEvent).snapshot.value == null) {
              return Center(child: Text(_t('No doctors found', 'لا يوجد أطباء')));
            }

            final doctorsMap = Map<String, dynamic>.from(
              (snapshot.data! as DatabaseEvent).snapshot.value as Map,
            );

            // ensure missing 'enabled' fields are set (fire-and-forget)
            _ensureEnabledField(doctorsMap);

            final doctors = doctorsMap.entries.toList();

            return ListView.builder(
              itemCount: doctors.length,
              itemBuilder: (context, index) {
                final doctorId = doctors[index].key;
                final doctorData = Map<String, dynamic>.from(doctors[index].value);

                final name = (doctorData["fullName"] ?? _t("Unknown Doctor", "طبيب غير معروف")).toString();
                final email = (doctorData["email"] ?? "-").toString();
                final profileImage = doctorData["profileImage"] as String?;
                final enabled = doctorData["enabled"] ?? true; 

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
                          ? Icon(Icons.person, color: Colors.purple)
                          : null,
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(email),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          enabled ? _t('Enabled', 'مفعل') : _t('Disabled', 'معطل'),
                          style: TextStyle(
                            color: enabled ? Colors.green.shade700 : Colors.red.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Switch(
                          activeColor: Colors.green,
                          inactiveThumbColor: Colors.red,
                          value: enabled,
                          onChanged: (_) => _toggleDoctorStatus(doctorId, enabled),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
