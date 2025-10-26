import 'package:flutter/material.dart';

class SendProblemPage extends StatefulWidget {
  const SendProblemPage({super.key});

  @override
  State<SendProblemPage> createState() => _SendProblemPageState();
}

class _SendProblemPageState extends State<SendProblemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController questionController = TextEditingController();

  void _submitQuestion() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Your medical question has been sent to the doctor.")),
      );

      // TODO: Send question to backend / notify doctor

      questionController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ask Your Doctor", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Write your medical question below. A doctor will respond shortly.",
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: questionController,
                maxLines: 6,
                decoration: const InputDecoration(
                  labelText: "Your Question",
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                validator: (value) => value == null || value.isEmpty ? "Please enter your question" : null,
              ),
              const SizedBox(height: 30),
              Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30), // Good curved shape
                    ),
                    elevation: 4,
                  ),
                  onPressed: _submitQuestion,
                  child: const Text("Send Question", style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
