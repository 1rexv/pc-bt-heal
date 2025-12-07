import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:pc_bt_heal/PaymentPage.dart';

class BookedAppointmentsPage extends StatefulWidget {
  const BookedAppointmentsPage({super.key});

  @override
  State<BookedAppointmentsPage> createState() => _BookedAppointmentsPageState();
}

class _BookedAppointmentsPageState extends State<BookedAppointmentsPage> {
  final DatabaseReference _appointmentsRef =
  FirebaseDatabase.instance.ref("appointments");

  final String? currentUserEmail = FirebaseAuth.instance.currentUser?.email;

  void _cancelAppointment(String key, bool isPaid) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Appointment"),
        content: const Text("Are you sure you want to cancel this appointment?"),
        actions: [
          TextButton(
            child: const Text("No"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () async {
              await _appointmentsRef.child(key).remove();
              Navigator.pop(context); // close dialog

              // ✅ Simple message after cancel
              final message = isPaid
                  ? "Appointment canceled. Refund in 4–5 days."
                  : "Appointment canceled.";

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(message)),
              );
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "My Booked Appointments",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _appointmentsRef.onValue,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error loading data"));
          }
          if (!snapshot.hasData || snapshot.data?.snapshot.value == null) {
            return const Center(child: Text("No booked appointments"));
          }

          final data =
          Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);

          // 🔹 Filter only current patient’s appointments
          final appointments = data.entries.map((entry) {
            final appt = Map<String, dynamic>.from(entry.value);
            return {
              'key': entry.key,
              'doctorName': appt['doctorName'] ?? '',
              'patientEmail': appt['patientEmail'] ?? '',
              'date': appt['date'] ?? '',
              'time': appt['time'] ?? '',
              'location': appt['location'] ?? '',
              'paid': appt['paid'] ?? false,
              'status': appt['status'] ?? 'pending',
            };
          }).where((appt) => appt['patientEmail'] == currentUserEmail).toList();

          if (appointments.isEmpty) {
            return const Center(child: Text("No booked appointments found."));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const ClipRRect(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                  child: Image(
                    image: AssetImage('images/logo.png'),
                    height: 100,
                    width: 100,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      columns: const [
                        DataColumn(label: Text('Doctor')),
                        DataColumn(label: Text('Date')),
                        DataColumn(label: Text('Time')),
                        DataColumn(label: Text('Status')),
                        DataColumn(label: Text('Paid')),
                        DataColumn(label: Text('Actions')),
                      ],
                      rows: appointments.map((appt) {
                        final bool isPaid = appt['paid'] == true;

                        final showPayButton =
                            appt['status'] == 'accepted' &&
                                appt['date'] != '' &&
                                appt['time'] != '' &&
                                !isPaid;

                        return DataRow(
                          cells: [
                            DataCell(Text(appt['doctorName'])),
                            DataCell(
                              Text(
                                appt['date'].toString().isNotEmpty
                                    ? appt['date']
                                    : '-',
                              ),
                            ),
                            DataCell(
                              Text(
                                appt['time'].toString().isNotEmpty
                                    ? appt['time']
                                    : '-',
                              ),
                            ),
                            DataCell(
                              Text(
                                appt['status'].toString().toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: appt['status'] == 'accepted'
                                      ? Colors.green
                                      : (appt['status'] == 'pending'
                                      ? Colors.orange
                                      : Colors.red),
                                ),
                              ),
                            ),
                            DataCell(
                              Text(
                                isPaid ? "Yes" : "No",
                                style: TextStyle(
                                  color: isPaid ? Colors.green : Colors.red,
                                ),
                              ),
                            ),
                            DataCell(
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel,
                                      color: Colors.red,
                                    ),
                                    tooltip: "Cancel",
                                    onPressed: () => _cancelAppointment(
                                      appt['key'],
                                      isPaid,
                                    ),
                                  ),
                                  if (showPayButton)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.purple,
                                      ),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => PaymentPage(
                                              doctorName: appt['doctorName'],
                                              appointmentDate: appt['date'],
                                              amount: 6.00,
                                              appointmentKey: appt['key'],
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Text(
                                        "Pay",
                                        style: TextStyle(color: Colors.white),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
