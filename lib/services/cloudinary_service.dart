import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/cloudinary_config.dart';

/// Result of a video upload.
class UploadedVideo {
  final String url;
  final String thumbnailUrl;
  final int durationSeconds;
  const UploadedVideo(this.url, this.thumbnailUrl, this.durationSeconds);
}

class CloudinaryService {
  static final CloudinaryService instance = CloudinaryService._();
  CloudinaryService._();

  /// Uploads [file] to Cloudinary using the unsigned preset defined in
  /// [CloudinaryConfig]. Returns the resulting `secure_url` on success,
  /// or throws an [Exception] with a clear message on failure.
  Future<String> uploadImage(XFile file) async {
    final json = await _upload(file, CloudinaryConfig.uploadUrl);
    return json['secure_url'] as String;
  }

  /// Uploads a short video clip through the video endpoint (same unsigned
  /// preset) and returns its URL plus a generated thumbnail.
  /// [onProgress] reports 0..1 as the file's bytes are sent.
  Future<UploadedVideo> uploadVideo(XFile file, {void Function(double)? onProgress}) async {
    final json = await _upload(file, CloudinaryConfig.videoUploadUrl, onProgress: onProgress);
    final publicId = json['public_id'] as String;
    // Thumbnail URL: the clip's own delivery path with the `so_1` (start
    // offset 1 s) transformation and a .jpg extension, so Cloudinary
    // serves the frame at 1 second as an image, e.g.
    // https://res.cloudinary.com/<cloud>/video/upload/so_1/<public_id>.jpg
    final thumbnail =
        'https://res.cloudinary.com/${CloudinaryConfig.cloudName}/video/upload/so_1/$publicId.jpg';
    final duration = (json['duration'] as num?)?.round() ?? 0;
    return UploadedVideo(json['secure_url'] as String, thumbnail, duration);
  }

  Future<Map<String, dynamic>> _upload(XFile file, String endpoint,
      {void Function(double)? onProgress}) async {
    final request = http.MultipartRequest('POST', Uri.parse(endpoint));
    request.fields['upload_preset'] = CloudinaryConfig.uploadPreset;

    final bytes = await file.readAsBytes();
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: file.name,
      ),
    );

    final http.StreamedResponse streamed;
    if (onProgress == null) {
      streamed = await request.send();
    } else {
      // Same multipart body, sent through a StreamedRequest so the bytes
      // can be counted on their way out for a progress bar.
      final total = request.contentLength;
      final counted = http.StreamedRequest('POST', request.url)
        ..headers.addAll(request.headers)
        ..contentLength = total;
      var sent = 0;
      request.finalize().listen(
        (chunk) {
          sent += chunk.length;
          if (total > 0) onProgress(sent / total);
          counted.sink.add(chunk);
        },
        onDone: counted.sink.close,
        onError: counted.sink.addError,
        cancelOnError: true,
      );
      streamed = await counted.send();
    }
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
    return json;
  }
}
