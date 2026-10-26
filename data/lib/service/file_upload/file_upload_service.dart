import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../errors/app_error.dart';
import 'local_file_upload.dart';
import 'supabase_storage_config.dart';

final fileUploadServiceProvider = Provider(
  (ref) => FileUploadService(),
);

class FileUploadService {
  static final _publicPrefix =
      '/storage/v1/object/public/${SupabaseStorageConfig.bucket}/';

  Future<String> uploadProfileImage({
    required String filePath,
    required String uploadPath,
  }) async {
    try {
      final bytes = await readLocalFileBytes(filePath);
      final objectPath = _encodeObjectPath(uploadPath);
      final uri = Uri.parse(
        '${SupabaseStorageConfig.projectUrl}/storage/v1/object/${SupabaseStorageConfig.bucket}/$objectPath',
      );
      final response = await http.post(
        uri,
        headers: _headers(_contentType(bytes, filePath), upsert: true),
        body: bytes,
      );
      if (response.statusCode >= 300) {
        throw Exception('Image upload failed (${response.statusCode})');
      }
      final version = DateTime.now().millisecondsSinceEpoch;
      return '${SupabaseStorageConfig.projectUrl}/storage/v1/object/public/${SupabaseStorageConfig.bucket}/$objectPath?v=$version';
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Future<void> deleteUploadedImage(String imgUrl) async {
    try {
      final uri = Uri.parse(imgUrl);
      final markerIndex = uri.path.indexOf(_publicPrefix);
      if (markerIndex < 0) {
        throw Exception('Image url is not in app storage');
      }
      final objectPath = uri.path.substring(markerIndex + _publicPrefix.length);
      final deleteUri = Uri.parse(
        '${SupabaseStorageConfig.projectUrl}/storage/v1/object/${SupabaseStorageConfig.bucket}/${_encodeObjectPath(objectPath)}',
      );
      final response = await http.delete(deleteUri, headers: _headers(null));
      if (response.statusCode == 404 || response.statusCode < 300) {
        return;
      }
      throw Exception('Image delete failed (${response.statusCode})');
    } catch (error, stack) {
      throw AppError.fromError(error, stack);
    }
  }

  Map<String, String> _headers(String? contentType, {bool upsert = false}) {
    return {
      'apikey': SupabaseStorageConfig.anonKey,
      'Authorization': 'Bearer ${SupabaseStorageConfig.anonKey}',
      if (contentType != null) 'Content-Type': contentType,
      if (upsert) 'x-upsert': 'true',
    };
  }

  String _encodeObjectPath(String path) {
    return path
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .map(Uri.encodeComponent)
        .join('/');
  }

  String _contentType(Uint8List bytes, String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (bytes.length >= 8 &&
        bytes[0] == 0x89 &&
        bytes[1] == 0x50 &&
        bytes[2] == 0x4E &&
        bytes[3] == 0x47) {
      return 'image/png';
    }
    if (bytes.length >= 6 &&
        bytes[0] == 0x47 &&
        bytes[1] == 0x49 &&
        bytes[2] == 0x46) {
      return 'image/gif';
    }
    if (bytes.length >= 12 &&
        bytes[0] == 0x52 &&
        bytes[1] == 0x49 &&
        bytes[8] == 0x57 &&
        bytes[9] == 0x45) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }
}
