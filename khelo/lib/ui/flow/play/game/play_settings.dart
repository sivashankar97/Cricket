import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

import '../../../../domain/play/play_flame_flag.dart';
import '../../../../domain/play/play_quality.dart';

/// Opens graphics / effects settings for the Play arena.
class PlayQualityButton extends ConsumerWidget {
  const PlayQualityButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: context.l10n.play_quality_title,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 40, height: 40),
      padding: EdgeInsets.zero,
      icon: Icon(Icons.high_quality_rounded,
          color: IconTheme.of(context).color ?? textPrimaryDarkColor),
      onPressed: () => showPlayQualitySheet(context, ref),
    );
  }
}

Future<void> showPlayQualitySheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: brandNavyCardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _PlayQualitySheet(),
  );
}

class _PlayQualitySheet extends ConsumerWidget {
  const _PlayQualitySheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pref = ref.watch(playQualityPrefPod);
    final effects = ref.watch(playEffectsOnPod);
    final resolved = ref.watch(playQualityProvider);
    final l10n = context.l10n;

    Widget option(String value, String label) {
      final selected = pref == value || (value == 'auto' && pref.isEmpty);
      return ListTile(
        dense: true,
        title: Text(
          label,
          style: AppTextStyle.subtitle2.copyWith(color: textPrimaryDarkColor),
        ),
        trailing: selected
            ? const Icon(Icons.check_rounded, color: positiveGreenColor)
            : null,
        onTap: () {
          ref.read(playQualityPrefPod.notifier).state = value;
        },
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 12, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                l10n.play_quality_title,
                style: AppTextStyle.header4.copyWith(
                  color: textPrimaryDarkColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Current: ${resolved.name}',
                style: AppTextStyle.caption
                    .copyWith(color: textSecondaryDarkColor),
              ),
            ),
            option('auto', l10n.play_quality_auto),
            option(PlayQuality.low.prefValue, l10n.play_quality_low),
            option(PlayQuality.medium.prefValue, l10n.play_quality_medium),
            option(PlayQuality.high.prefValue, l10n.play_quality_high),
            const Divider(color: Colors.white12),
            SwitchListTile.adaptive(
              value: effects,
              activeTrackColor: positiveGreenColor,
              title: Text(
                effects ? l10n.play_effects_on : l10n.play_effects_off,
                style:
                    AppTextStyle.subtitle2.copyWith(color: textPrimaryDarkColor),
              ),
              onChanged: (v) =>
                  ref.read(playEffectsOnPod.notifier).state = v,
            ),
            const Divider(color: Colors.white12),
            SwitchListTile.adaptive(
              value: ref.watch(playFlameSpikePod),
              activeTrackColor: positiveGreenColor,
              title: Text(
                'Flame experiment (Quick Play)',
                style:
                    AppTextStyle.subtitle2.copyWith(color: textPrimaryDarkColor),
              ),
              subtitle: Text(
                'Off = classic CustomPaint arena',
                style: AppTextStyle.caption
                    .copyWith(color: textSecondaryDarkColor),
              ),
              onChanged: (v) =>
                  ref.read(playFlameSpikePod.notifier).state = v,
            ),
          ],
        ),
      ),
    );
  }
}
