import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  const ContactUsPage({super.key});

  static final Uri _instagramUri =
  Uri.parse('https://www.instagram.com/omanimoh/?hl=ar');
  static final Uri _linkedInUri =
  Uri.parse('https://www.linkedin.com/in/reem-alrawahi-35758b35a');

  Future<void> _openExternal(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link')),
        );
      }
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the link')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple;

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: const Text('Module 3 • Social Media', style: TextStyle(color: Colors.white)),
        backgroundColor: purple,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Intro
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
            ),
            child: Row(
              children: [
                Icon(Icons.share, color: purple),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Stay connected with HealthApp across our official channels.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // M3F1 — Instagram
          _buildContactCard(
            context: context,
            purple: purple,
            featureCode: 'M3F1',
            icon: Icons.camera_alt,
            platform: 'Instagram',
            handle: '@omanimoh',
            description:
            'Health tips, doctor Q&As, patient testimonials, and highlights of our app features.',
            onOpen: () => _openExternal(context, _instagramUri),
          ),
          const SizedBox(height: 16),

          // M3F2 — LinkedIn
          _buildContactCard(
            context: context,
            purple: purple,
            featureCode: 'M3F2',
            icon: Icons.business,
            platform: 'LinkedIn',
            handle: 'Reem Alrawahi',
            description:
            'Medical research updates, collaborations with healthcare professionals, and app innovations.',
            onOpen: () => _openExternal(context, _linkedInUri),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required Color purple,
    required String featureCode,
    required IconData icon,
    required String platform,
    required String handle,
    required String description,
    required VoidCallback onOpen,
  }) {
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row (icon + platform + feature code chip)
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: purple.withOpacity(0.12),
                    child: Icon(icon, color: purple),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      platform,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: purple.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: purple.withOpacity(0.25)),
                    ),
                    child: Text(
                      featureCode,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.purple.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Handle
              Text(
                handle,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              // Description
              Text(
                description,
                style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.35),
              ),

              const SizedBox(height: 12),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: purple,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.open_in_new, size: 18, color: Colors.white),
                    label: const Text('Open', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
