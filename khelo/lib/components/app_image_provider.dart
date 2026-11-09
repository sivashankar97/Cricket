import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/widgets.dart';
import 'package:khelo/domain/image/profile_photo.dart';

/// Image for a stored URL: inline profile photos (`data:image/...`) are
/// decoded from memory, everything else is fetched and cached.
ImageProvider appImageProvider(String url) {
  final bytes = ProfilePhoto.bytesOf(url);
  if (bytes != null) return MemoryImage(bytes);
  return CachedNetworkImageProvider(url);
}
