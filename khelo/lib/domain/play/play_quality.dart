import 'package:data/storage/provider/preferences_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Graphics / effects preset for the Play arena (2.5D CustomPaint).
enum PlayQuality {
  low,
  medium,
  high;

  String get prefValue => name;

  static PlayQuality fromPref(String? value) => PlayQuality.values.firstWhere(
        (q) => q.name == value,
        orElse: () => PlayQuality.medium,
      );

  /// Crowd dots drawn (of the precomputed 320).
  int get crowdCount => switch (this) {
        PlayQuality.low => 80,
        PlayQuality.medium => 180,
        PlayQuality.high => 320,
      };

  bool get showFloodlightBeams => this != PlayQuality.low;

  bool get showCelebrateFlashes => this == PlayQuality.high;

  bool get showBallShadow => this != PlayQuality.low;

  bool get haptics => this != PlayQuality.low;
}

/// User override; empty / null means use [playQualityAutoProvider].
final playQualityPrefPod = createPrefProvider<String>(
  prefKey: 'play_quality',
  defaultValue: 'auto',
);

final playEffectsOnPod = createPrefProvider<bool>(
  prefKey: 'play_effects_on',
  defaultValue: true,
);

/// Cheap auto pick from platform + device pixel ratio (not model strings).
PlayQuality detectPlayQuality() {
  final views = PlatformDispatcher.instance.views;
  if (views.isEmpty) return PlayQuality.medium;
  final dpr = views.first.devicePixelRatio;
  final shortest = views.first.physicalSize.shortestSide / dpr;
  if (kIsWeb) {
    return dpr >= 2 && shortest >= 700 ? PlayQuality.high : PlayQuality.medium;
  }
  if (shortest < 360 || dpr < 2) return PlayQuality.low;
  if (shortest >= 600 && dpr >= 2.5) return PlayQuality.high;
  return PlayQuality.medium;
}

final playQualityProvider = Provider<PlayQuality>((ref) {
  final pref = ref.watch(playQualityPrefPod);
  if (pref == 'auto' || pref.isEmpty) return detectPlayQuality();
  return PlayQuality.fromPref(pref);
});
