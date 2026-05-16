import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageService {
  // ── Cloudinary config ────────────────────────────────────────────────────
  // Replace these two values with your own from cloudinary.com (free tier).
  static const String _cloudName = 'dqq14myg4';
  static const String _uploadPreset = 'lets_chat_upload';
  // ─────────────────────────────────────────────────────────────────────────

  Future<String?> uploadFile(File file, String folder) async {
    try {
      final uri = Uri.parse(
        'https://api.cloudinary.com/v1_1/$_cloudName/auto/upload',
      );

      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = _uploadPreset
        ..fields['folder'] = folder
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final json = jsonDecode(body) as Map<String, dynamic>;
        return json['secure_url'] as String?;
      } else {
        print('Cloudinary upload error: $body');
        return null;
      }
    } catch (e) {
      print('Error uploading file: $e');
      return null;
    }
  }

  // Cloudinary deletion requires an API signature (server-side).
  // For client apps, simply orphan the old URL — Cloudinary's free tier
  // has no storage pressure at this scale.
  Future<void> deleteFile(String url) async {}
}
