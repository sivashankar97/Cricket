import 'dart:async';

import 'package:data/api/play/play_match.dart';
import 'package:data/service/play/play_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';

import '../game/play_arena.dart';
import '../play_opponent_sheet.dart';
import '../play_providers.dart';

/// App-wide: marks me online for Play and pops up live match requests sent
/// to me, wherever I am in the app.
class PlayInviteListener extends ConsumerStatefulWidget {
  final Widget child;

  const PlayInviteListener({super.key, required this.child});

  @override
  ConsumerState<PlayInviteListener> createState() => _PlayInviteListenerState();
}

class _PlayInviteListenerState extends ConsumerState<PlayInviteListener> {
  static const _presenceEvery = Duration(seconds: 60);

  Timer? _presence;
  final Set<String> _prompted = {};
  bool _dialogOpen = false;

  @override
  void initState() {
    super.initState();
    _presence = Timer.periodic(_presenceEvery, (_) => _markOnline());
    WidgetsBinding.instance.addPostFrameCallback((_) => _markOnline());
  }

  @override
  void dispose() {
    _presence?.cancel();
    super.dispose();
  }

  void _markOnline() {
    final me = ref.read(playIdentityProvider);
    if (me == null || me.isGuest) return;
    ref
        .read(playServiceProvider)
        .updatePresence(userId: me.id, name: me.name, image: me.imageUrl);
  }

  void _onMatches(List<PlayMatch> matches) {
    final me = ref.read(playIdentityProvider)?.id;
    if (me == null || _dialogOpen) return;
    final now = DateTime.now();
    final incoming = matches
        .where((match) =>
            match.status == PlayMatchStatus.requested &&
            match.guest.id == me &&
            !match.isExpired(now) &&
            !_prompted.contains(match.id))
        .firstOrNull;
    if (incoming != null) _prompt(incoming);
  }

  Future<void> _prompt(PlayMatch match) async {
    _prompted.add(match.id);
    _dialogOpen = true;
    final accept = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: PlayerBadge(
          name: match.host.name,
          image: match.host.image,
          size: 56,
        ),
        title: Text(context.l10n.play_match_incoming_title(match.host.name)),
        content: Text(
          context.l10n
              .play_match_incoming_body(formatLabel(context, match.format)),
          textAlign: TextAlign.center,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.play_match_decline),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.play_match_accept),
          ),
        ],
      ),
    );
    _dialogOpen = false;
    if (!mounted || accept == null) return;
    final service = ref.read(playServiceProvider);
    try {
      if (accept) {
        if (await service.acceptMatch(match.id) && mounted) {
          AppRoute.playMatch(match.id).push(context);
        } else if (mounted) {
          showSnackBar(context, context.l10n.play_match_unavailable);
        }
      } else {
        await service.declineMatch(match.id);
      }
    } catch (error) {
      if (mounted) showErrorSnackBar(context: context, error: error);
    }
    final latest = ref.read(playMatchesProvider).valueOrNull;
    if (latest != null && mounted) _onMatches(latest);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(playMatchesProvider, (_, next) {
      final matches = next.valueOrNull;
      if (matches != null) _onMatches(matches);
    });
    ref.listen(playIdentityProvider, (_, __) => _markOnline());
    return widget.child;
  }
}
