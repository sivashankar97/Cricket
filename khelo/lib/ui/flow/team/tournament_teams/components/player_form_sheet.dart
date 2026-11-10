import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/api/user/user_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:khelo/components/action_bottom_sheet.dart';
import 'package:khelo/components/player_phone_field.dart';
import 'package:khelo/domain/extensions/app_error_extension.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/gen/assets.gen.dart';
import 'package:khelo/ui/flow/score_board/components/bottom_sheet_wrapper.dart';
import 'package:style/button/chip_button.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/widgets/adaptive_outlined_tile.dart';

import 'form_text_field.dart';
import 'tournament_player_role_extension.dart';

/// Add / edit form for a [TournamentTeamPlayer].
class PlayerFormSheet extends StatefulWidget {
  static Future<bool?> show(
    BuildContext context, {
    required String teamId,
    TournamentTeamPlayer? player,
    required Future<void> Function(
      TournamentTeamPlayer player,
      PlayerPhoneMatch phone,
    ) onSave,
  }) {
    HapticFeedback.mediumImpact();
    return showModalBottomSheet<bool>(
      context: context,
      showDragHandle: false,
      enableDrag: false,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: context.colorScheme.surface,
      builder: (context) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: PlayerFormSheet(teamId: teamId, player: player, onSave: onSave),
      ),
    );
  }

  final String teamId;
  final TournamentTeamPlayer? player;
  final Future<void> Function(
    TournamentTeamPlayer player,
    PlayerPhoneMatch phone,
  ) onSave;

  const PlayerFormSheet({
    super.key,
    required this.teamId,
    this.player,
    required this.onSave,
  });

  @override
  State<PlayerFormSheet> createState() => _PlayerFormSheetState();
}

class _PlayerFormSheetState extends State<PlayerFormSheet> {
  late final TextEditingController _nameController =
      TextEditingController(text: widget.player?.name);
  late final TextEditingController _jerseyController = TextEditingController(
      text: widget.player?.jerseyNumber?.toString() ?? '');
  final TextEditingController _phoneController = TextEditingController();
  PlayerPhoneMatch _match = PlayerPhoneMatch.none;
  late TournamentPlayerRole? _role = widget.player?.role;
  late BattingStyle? _battingStyle = widget.player?.battingStyle;
  late BowlingStyle? _bowlingStyle = widget.player?.bowlingStyle;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameController.dispose();
    _jerseyController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _onPhoneMatch(PlayerPhoneMatch match) {
    final name = match.player?.name;
    final editing = widget.player != null;
    if (!editing && name != null && name.isNotEmpty) {
      _nameController.text = name;
    }
    setState(() {
      _match = match;
      _error = null;
    });
  }

  /// Why the typed number can't be saved, if it can't.
  String? _phoneProblem() {
    final found = _match.player;
    if (widget.player != null &&
        found != null &&
        found.id != widget.player!.id) {
      return context.l10n.player_phone_taken(found.name ?? '');
    }
    if (_phoneController.text.trim().isNotEmpty && _match.e164 == null) {
      return context.l10n.player_phone_incomplete;
    }
    return null;
  }

  Future<void> _save() async {
    final problem = _phoneProblem();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(
          TournamentTeamPlayer(
            id: widget.player?.id ?? '',
            teamId: widget.teamId,
            name: _nameController.text.trim(),
            role: _role,
            battingStyle: _battingStyle,
            bowlingStyle: _bowlingStyle,
            jerseyNumber: int.tryParse(_jerseyController.text.trim()),
          ),
          _match);
      if (mounted) context.pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.l10nMessage(context);
      });
    }
  }

  void _selectBowlingStyle() {
    showActionBottomSheet(
      context: context,
      heightFactor: 0.7,
      items: BowlingStyle.values
          .where((style) => style != BowlingStyle.none)
          .map((style) => BottomSheetAction(
                title: style.getString(context),
                child: style == _bowlingStyle
                    ? SvgPicture.asset(
                        Assets.images.icCheck,
                        colorFilter: ColorFilter.mode(
                          context.colorScheme.primary,
                          BlendMode.srcATop,
                        ),
                      )
                    : null,
                onTap: () {
                  context.pop();
                  setState(() =>
                      _bowlingStyle = style == _bowlingStyle ? null : style);
                },
              ))
          .toList(),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 4),
        child: Text(
          text,
          style: AppTextStyle.caption
              .copyWith(color: context.colorScheme.textSecondary),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return BottomSheetWrapper(
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.player == null
                ? context.l10n.tournament_team_add_player
                : context.l10n.tournament_team_edit_player,
            style: AppTextStyle.header3
                .copyWith(color: context.colorScheme.textPrimary),
          ),
          const SizedBox(height: 16),
          FormTextField(
            controller: _nameController,
            label: context.l10n.tournament_team_player_name_label,
            autoFocus: widget.player == null,
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 12),
          PlayerPhoneField(
            controller: _phoneController,
            selfId: widget.player?.id,
            onChanged: _onPhoneMatch,
          ),
          _label(context.l10n.tournament_team_player_role_label),
          Wrap(
            spacing: 8,
            children: TournamentPlayerRole.values
                .map((role) => ChipButton(
                      title: role.getString(context),
                      isSelected: role == _role,
                      onTap: () =>
                          setState(() => _role = role == _role ? null : role),
                    ))
                .toList(),
          ),
          _label(context.l10n.common_batting_style_title),
          Wrap(
            spacing: 8,
            children: BattingStyle.values
                .map((style) => ChipButton(
                      title: style.getString(context),
                      isSelected: style == _battingStyle,
                      onTap: () => setState(() => _battingStyle =
                          style == _battingStyle ? null : style),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
          AdaptiveOutlinedTile(
            headerText: context.l10n.common_bowling_style_title,
            placeholder: context.l10n.common_bowling_style_title,
            title: _bowlingStyle?.getString(context),
            showTrailingIcon: true,
            onTap: _selectBowlingStyle,
          ),
          const SizedBox(height: 16),
          FormTextField(
            controller: _jerseyController,
            label: context.l10n.tournament_team_jersey_label,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
          ),
        ],
      ),
      options: [if (_error != null) FormErrorText(_error!)],
      action: [
        PrimaryButton(
          widget.player == null
              ? (_match.player != null
                  ? context.l10n
                      .player_phone_add_existing(_match.player!.name ?? '')
                  : context.l10n.common_add_title)
              : context.l10n.common_save_title,
          enabled: _nameController.text.trim().isNotEmpty && !_match.checking,
          progress: _saving,
          onPressed: _save,
        ),
      ],
    );
  }
}
