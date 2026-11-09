import 'dart:async';

import 'package:data/api/play/play_match.dart';
import 'package:data/service/user/user_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:khelo/domain/image/profile_photo.dart';

import '../../../domain/play/cricket_game.dart';
import 'play_providers.dart';

/// Picks who to send a live match request to: players online now, players
/// met before, or anyone found by name.
Future<PlayMatchPlayer?> showPlayOpponentSheet(BuildContext context) =>
    showModalBottomSheet<PlayMatchPlayer>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _PlayOpponentSheet(),
    );

/// Asks for the match length; null when dismissed.
Future<MatchFormat?> showMatchFormatSheet(
  BuildContext context,
  PlayMatchPlayer opponent,
) =>
    showModalBottomSheet<MatchFormat>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _MatchFormatSheet(opponent: opponent),
    );

String formatName(BuildContext context, MatchFormat format) =>
    switch (format.overs) {
      1 => context.l10n.play_format_quick,
      5 => context.l10n.play_format_long,
      _ => context.l10n.play_format_classic,
    };

String formatLabel(BuildContext context, MatchFormat format) =>
    context.l10n.play_format_detail(format.overs, format.wickets);

class _PlayOpponentSheet extends ConsumerStatefulWidget {
  const _PlayOpponentSheet();

  @override
  ConsumerState<_PlayOpponentSheet> createState() => _PlayOpponentSheetState();
}

class _PlayOpponentSheetState extends ConsumerState<_PlayOpponentSheet> {
  Timer? _debounce;
  bool _loading = false;
  List<PlayMatchPlayer> _found = [];
  String _query = '';

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () => _search(value));
  }

  Future<void> _search(String value) async {
    final query = value.trim();
    setState(() {
      _query = query;
      _loading = query.isNotEmpty;
      if (query.isEmpty) _found = [];
    });
    if (query.isEmpty) return;
    try {
      final me = ref.read(playIdentityProvider)?.id;
      final users = await ref.read(userServiceProvider).searchUser(query);
      if (!mounted || query != _query) return;
      setState(() {
        // Only real accounts can sign in and answer the request.
        _found = users
            .where((user) =>
                user.id != me && (user.email != null || user.phone != null))
            .map((user) => PlayMatchPlayer(
                  id: user.id,
                  name: user.name ?? '',
                  image: ProfilePhoto.shareable(user.profile_img_url),
                ))
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// Opponents from earlier live matches and challenges, most recent first.
  List<PlayMatchPlayer> _playedBefore(String me) {
    final seen = <String>{};
    final players = <PlayMatchPlayer>[];
    void add(PlayMatchPlayer player) {
      if (player.id != me && seen.add(player.id)) players.add(player);
    }

    for (final match in ref.watch(playMatchesProvider).valueOrNull ?? []) {
      add(match.otherThan(me));
    }
    for (final challenge
        in ref.watch(playChallengesProvider).valueOrNull ?? []) {
      challenge.creatorId == me
          ? add(PlayMatchPlayer(
              id: challenge.opponentId, name: challenge.opponentName))
          : add(PlayMatchPlayer(
              id: challenge.creatorId, name: challenge.creatorName));
    }
    return players.take(10).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: cs.containerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
              child: Text(
                context.l10n.play_select_opponent_title,
                style: AppTextStyle.header4.copyWith(
                  color: cs.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              context.l10n.play_challenge_live_hint,
              style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: CupertinoSearchTextField(
                placeholder: context.l10n.play_select_opponent_hint,
                style: AppTextStyle.body1.copyWith(color: cs.textPrimary),
                onChanged: _onChanged,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _query.isEmpty ? _suggestions(context) : _results(context),
            ),
          ],
        ),
      ),
    );
  }

  Set<String> _onlineIds(DateTime now) => {
        for (final presence in ref.watch(playOnlineProvider).valueOrNull ?? [])
          if (presence.isOnline(now)) presence.userId,
      };

  Widget _suggestions(BuildContext context) {
    final cs = context.colorScheme;
    final me = ref.watch(playIdentityProvider)?.id ?? '';
    final now = DateTime.now();
    final online = [
      for (final presence in ref.watch(playOnlineProvider).valueOrNull ?? [])
        if (presence.userId != me && presence.isOnline(now))
          PlayMatchPlayer(
            id: presence.userId,
            name: presence.name,
            image: presence.image,
          ),
    ];
    final onlineIds = online.map((player) => player.id).toSet();
    final before = _playedBefore(me)
        .where((player) => !onlineIds.contains(player.id))
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 24),
      children: [
        _section(context, context.l10n.play_online_now, live: true),
        if (online.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Text(
              context.l10n.play_select_opponent_none_online,
              style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
            ),
          )
        else
          ...online.map((player) => _tile(context, player, online: true)),
        if (before.isNotEmpty) ...[
          _section(context, context.l10n.play_recent_opponents),
          ...before.map((player) => _tile(context, player, online: false)),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            context.l10n.play_select_opponent_more,
            textAlign: TextAlign.center,
            style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
          ),
        ),
      ],
    );
  }

  Widget _results(BuildContext context) {
    final cs = context.colorScheme;
    if (_loading) return const Center(child: AppProgressIndicator());
    if (_found.isEmpty) {
      return Center(
        child: Text(
          context.l10n.play_select_opponent_empty,
          style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
        ),
      );
    }
    final onlineIds = _onlineIds(DateTime.now());
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        for (final player in _found)
          _tile(context, player, online: onlineIds.contains(player.id)),
      ],
    );
  }

  Widget _section(BuildContext context, String title, {bool live = false}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 6),
      child: Row(
        children: [
          if (live) ...[
            const _OnlineDot(),
            const SizedBox(width: 6),
          ],
          Text(
            title.toUpperCase(),
            style: AppTextStyle.caption.copyWith(
              color: context.colorScheme.textSecondary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    PlayMatchPlayer player, {
    required bool online,
  }) {
    final cs = context.colorScheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      leading: Stack(
        clipBehavior: Clip.none,
        children: [
          ImageAvatar(
            initial: player.name.isEmpty ? '?' : player.name[0].toUpperCase(),
            imageUrl: player.image,
            size: 40,
          ),
          if (online)
            const Positioned(right: -1, bottom: -1, child: _OnlineDot()),
        ],
      ),
      title: Text(
        player.name,
        style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
      ),
      subtitle: online
          ? Text(
              context.l10n.play_online_label,
              style: AppTextStyle.caption.copyWith(color: positiveGreenColor),
            )
          : null,
      trailing:
          Icon(CupertinoIcons.chevron_right, size: 16, color: cs.textDisabled),
      onTap: () => Navigator.of(context).pop(player),
    );
  }
}

class _OnlineDot extends StatelessWidget {
  const _OnlineDot();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 12,
      width: 12,
      decoration: BoxDecoration(
        color: positiveGreenColor,
        shape: BoxShape.circle,
        border: Border.all(color: context.colorScheme.surface, width: 2),
      ),
    );
  }
}

class _MatchFormatSheet extends StatefulWidget {
  final PlayMatchPlayer opponent;

  const _MatchFormatSheet({required this.opponent});

  @override
  State<_MatchFormatSheet> createState() => _MatchFormatSheetState();
}

class _MatchFormatSheetState extends State<_MatchFormatSheet> {
  MatchFormat _format = GameRules.format;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              height: 4,
              width: 36,
              decoration: BoxDecoration(
                color: cs.containerHigh,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              ImageAvatar(
                initial: widget.opponent.name.isEmpty
                    ? '?'
                    : widget.opponent.name[0].toUpperCase(),
                imageUrl: widget.opponent.image,
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.play_format_title,
                      style: AppTextStyle.header4.copyWith(
                        color: cs.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      context.l10n.play_game_vs(widget.opponent.name),
                      style: AppTextStyle.caption
                          .copyWith(color: cs.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.play_format_subtitle,
            style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
          ),
          const SizedBox(height: 14),
          for (final format in MatchFormat.options) _option(context, format),
          const SizedBox(height: 10),
          OnTapScale(
            onTap: () => Navigator.of(context).pop(_format),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: liveCardGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                context.l10n.play_send_request,
                style:
                    AppTextStyle.button.copyWith(color: textPrimaryDarkColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(BuildContext context, MatchFormat format) {
    final cs = context.colorScheme;
    final selected = format == _format;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: OnTapScale(
        onTap: () => setState(() => _format = format),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color:
                selected ? cs.primary.withValues(alpha: 0.10) : cs.containerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? cs.primary : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                switch (format.overs) {
                  1 => Icons.bolt_rounded,
                  5 => Icons.emoji_events_rounded,
                  _ => Icons.sports_cricket_rounded,
                },
                color: selected ? cs.primary : cs.textSecondary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatName(context, format),
                      style: AppTextStyle.subtitle2.copyWith(
                        color: cs.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      formatLabel(context, format),
                      style: AppTextStyle.caption
                          .copyWith(color: cs.textSecondary),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                color: selected ? cs.primary : cs.textDisabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
