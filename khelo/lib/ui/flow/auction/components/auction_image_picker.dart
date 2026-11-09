import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';

/// Player photos are stored in Firestore, so they are shrunk while picking
/// (the web picker resizes on a canvas) to stay around 30–80 KB each.
const _photoSize = 480.0;
const _bannerWidth = 1200.0;
const _bannerHeight = 500.0;
const _quality = 70;

typedef PickedPhoto = ({String name, Uint8List bytes});

Future<Uint8List?> pickAuctionPhoto({bool banner = false}) async {
  final file = await ImagePicker().pickImage(
    source: ImageSource.gallery,
    maxWidth: banner ? _bannerWidth : _photoSize,
    maxHeight: banner ? _bannerHeight : _photoSize,
    imageQuality: _quality,
  );
  return file?.readAsBytes();
}

Future<List<PickedPhoto>> pickAuctionPhotos() async {
  final files = await ImagePicker().pickMultiImage(
    maxWidth: _photoSize,
    maxHeight: _photoSize,
    imageQuality: _quality,
  );
  return [
    for (final file in files) (name: file.name, bytes: await file.readAsBytes()),
  ];
}
