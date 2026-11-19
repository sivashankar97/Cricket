import 'package:data/storage/provider/preferences_provider.dart';

/// When true, Quick Play (`PlayMode.solo`) uses the Flame arena spike.
/// Daily, challenges and live matches stay on CustomPaint.
final playFlameSpikePod = createPrefProvider<bool>(
  prefKey: 'play_flame_spike_v2',
  defaultValue: true,
);
