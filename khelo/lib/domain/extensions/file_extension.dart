import 'package:image_picker/image_picker.dart';

Future<bool> isFileUnderMaxSize(String path) async {
  const maxAllowedSizeInBytes = 25 * 1024 * 1024;
  final sizeInBytes = await XFile(path).length();
  return sizeInBytes <= maxAllowedSizeInBytes;
}
