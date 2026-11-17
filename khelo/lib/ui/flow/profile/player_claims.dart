import 'package:data/api/user/player_claim.dart';
import 'package:data/api/user/user_models.dart';
import 'package:data/service/user/player_link_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/grouped_list.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/flow/settings/edit_profile/profile_completion.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/button/secondary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

/// Pending "that added player is me" requests the signed-in organizer must
/// answer. Empty when the rules or network refuse.
final playerClaimRequestsProvider =
    StreamProvider.autoDispose<List<PlayerClaim>>((ref) {
  final userId = ref.watch(currentUserPod.select((u) => u?.id));
  if (userId == null) return Stream.value(const []);
  return ref
      .watch(playerLinkServiceProvider)
      .streamRequestsForOrganizer(userId)
      .handleError((_) => const <PlayerClaim>[]);
});

/// The signed-in user's own link requests (pending, approved or declined).
final myPlayerClaimsProvider =
    StreamProvider.autoDispose<List<PlayerClaim>>((ref) {
  final userId = ref.watch(currentUserPod.select((u) => u?.id));
  if (userId == null) return Stream.value(const []);
  return ref
      .watch(playerLinkServiceProvider)
      .streamMyClaims(userId)
      .handleError((_) => const <PlayerClaim>[]);
});

/// Asks once per number whether an organizer-added player with the user's
/// mobile number is them.
class PlayerClaimListener extends ConsumerStatefulWidget {
  final Widget child;

  const PlayerClaimListener({super.key, required this.child});

  @override
  ConsumerState<PlayerClaimListener> createState() =>
      _PlayerClaimListenerState();
}

class _PlayerClaimListenerState extends ConsumerState<PlayerClaimListener> {
  final _checked = <String>{};

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      currentUserPhoneProvider,
      (_, next) => _check(next.valueOrNull),
      fireImmediately: true,
    );
  }

  Future<void> _check(String? phone) async {
    final user = ref.read(currentUserPod);
    if (user == null || phone == null || phone.isEmpty) return;
    if (!_checked.add('${user.id}|$phone')) return;
    try {
      final player = await ref
          .read(playerLinkServiceProvider)
          .findClaimable(userId: user.id, e164: phone);
      if (player == null || !mounted) return;
      await PlayerClaimSheet.show(context,
          player: player, user: user, e164: phone);
    } catch (e) {
      debugPrint('PlayerClaimListener: error while checking number -> $e');
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class PlayerClaimSheet extends ConsumerStatefulWidget {
  final ClaimablePlayer player;
  final UserModel user;
  final String e164;

  const PlayerClaimSheet({
    super.key,
    required this.player,
    required this.user,
    required this.e164,
  });

  static Future<void> show(
    BuildContext context, {
    required ClaimablePlayer player,
    required UserModel user,
    required String e164,
  }) {
    return showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => PlayerClaimSheet(player: player, user: user, e164: e164),
    );
  }

  @override
  ConsumerState<PlayerClaimSheet> createState() => _PlayerClaimSheetState();
}

class _PlayerClaimSheetState extends ConsumerState<PlayerClaimSheet> {
  bool? _sending;
  List<String>? _teamNames;
  List<String>? _recentMatches;
  bool _loadingDetails = true;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      final service = ref.read(playerLinkServiceProvider);
      final teams = await service.getPlayerTeamNames(widget.player.playerId);
      final matches =
          await service.getPlayerRecentMatches(widget.player.playerId);
      if (mounted) {
        setState(() {
          _teamNames = teams;
          _recentMatches = matches;
          _loadingDetails = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loadingDetails = false);
      }
    }
  }

  Future<void> _confirmMerge() async {
    setState(() => _sending = true);
    final messenger = ScaffoldMessenger.of(context);
    final successMessage = context.l10n.player_claim_merged_success;
    try {
      await ref.read(playerLinkServiceProvider).claimAndMerge(
            player: widget.player,
            claimant: widget.user,
            e164: widget.e164,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(SnackBar(
        content: Text(successMessage),
        backgroundColor: positiveGreenColor,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = null);
      showErrorSnackBar(context: context, error: e);
    }
  }

  Future<void> _dismiss() async {
    setState(() => _sending = false);
    try {
      await ref.read(playerLinkServiceProvider).answerClaim(
            player: widget.player,
            claimant: widget.user,
            e164: widget.e164,
            isMe: false,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = null);
      showErrorSnackBar(context: context, error: e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final player = widget.player;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: brandRedColor,
              ),
              child: ImageAvatar(
                size: 72,
                imageUrl: player.photoUrl,
                initial: player.playerName.isEmpty
                    ? '?'
                    : player.playerName[0].toUpperCase(),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.player_claim_title,
              style: AppTextStyle.header3.copyWith(
                color: cs.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              context.l10n.player_claim_body(
                player.playerName,
                player.teams,
                player.matches,
              ),
              textAlign: TextAlign.center,
              style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.containerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.shield_fill,
                          size: 16, color: cs.primary,),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.player_claim_teams_title,
                        style: AppTextStyle.subtitle2.copyWith(
                          color: cs.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _loadingDetails
                        ? context.l10n.player_claim_loading_details
                        : (_teamNames != null && _teamNames!.isNotEmpty
                            ? _teamNames!.join(', ')
                            : '${player.teams} ${context.l10n.player_claim_teams_title.toLowerCase()}'),
                    style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(CupertinoIcons.sportscourt_fill,
                          size: 16, color: cs.primary,),
                      const SizedBox(width: 8),
                      Text(
                        '${context.l10n.player_claim_matches_title} (${player.matches})',
                        style: AppTextStyle.subtitle2.copyWith(
                          color: cs.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  if (!_loadingDetails &&
                      _recentMatches != null &&
                      _recentMatches!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _recentMatches!.take(3).join('\n'),
                      style: AppTextStyle.caption
                          .copyWith(color: cs.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              context.l10n.player_claim_confirm_merge,
              progress: _sending == true,
              enabled: _sending == null,
              background: brandRedColor,
              onPressed: _confirmMerge,
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              context.l10n.player_claim_no,
              enabled: _sending == null,
              onPressed: _dismiss,
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile section: displays any existing unclaimed player profile found for
/// the user's mobile number, allowing them to review and merge it directly.
class PlayerLinksSection extends ConsumerStatefulWidget {
  const PlayerLinksSection({super.key});

  @override
  ConsumerState<PlayerLinksSection> createState() => _PlayerLinksSectionState();
}

class _PlayerLinksSectionState extends ConsumerState<PlayerLinksSection> {
  ClaimablePlayer? _unclaimedPlayer;

  @override
  void initState() {
    super.initState();
    _checkClaimable();
  }

  Future<void> _checkClaimable() async {
    final user = ref.read(currentUserPod);
    final phone = ref.read(currentUserPhoneProvider).valueOrNull;
    if (user == null || phone == null || phone.isEmpty) return;
    try {
      final player = await ref
          .read(playerLinkServiceProvider)
          .findClaimable(userId: user.id, e164: phone);
      if (mounted) {
        setState(() {
          _unclaimedPlayer = player;
        });
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    ref.listenManual(
      currentUserPhoneProvider,
      (_, next) => _checkClaimable(),
    );

    final player = _unclaimedPlayer;
    if (player == null) return const SizedBox.shrink();

    final user = ref.watch(currentUserPod);
    final phone = ref.watch(currentUserPhoneProvider).valueOrNull;
    if (user == null || phone == null) return const SizedBox.shrink();

    final cs = context.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: brandRedColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconTile(CupertinoIcons.link, brandRedColor),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.player_claim_unclaimed_title,
                      style: AppTextStyle.subtitle1.copyWith(
                        color: cs.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.player_claim_unclaimed_subtitle(
                        player.playerName,
                        player.teams,
                        player.matches,
                      ),
                      style: AppTextStyle.caption
                          .copyWith(color: cs.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            context.l10n.player_claim_check_and_merge,
            background: brandRedColor,
            onPressed: () async {
              await PlayerClaimSheet.show(
                context,
                player: player,
                user: user,
                e164: phone,
              );
              _checkClaimable();
            },
          ),
        ],
      ),
    );
  }
}
