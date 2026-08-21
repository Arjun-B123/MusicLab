import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/config/analysis_config.dart';

class OmrRepository {
  /// Attempts to read the time signature off a sheet music file (photo or
  /// PDF). Returns null when nothing could be detected — the caller
  /// should treat this as "couldn't tell," not "no time signature," and
  /// let the user set it manually either way.
  Future<String?> detectTimeSignature(File file, String extension) async {
    final uri = Uri.parse('$omrServiceBaseUrl/detect-time-signature');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(
        await http.MultipartFile.fromPath(
          'sheet_music',
          file.path,
          filename: 'sheet_music.$extension',
        ),
      );

    final streamedResponse = await request.send().timeout(
      const Duration(seconds: 120),
    );
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    return decoded['timeSignature'] as String?;
  }
}
