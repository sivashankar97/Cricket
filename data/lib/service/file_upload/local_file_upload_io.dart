import 'dart:io';
import 'dart:typed_data';

Future<Uint8List> readLocalFileBytes(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw Exception("uploadProfileImage: file doesn't exist.");
  }
  return file.readAsBytes();
}
