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

  Future<void> _answer(bool isMe) async {
    setState(() => _sending = isMe);
    final messenger = ScaffoldMessenger.of(context);
    final message = context.l10n.player_claim_sent;
    try {
      await ref.read(playerLinkServiceProvider).answerClaim(
            player: widget.player,
            claimant: widget.user,
            e164: widget.e164,
            isMe: isMe,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      if (isMe) {
        messenger.showSnackBar(SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ));
      }
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
            const SizedBox(height: 24),
            PrimaryButton(
              context.l10n.player_claim_yes,
              progress: _sending == true,
              enabled: _sending == null,
              onPressed: () => _answer(true),
            ),
            const SizedBox(height: 10),
            SecondaryButton(
              context.l10n.player_claim_no,
              enabled: _sending == null,
              onPressed: () => _answer(false),
            ),
          ],
        ),
      ),
    );
  }
}

/// Profile section: requests to approve, and the user's own waiting or
/// declined requests. Hidden when there's nothing to show.
class PlayerLinksSection extends ConsumerStatefulWidget {
  const PlayerLinksSection({super.key});

  @override
  ConsumerState<PlayerLinksSection> createState() => _PlayerLinksSectionState();
}

class _PlayerLinksSectionState extends ConsumerState<PlayerLinksSection> {
  final _busy = <String>{};

  Future<void> _decide(PlayerClaim claim, {required bool approve}) async {
    setState(() => _busy.add(claim.id));
    final service = ref.read(playerLinkServiceProvider);
    try {
      if (approve) {
        await service.approveClaim(claim);
        if (mounted) {
          showSnackBar(
            context,
            context.l10n.player_claim_approved_toast(
              claim.playerName,
              claim.claimantName,
            ),
            length: SnackBarLength.long,
          );
        }
      } else {
        await service.declineClaim(claim);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context: context, error: e);
    } finally {
      if (mounted) setState(() => _busy.remove(claim.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final requests = ref.watch(playerClaimRequestsProvider).valueOrNull ?? [];
    final mine = (ref.watch(myPlayerClaimsProvider).valueOrNull ?? [])
        .where((c) => c.status != PlayerClaimStatus.approved)
        .toList();
    if (requests.isEmpty && mine.isEmpty) return const SizedBox.shrink();

    final cs = context.colorScheme;
    final rows = <Widget>[
      for (final claim in requests) _requestRow(context, claim),
      for (final claim in mine) _myClaimRow(context, claim),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionCaption(context.l10n.profile_section_player_links),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 0.5,
                    thickness: 0.5,
                    indent: 58,
                    color: cs.outline,
                  ),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _requestRow(BuildContext context, PlayerClaim claim) {
    final cs = context.colorScheme;
    final busy = _busy.contains(claim.id);
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const IconTile(CupertinoIcons.link, brandRedColor),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.player_claim_request_row(
                    claim.claimantName,
                    claim.playerName,
                  ),
                  style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  context.l10n.player_claim_request_hint,
                  style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
                ),
                const SizedBox(height: 10),
                busy
                    ? const SizedBox(
                        height: 32,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _pill(
                            context.l10n.player_claim_approve,
                            background: brandRedColor,
                            foreground: Colors.white,
                            onTap: () => _decide(claim, approve: true),
                          ),
                          _pill(
                            context.l10n.player_claim_decline,
                            background: cs.containerLow,
                            foreground: cs.textPrimary,
                            onTap: () => _decide(claim, approve: false),
                          ),
                        ],
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _myClaimRow(BuildContext context, PlayerClaim claim) {
    final cs = context.colorScheme;
    final declined = claim.status == PlayerClaimStatus.declined;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          IconTile(
            declined ? CupertinoIcons.xmark : CupertinoIcons.hourglass,
            declined ? cs.textSecondary : cs.warning,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              declined
                  ? context.l10n.player_claim_declined(claim.playerName)
                  : context.l10n.player_claim_waiting(claim.playerName),
              style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pill(
    String label, {
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyle.caption.copyWith(
            color: foreground,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
