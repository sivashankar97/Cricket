import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/action_bottom_sheet.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/confirmation_dialog.dart';
import 'package:khelo/components/empty_screen.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:style/button/action_button.dart';
import 'package:style/button/bottom_sticky_overlay.dart';
import 'package:style/button/more_option_button.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart';
import 'package:khelo/components/mascot/mascot_on_appear.dart';
import 'package:khelo/components/mascot/mascot_reactions.dart';

import '../../../auction/components/auction_widgets.dart';
import '../components/player_form_sheet.dart';
import '../components/tournament_player_role_extension.dart';
import '../components/tournament_team_form_sheet.dart';
import '../components/tournament_team_tile.dart';
import 'tournament_team_players_view_model.dart';

class TournamentTeamPlayersScreen extends ConsumerWidget {
  final String teamId;

  const TournamentTeamPlayersScreen({super.key, required this.teamId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = tournamentTeamPlayersStateProvider(teamId);
    ref.listen(provider.select((s) => s.actionError), (_, next) {
      if (next != null) showErrorSnackBar(context: context, error: next);
    });
    final state = ref.watch(provider);
    final notifier = ref.read(provider.notifier);
    final team = state.team;

    return AppPage(
      title: team?.name ?? context.l10n.tournament_teams_title,
      actions: [
        if (team != null)
          actionButton(
            context,
            onPressed: () => TournamentTeamFormSheet.show(
              context,
              team: team,
              players: state.players,
            ),
            icon: Icon(CupertinoIcons.pencil,
                color: context.colorScheme.textPrimary),
          ),
      ],
      body: Builder(builder: (context) {
        if (state.loading && team == null) {
          return const SkeletonList();
        }
        if (team == null) {
          return ErrorScreen(error: state.error, onRetryTap: notifier.load);
        }
        return Stack(
          children: [
            _content(context, state, notifier, team),
            BottomStickyOverlay(
              child: PrimaryButton(
                context.l10n.tournament_team_add_player,
                onPressed: () => _openPlayerForm(context, notifier, team),
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _content(
    BuildContext context,
    TournamentTeamPlayersState state,
    TournamentTeamPlayersViewNotifier notifier,
    TournamentTeam team,
  ) {
    final captain = state.playerById(team.captainId);
    final keeper = state.playerById(team.wicketKeeperId);
    final roles = [
      if (captain != null)
        '${context.l10n.tournament_team_captain_label}: ${captain.name}',
      if (keeper != null)
        '${context.l10n.tournament_team_wicket_keeper_label}: ${keeper.name}',
    ];

    return ListView(
      padding: const EdgeInsets.all(16) +
          context.mediaQueryPadding +
          BottomStickyOverlay.padding,
      children: [
        TournamentTeamTile(
          team: team,
          caption: roles.isEmpty ? null : roles.join(' · '),
        ),
        const SizedBox(height: 16),
        if (state.players.isEmpty && !state.loading)
          SizedBox(
            height: 260,
            child: MascotOnAppear(
              reaction: MascotReaction.noPlayers,
              child: EmptyScreen(
                title: context.l10n.tournament_team_players_empty_title,
                description:
                    context.l10n.tournament_team_players_empty_description,
                isShowButton: false,
              ),
            ),
          )
        else
          for (final player in state.players)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _PlayerTile(
                player: player,
                isCaptain: player.id == team.captainId,
                isWicketKeeper: player.id == team.wicketKeeperId,
                onMoreTap: () =>
                    _playerActions(context, notifier, team, player),
              ),
            ),
      ],
    );
  }

  void _openPlayerForm(
    BuildContext context,
    TournamentTeamPlayersViewNotifier notifier,
    TournamentTeam team, {
    TournamentTeamPlayer? player,
  }) {
    PlayerFormSheet.show(
      context,
      teamId: team.id,
      player: player,
      onSave: notifier.savePlayer,
    );
  }

  void _playerActions(
    BuildContext context,
    TournamentTeamPlayersViewNotifier notifier,
    TournamentTeam team,
    TournamentTeamPlayer player,
  ) {
    showActionBottomSheet(context: context, items: [
      BottomSheetAction(
        title: context.l10n.tournament_team_edit_player,
        onTap: () {
          context.pop();
          _openPlayerForm(context, notifier, team, player: player);
        },
      ),
      BottomSheetAction(
        title: team.captainId == player.id
            ? context.l10n.tournament_team_remove_captain
            : context.l10n.tournament_team_make_captain,
        onTap: () {
          context.pop();
          notifier.toggleCaptain(player);
        },
      ),
      BottomSheetAction(
        title: team.wicketKeeperId == player.id
            ? context.l10n.tournament_team_remove_wicket_keeper
            : context.l10n.tournament_team_make_wicket_keeper,
        onTap: () {
          context.pop();
          notifier.toggleWicketKeeper(player);
        },
      ),
      BottomSheetAction(
        title: context.l10n.common_remove_title,
        onTap: () {
          context.pop();
          showConfirmationDialog(
            context,
            title: context.l10n.tournament_team_remove_player_title,
            message: context.l10n
                .tournament_team_remove_player_description(player.name),
            confirmBtnText: context.l10n.common_remove_title,
            onConfirm: () => notifier.removePlayer(player),
          );
        },
      ),
    ]);
  }
}

class _PlayerTile extends StatelessWidget {
  final TournamentTeamPlayer player;
  final bool isCaptain;
  final bool isWicketKeeper;
  final VoidCallback onMoreTap;

  const _PlayerTile({
    required this.player,
    required this.isCaptain,
    required this.isWicketKeeper,
    required this.onMoreTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final details = [
      if (player.role != null) player.role!.getString(context),
      if (player.battingStyle != null) player.battingStyle!.getString(context),
      if (player.bowlingStyle != null) player.bowlingStyle!.getString(context),
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
      decoration: cs.cardDecoration(radius: 12).copyWith(
            border: Border.all(color: cs.outline, width: 0.5),
          ),
      child: Row(
        children: [
          if (player.photoId != null)
            AuctionPhoto(
              photoId: player.photoId!,
              hasPhoto: true,
              fallback: player.nameInitial,
              size: 40,
              radius: 20,
            )
          else
            ImageAvatar(
              initial: player.jerseyNumber?.toString() ?? player.nameInitial,
              size: 40,
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      player.name,
                      style: AppTextStyle.subtitle1
                          .copyWith(color: cs.textPrimary),
                    ),
                    if (isCaptain)
                      _Badge(context.l10n.tournament_team_captain_short),
                    if (isWicketKeeper)
                      _Badge(context.l10n.tournament_team_wicket_keeper_short),
                  ],
                ),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    details,
                    style:
                        AppTextStyle.caption.copyWith(color: cs.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          moreOptionButton(context, onPressed: onMoreTap),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;

  const _Badge(this.text);

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: AppTextStyle.caption
            .copyWith(color: cs.primary, fontWeight: FontWeight.w700),
      ),
    );
  }
}
