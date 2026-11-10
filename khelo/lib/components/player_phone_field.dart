import 'dart:async';

import 'package:data/api/user/user_models.dart';
import 'package:data/service/user/player_link_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/phone/phone_number.dart';
import 'package:khelo/ui/flow/settings/edit_profile/profile_completion.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';

/// What [PlayerPhoneField] found for the typed number.
class PlayerPhoneMatch {
  /// The full number, when a valid mobile was typed.
  final String? e164;

  /// The player who already has this number.
  final UserModel? player;
  final bool checking;

  const PlayerPhoneMatch({this.e164, this.player, this.checking = false});

  static const none = PlayerPhoneMatch();

  /// A valid number nobody has yet.
  bool get isNew => e164 != null && player == null && !checking;
}

/// Mobile number field for adding a player. A known number fills in that
/// player (one number = one player everywhere); an unknown one makes a new
/// player whose future account can claim it ([PlayerLinkService]).
class PlayerPhoneField extends ConsumerStatefulWidget {
  final TextEditingController controller;
  final ValueChanged<PlayerPhoneMatch> onChanged;

  /// The player being edited, so a match on them isn't someone else.
  final String? selfId;

  /// Shown while empty when the player already has a linked number.
  final bool alreadyLinked;

  const PlayerPhoneField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.selfId,
    this.alreadyLinked = false,
  });

  @override
  ConsumerState<PlayerPhoneField> createState() => _PlayerPhoneFieldState();
}

class _PlayerPhoneFieldState extends ConsumerState<PlayerPhoneField> {
  Timer? _debounce;
  PlayerPhoneMatch _match = PlayerPhoneMatch.none;
  PhoneCountry _country = PhoneCountry.india;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    ref.listenManual(currentUserPhoneProvider, (_, next) {
      final country = PhoneNumber.parse(next.valueOrNull)?.country;
      if (country != null) _country = country;
    }, fireImmediately: true);
    if (widget.controller.text.isNotEmpty) _onTextChanged();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _set(PlayerPhoneMatch match) {
    if (!mounted) return;
    setState(() => _match = match);
    widget.onChanged(match);
  }

  void _onTextChanged() {
    _debounce?.cancel();
    final e164 = PhoneNumber.toE164(widget.controller.text, _country);
    if (e164 == null) {
      if (_match.e164 != null || _match.checking) {
        _set(PlayerPhoneMatch.none);
      } else if (mounted) {
        setState(() {});
      }
      return;
    }
    if (e164 == _match.e164 && !_match.checking) return;
    _set(PlayerPhoneMatch(e164: e164, checking: true));
    _debounce = Timer(const Duration(milliseconds: 400), () => _lookup(e164));
  }

  Future<void> _lookup(String e164) async {
    UserModel? player;
    try {
      player =
          await ref.read(playerLinkServiceProvider).findPlayerByPhone(e164);
    } catch (error) {
      debugPrint('PlayerPhoneField: lookup failed -> $error');
    }
    final current = PhoneNumber.toE164(widget.controller.text, _country);
    if (current != e164) return;
    _set(PlayerPhoneMatch(e164: e164, player: player));
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          controller: widget.controller,
          label: context.l10n.add_team_member_create_player_phone,
          keyboardType: TextInputType.phone,
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9+ ]')),
          ],
          borderRadius: BorderRadius.circular(12),
          borderType: AppTextFieldBorderType.outline,
          style: AppTextStyle.subtitle3.copyWith(color: cs.textPrimary),
          borderColor: BorderColor(
            focusColor: cs.outline,
            unFocusColor: cs.outline,
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.topLeft,
          child: _status(context),
        ),
      ],
    );
  }

  Widget _status(BuildContext context) {
    final cs = context.colorScheme;
    final text = widget.controller.text.trim();
    final player = _match.player;

    Widget row(Widget leading, String label, {Color? color, String? hint}) =>
        Padding(
          padding: const EdgeInsets.only(top: 8, left: 2),
          child: Row(
            children: [
              leading,
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTextStyle.caption.copyWith(
                        color: color ?? cs.textSecondary,
                        fontWeight: color == null ? null : FontWeight.w600,
                      ),
                    ),
                    if (hint != null)
                      Text(
                        hint,
                        style: AppTextStyle.caption
                            .copyWith(color: cs.textSecondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

    if (_match.checking) {
      return row(
        const AppProgressIndicator(size: AppProgressIndicatorSize.small),
        context.l10n.player_phone_checking,
      );
    }
    if (player != null && player.id == widget.selfId) {
      return row(
        Icon(CupertinoIcons.checkmark_seal_fill, size: 18, color: cs.positive),
        context.l10n.player_phone_self,
      );
    }
    if (player != null) {
      return row(
        ImageAvatar(
          size: 28,
          imageUrl: player.profile_img_url,
          initial: player.nameInitial,
        ),
        context.l10n.player_phone_found(player.name ?? ''),
        color: cs.textPrimary,
        hint: context.l10n.player_phone_found_hint,
      );
    }
    if (_match.isNew) {
      return row(
        Icon(CupertinoIcons.person_badge_plus, size: 18, color: cs.primary),
        context.l10n.player_phone_new,
      );
    }
    if (text.replaceAll(RegExp(r'\D'), '').length >= 4) {
      return row(
        Icon(CupertinoIcons.info, size: 16, color: cs.textSecondary),
        context.l10n.player_phone_incomplete,
      );
    }
    if (text.isEmpty && widget.alreadyLinked) {
      return row(
        Icon(CupertinoIcons.lock_fill, size: 16, color: cs.textSecondary),
        context.l10n.player_phone_linked,
      );
    }
    return const SizedBox(width: double.infinity);
  }
}
