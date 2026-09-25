import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/cloudinary_config.dart';

class CloudinaryService {
  static final CloudinaryService instance = CloudinaryService._();
  CloudinaryService._();

  /// Uploads [file] to Cloudinary using the unsigned preset defined in
  /// [CloudinaryConfig]. Returns the resulting `secure_url` on success,
  /// or throws an [Exception] with a clear message on failure.
  Future<String> uploadImage(XFile file) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse(CloudinaryConfig.uploadUrl),
    );
    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;

    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ),
    );

    final streamed = await request.send();
    final body = await streamed.stream.bytesToString();

    if (streamed.statusCode != 200) {
      throw Exception(
          'Cloudinary upload failed (${streamed.statusCode}): $body');
    }

    final json = jsonDecode(body) as Map<String, dynamic>;
    final url = json['secure_url'] as String?;
    if (url == null || url.isEmpty) {
      throw Exception('Cloudinary returned no secure_url. Response: $body');
    }
    return url;
  }
}
