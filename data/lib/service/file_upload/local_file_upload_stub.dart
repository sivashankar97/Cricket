import 'dart:typed_data';

import 'package:http/http.dart' as http;

Future<Uint8List> readLocalFileBytes(String path) async {
  final response = await http.get(Uri.parse(path));
  if (response.statusCode >= 400 || response.bodyBytes.isEmpty) {
    throw Exception("uploadProfileImage: file doesn't exist.");
  }
  return response.bodyBytes;
}
