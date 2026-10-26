import 'package:data/api/match/match_model.dart';
import 'package:data/api/user/user_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/flow/score_board/components/bottom_sheet_wrapper.dart';
import 'package:khelo/ui/flow/score_board/score_board_view_model.dart';
import 'package:style/button/chip_button.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

class ReplacePlayerSheet extends ConsumerStatefulWidget {
  static Future<T?> show<T>(BuildContext context) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet(
      context: context,
      showDragHandle: false,
      enableDrag: false,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colorScheme.surface,
      builder: (context) => const ReplacePlayerSheet(),
    );
  }

  const ReplacePlayerSheet({super.key});

  @override
  ConsumerState createState() => _ReplacePlayerSheetState();
}

class _ReplacePlayerSheetState extends ConsumerState<ReplacePlayerSheet> {
  String? _teamId;
  String? _outPlayerId;
  String? _inPlayerId;

  @override
  void initState() {
    super.initState();
    _teamId =
        ref.read(scoreBoardStateProvider).match?.teams.firstOrNull?.team.id;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(scoreBoardStateProvider);
    final notifier = ref.read(scoreBoardStateProvider.notifier);
    final teams = state.match?.teams ?? [];
    final outCandidates =
        _teamId == null ? <MatchPlayer>[] : notifier.getReplaceablePlayers(_teamId!);
    final inCandidates =
        _teamId == null ? <UserModel>[] : notifier.getBenchPlayers(_teamId!);

    return BottomSheetWrapper(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.score_board_replace_player_title,
            style: AppTextStyle.header3
                .copyWith(color: context.colorScheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            context.l10n.score_board_replace_player_description,
            style: AppTextStyle.caption
                .copyWith(color: context.colorScheme.textDisabled),
          ),
          _sectionTitle(context, context.l10n.score_board_replace_team_title),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: teams
                .map((team) => ChipButton(
                      title: team.team.name,
                      isSelected: team.team.id == _teamId,
                      onTap: () => setState(() {
                        _teamId = team.team.id;
                        _outPlayerId = null;
                        _inPlayerId = null;
                      }),
                    ))
                .toList(),
          ),
          _sectionTitle(context, context.l10n.score_board_replace_out_title),
          _playerChips(
            context,
            players: outCandidates.map((e) => e.player).toList(),
            selectedId: _outPlayerId,
            onSelect: (id) => setState(() => _outPlayerId = id),
          ),
          _sectionTitle(context, context.l10n.score_board_replace_in_title),
          _playerChips(
            context,
            players: inCandidates,
            selectedId: _inPlayerId,
            onSelect: (id) => setState(() => _inPlayerId = id),
          ),
        ],
      ),
      action: [
        PrimaryButton(
          context.l10n.score_board_replace_player_title,
          enabled: _teamId != null && _outPlayerId != null && _inPlayerId != null,
          progress: state.isActionInProgress,
          onPressed: () async {
            await notifier.replacePlayer(
              teamId: _teamId!,
              outPlayerId: _outPlayerId!,
              inPlayerId: _inPlayerId!,
            );
            if (context.mounted) context.pop(true);
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      child: Text(
        title,
        style: AppTextStyle.subtitle2
            .copyWith(color: context.colorScheme.textPrimary),
      ),
    );
  }

  Widget _playerChips(
    BuildContext context, {
    required List<UserModel> players,
    required String? selectedId,
    required ValueChanged<String> onSelect,
  }) {
    if (players.isEmpty) {
      return Text(
        context.l10n.score_board_replace_no_player_text,
        style: AppTextStyle.body2
            .copyWith(color: context.colorScheme.textDisabled),
      );
    }
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: players
          .map((player) => ChipButton(
                title: player.name ?? '',
                isSelected: player.id == selectedId,
                onTap: () => onSelect(player.id),
              ))
          .toList(),
    );
  }
}
