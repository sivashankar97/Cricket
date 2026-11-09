import 'package:audioplayers/audioplayers.dart';
import 'package:data/storage/provider/preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/theme/colors.dart';

import '../../../../domain/play/cricket_game.dart';

/// Effects in `assets/sounds/` (made by `scripts/make_play_sounds.py`).
enum PlaySound {
  batHit('bat_hit'),
  crowdCheer('crowd_cheer'),
  crowdRoar('crowd_roar'),
  wicket('wicket'),
  coin('coin'),
  countdown('countdown'),
  go('go'),
  win('win'),
  lose('lose');

  final String file;

  const PlaySound(this.file);
}

final playSoundOnPod = createPrefProvider<bool>(
  prefKey: 'play_sound_on',
  defaultValue: true,
);

final playSoundsProvider = Provider<PlaySounds>((ref) {
  final sounds = PlaySounds(() => ref.read(playSoundOnPod));
  ref.onDispose(sounds.dispose);
  return sounds;
});

/// Plays short effects; silent when muted. Failures (e.g. the browser
/// blocking audio before the first tap) are ignored: sound is a bonus.
class PlaySounds {
  PlaySounds(this._isOn);

  /// For tests and previews: never touches the audio plugin.
  PlaySounds.silent() : _isOn = (() => false);

  final bool Function() _isOn;
  final Map<PlaySound, AudioPlayer> _players = {};

  void play(PlaySound sound, {double volume = 1}) {
    if (!_isOn()) return;
    try {
      final player = _players.putIfAbsent(sound, AudioPlayer.new);
      player
          .stop()
          .then((_) => player.play(
                AssetSource('sounds/${sound.file}.wav'),
                volume: volume,
              ))
          .catchError((Object error) {
        debugPrint('PlaySounds: ${sound.file} failed: $error');
      });
    } catch (error) {
      debugPrint('PlaySounds: ${sound.file} failed: $error');
    }
  }

  /// Bat, crowd or stumps for a played ball.
  void shot(ShotResult result, {required bool swung}) {
    switch (result) {
      case ShotResult.six:
        play(PlaySound.batHit);
        play(PlaySound.crowdRoar, volume: 0.7);
      case ShotResult.four:
        play(PlaySound.batHit);
        play(PlaySound.crowdCheer, volume: 0.6);
      case ShotResult.two || ShotResult.single:
        play(PlaySound.batHit, volume: 0.8);
      case ShotResult.out:
        play(PlaySound.wicket);
      case ShotResult.dot:
        if (swung) play(PlaySound.batHit, volume: 0.35);
    }
  }

  void dispose() {
    for (final player in _players.values) {
      player.dispose().catchError((Object _) {});
    }
    _players.clear();
  }
}

/// Speaker button that mutes or unmutes all Play effects.
class PlaySoundToggle extends ConsumerWidget {
  const PlaySoundToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOn = ref.watch(playSoundOnPod);
    return IconButton(
      tooltip: isOn ? context.l10n.play_sound_off : context.l10n.play_sound_on,
      icon: Icon(
        isOn ? Icons.volume_up_rounded : Icons.volume_off_rounded,
        color: textPrimaryDarkColor,
      ),
      onPressed: () => ref.read(playSoundOnPod.notifier).state = !isOn,
    );
  }
}
