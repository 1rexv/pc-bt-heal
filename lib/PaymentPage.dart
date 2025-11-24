import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'BookedAppointmentsPage.dart';

class PaymentPage extends StatefulWidget {
  final String doctorName;
  final String appointmentDate;
  final double amount;
  final String? appointmentKey;

  const PaymentPage({
    super.key,
    required this.doctorName,
    required this.appointmentDate,
    required this.amount,
    this.appointmentKey,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController cardNumberController = TextEditingController();
  final TextEditingController expiryController = TextEditingController();
  final TextEditingController cvvController = TextEditingController();

  bool _isProcessing = false;

  bool _isExpiryValid(String value) {
    if (!value.contains('/') || value.length != 5) return false;

    final parts = value.split('/');
    final month = int.tryParse(parts[0]);
    final year = int.tryParse(parts[1]);

    if (month == null || year == null) return false;
    if (month < 1 || month > 12) return false;

    final now = DateTime.now();
    final currentMonth = now.month;
    final currentYearTwoDigits = now.year % 100;

    // Check if card year is in the past
    if (year < currentYearTwoDigits) return false;

    // Same year but old month
    if (year == currentYearTwoDigits && month < currentMonth) return false;

    return true;
  }

  Future<void> _processPayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 2));

      if (widget.appointmentKey != null && widget.appointmentKey!.isNotEmpty) {
        final DatabaseReference appointmentRef = FirebaseDatabase.instance
            .ref("appointments")
            .child(widget.appointmentKey!);

        await appointmentRef.update({
          'paid': true,
        });
      }

      setState(() => _isProcessing = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Payment Successful! 🎉"),
          content: const Text("Your payment has been completed successfully."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const BookedAppointmentsPage()),
                );
              },
              child: const Text("OK", style: TextStyle(color: Colors.purple)),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isProcessing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error processing payment: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
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
                padding: const EdgeInsets.all(20),
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
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text("Paying for: ${widget.doctorName}",
                          style: const TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text("Date: ${widget.appointmentDate}",
                          style: const TextStyle(fontSize: 16)),
                      const SizedBox(height: 8),
                      Text(
                        "Amount: OMR ${widget.amount.toStringAsFixed(2)}",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 24),

                      TextFormField(
                        controller: cardNumberController,
                        decoration: const InputDecoration(
                          labelText: "Card Number",
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.credit_card),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                        value == null || value.length != 16
                            ? "Enter valid 16-digit card number"
                            : null,
                      ),
                      const SizedBox(height: 16),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: expiryController,
                              decoration: const InputDecoration(
                                labelText: "Expiry (MM/YY)",
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return "Enter expiry date";
                                }
                                if (!_isExpiryValid(value)) {
                                  return "Card is expired or invalid";
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextFormField(
                              controller: cvvController,
                              decoration: const InputDecoration(
                                labelText: "CVV",
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              obscureText: true,
                              validator: (value) =>
                              value == null || value.length != 3
                                  ? "Enter valid 3-digit CVV"
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _isProcessing ? null : _processPayment,
                        child: _isProcessing
                            ? const CircularProgressIndicator(
                          color: Colors.white,
                        )
                            : const Text("Pay Now",
                            style: TextStyle(
                                color: Colors.white, fontSize: 16)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
