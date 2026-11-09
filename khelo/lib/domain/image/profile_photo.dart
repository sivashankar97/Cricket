import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Profile photos are saved inside the user's Firestore doc as a small JPEG
/// data URL, because the old file storage (Supabase) is offline.
class ProfilePhoto {
  static const size = 256;
  static const _quality = 75;
  static const _prefix = 'data:image/';

  static bool isInline(String? url) => url != null && url.startsWith(_prefix);

  /// [url] when it's a short link that can be copied into other docs (Play
  /// games and matches); null for inline photos, which are 10–20 KB each.
  static String? shareable(String? url) => isInline(url) ? null : url;

  /// Crops to a centred square, shrinks to [size] px and encodes as JPEG
  /// (about 10–20 KB). Returns null when the bytes aren't an image.
  static Future<String?> encode(Uint8List bytes) => compute(_encode, bytes);

  static String? _encode(Uint8List bytes) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;
    final square = img.copyResizeCropSquare(
      img.bakeOrientation(decoded),
      size: size,
      interpolation: img.Interpolation.average,
    );
    final jpeg = img.encodeJpg(square, quality: _quality);
    return 'data:image/jpeg;base64,${base64Encode(jpeg)}';
  }

  static final _decoded = <String, Uint8List>{};

  /// Bytes of an inline photo; the same instance is returned for the same
  /// URL so Flutter's image cache can reuse the decoded picture.
  static Uint8List? bytesOf(String url) {
    if (!isInline(url)) return null;
    final cached = _decoded[url];
    if (cached != null) return cached;
    final comma = url.indexOf(',');
    if (comma < 0) return null;
    try {
      final bytes = base64Decode(url.substring(comma + 1));
      if (_decoded.length > 200) _decoded.remove(_decoded.keys.first);
      return _decoded[url] = bytes;
    } on FormatException {
      return null;
    }
  }
}
