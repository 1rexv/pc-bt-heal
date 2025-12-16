import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class SocialService {
  // Decide base URL depending on platform
  static String get _baseUrl {
    if (Platform.isAndroid) {
      // ANDROID EMULATOR
      return 'http://10.0.2.2:5000';
    } else if (Platform.isIOS) {
      // iOS SIMULATOR
      return 'http://localhost:5000';
    } else {
      // If you run on a REAL DEVICE (Android or iOS),
      // put your laptop IP here, example:
      // return 'http://192.168.1.7:5000';
      return 'http://10.0.2.2:5000';
    }
  }

  static Future<bool> postToSocial({
    required String text,
    required String imageUrl,
    required List<String> platforms,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/api/social/post');
      print('➡️ POST to $uri');

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'imageUrl': imageUrl,
          'postTo': platforms,
        }),
      );

      print('⬅️ status: ${response.statusCode}');
      print('⬅️ body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('❌ Exception calling backend: $e');
      return false;
    }
  }
}
