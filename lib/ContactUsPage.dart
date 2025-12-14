import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsPage extends StatelessWidget {
  final String currentLanguage; // "ar" or "en"

  const ContactUsPage({super.key, required this.currentLanguage});

  static final Uri _instagramUri =
  Uri.parse('https://www.instagram.com/omanimoh/?hl=ar');

  static final Uri _linkedInUri =
  Uri.parse('https://www.linkedin.com/in/reem-alrawahi-35758b35a');

  Future<void> _openExternal(BuildContext context, Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) {
        _showSnack(context, currentLanguage == "ar"
            ? 'تعذر فتح الرابط'
            : 'Could not open the link');
      }
    } catch (_) {
      _showSnack(context, currentLanguage == "ar"
          ? 'تعذر فتح الرابط'
          : 'Could not open the link');
    }
  }

  void _showSnack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final purple = Colors.purple;

    return Scaffold(
      backgroundColor: Colors.purple.shade50,
      appBar: AppBar(
        title: Text(
          currentLanguage == "ar" ? 'روابط التواصل' : 'Social Media',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: purple,
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SizedBox(height: 16),

          // Instagram
          _buildContactCard(
            context: context,
            purple: purple,
            icon: Icons.camera_alt,
            platform: currentLanguage == "ar" ? 'إنستغرام' : 'Instagram',
            handle: '@omanimoh',
            description: currentLanguage == "ar"
                ? 'نصائح صحية، أسئلة وأجوبة مع الأطباء، وآخر تحديثات التطبيق.'
                : 'Health tips, doctor Q&As, patient stories, and app highlights.',
            onOpen: () => _openExternal(context, _instagramUri),
            buttonText: currentLanguage == "ar" ? 'فتح' : 'Open',
          ),
          const SizedBox(height: 16),

          // LinkedIn
          _buildContactCard(
            context: context,
            purple: purple,
            icon: Icons.business,
            platform: 'LinkedIn',
            handle: 'Reem Alrawahi',
            description: currentLanguage == "ar"
                ? 'أبحاث طبية، تعاونات مع مختصين، وتحديثات حول تطوير التطبيق.'
                : 'Medical research updates, collaborations, and app innovations.',
            onOpen: () => _openExternal(context, _linkedInUri),
            buttonText: currentLanguage == "ar" ? 'فتح' : 'Open',
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard({
    required BuildContext context,
    required Color purple,
    required IconData icon,
    required String platform,
    required String handle,
    required String description,
    required VoidCallback onOpen,
    required String buttonText,
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
                ],
              ),

              const SizedBox(height: 8),

              Text(
                handle,
                style: const TextStyle(
                  fontSize: 15,
                  fontStyle: FontStyle.italic,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                description,
                style: const TextStyle(
                    fontSize: 14, color: Colors.black54, height: 1.35),
              ),

              const SizedBox(height: 12),

              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: onOpen,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: purple,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    icon: const Icon(Icons.open_in_new,
                        size: 18, color: Colors.white),
                    label: Text(buttonText),
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
