import 'package:flutter/material.dart';
import 'social_service.dart';

class SocialPostPage extends StatelessWidget {
  /// Local asset image for the post (from your images/ folder)
  final String imageAssetPath;

  /// Text that will appear under the image AND be sent to backend (EN/AR handled below)
  final String baseText;

  const SocialPostPage({
    super.key,
    this.imageAssetPath = 'images/w2.png',
    this.baseText =
    'I am using the Heal pregnancy app to support and advise women '
        'for a healthy, safe pregnancy journey 💜.',
  });

  bool _isArabic(BuildContext context) =>
      Localizations.localeOf(context).languageCode.toLowerCase().startsWith('ar');

  String _t(BuildContext context, String en, String ar) =>
      _isArabic(context) ? ar : en;

  String _postText(BuildContext context) {
    // If you want baseText to always be the English provided text, keep it as is.
    // But since you asked "translate same as main.dart", we show AR text automatically.
    if (_isArabic(context)) {
      return 'أستخدم تطبيق Heal للحمل لدعم وإرشاد النساء '
          'من أجل رحلة حمل صحية وآمنة 💜.';
    }
    return baseText;
  }

  Future<void> _post(
      BuildContext context, {
        required List<String> platforms,
        required String friendlyNameEn,
        required String friendlyNameAr,
      }) async {
    final friendlyName = _t(context, friendlyNameEn, friendlyNameAr);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_t(context, 'Posting to $friendlyName...', 'جاري النشر على $friendlyName...'))),
    );

    // Backend still expects some image URL string.
    const dummyImageUrl = 'https://example.com/heal-pregnancy-image.png';

    final ok = await SocialService.postToSocial(
      text: _postText(context),
      imageUrl: dummyImageUrl,
      platforms: platforms,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? _t(
            context,
            'Successfully sent to $friendlyName (backend).',
            'تم الإرسال بنجاح إلى $friendlyName (الخادم).',
          )
              : _t(
            context,
            'Failed to post to $friendlyName.',
            'فشل النشر إلى $friendlyName.',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = _isArabic(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_t(context, 'Social Media Post', 'منشور وسائل التواصل')),
        backgroundColor: Colors.purple,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFFF0F7), Color(0xFFEAD7FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Post preview card (asset image + text)
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(20),
                          topRight: Radius.circular(20),
                        ),
                        child: Image.asset(
                          imageAssetPath,
                          height: 200,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          _postText(context),
                          textDirection:
                          isArabic ? TextDirection.rtl : TextDirection.ltr,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF444444),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Text(
                  _t(
                    context,
                    'Choose where to post automatically:',
                    'اختاري أين يتم النشر تلقائياً:',
                  ),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A2BE2),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                Expanded(
                  child: Column(
                    children: [
                      // LinkedIn button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0A66C2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => _post(
                            context,
                            platforms: ['linkedin'],
                            friendlyNameEn: 'LinkedIn',
                            friendlyNameAr: 'لينكدإن',
                          ),
                          child: Text(
                            _t(context, 'Post on LinkedIn', 'انشري على لينكدإن'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Instagram button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFE1306C),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => _post(
                            context,
                            platforms: ['instagram'],
                            friendlyNameEn: 'Instagram',
                            friendlyNameAr: 'إنستغرام',
                          ),
                          child: Text(
                            _t(context, 'Post on Instagram', 'انشري على إنستغرام'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Both button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF8A2BE2),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: () => _post(
                            context,
                            platforms: ['linkedin', 'instagram'],
                            friendlyNameEn: 'LinkedIn & Instagram',
                            friendlyNameAr: 'لينكدإن وإنستغرام',
                          ),
                          child: Text(
                            _t(
                              context,
                              'Post on Both (Auto)',
                              'انشري على الاثنين (تلقائي)',
                            ),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
