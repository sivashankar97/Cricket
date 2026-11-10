import 'package:data/api/auction/auction_models.dart';
import 'package:data/api/tournament_team/tournament_team_model.dart';
import 'package:data/service/auction/auction_service.dart';
import 'package:data/service/user/player_link_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/confirmation_dialog.dart';
import 'package:khelo/components/error_snackbar.dart';
import 'package:khelo/components/player_phone_field.dart';
import 'package:khelo/domain/auction/auction_import.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/button/primary_button.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/shadows.dart';

import '../../team/tournament_teams/components/tournament_player_role_extension.dart';
import '../auction_providers.dart';
import '../components/auction_image_picker.dart';
import '../components/auction_widgets.dart';

/// Admin screen to register auction players: one by one, pasted lists and
/// bulk photo upload matched by file name.
class AuctionPlayersScreen extends ConsumerStatefulWidget {
  final String auctionId;

  const AuctionPlayersScreen({super.key, required this.auctionId});

  @override
  ConsumerState<AuctionPlayersScreen> createState() =>
      _AuctionPlayersScreenState();
}

class _AuctionPlayersScreenState extends ConsumerState<AuctionPlayersScreen> {
  final _search = TextEditingController();
  AuctionPlayerStatus? _filter;
  bool _busy = false;

  AuctionService get _service => ref.read(auctionServiceProvider);

  String get _userId => ref.read(currentUserPod)?.id ?? '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } on AuctionActionException catch (e) {
      if (mounted) showSnackBar(context, e.error.label(context));
    } catch (e) {
      if (mounted) showErrorSnackBar(context: context, error: e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  List<AuctionPlayer> _visible(Auction auction) {
    final query = _search.text.trim().toLowerCase();
    return auction.orderedPlayers.where((p) {
      if (_filter != null && p.status != _filter) return false;
      if (query.isEmpty) return true;
      return p.name.toLowerCase().contains(query) ||
          (p.code?.toLowerCase().contains(query) ?? false) ||
          '${p.number ?? ''}' == query;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final auction = ref.watch(auctionProvider(widget.auctionId)).valueOrNull;
    if (auction == null) {
      return const AppPage(body: Center(child: AppProgressIndicator()));
    }
    final players = _visible(auction);
    final cs = context.colorScheme;
    return AppPage(
      title:
          '${context.l10n.auction_players_title} (${auction.players.length})',
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              context.mediaQueryPadding.top + 12,
              16,
              0,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    _action(
                      context,
                      CupertinoIcons.person_add,
                      context.l10n.auction_add_player,
                      () => _edit(auction),
                    ),
                    const SizedBox(width: 8),
                    _action(
                      context,
                      CupertinoIcons.text_badge_plus,
                      context.l10n.auction_add_players_bulk,
                      () => _bulkAdd(auction),
                    ),
                    const SizedBox(width: 8),
                    _action(
                      context,
                      CupertinoIcons.photo_on_rectangle,
                      context.l10n.auction_upload_photos,
                      () => _uploadPhotos(auction),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _search,
                  hintText: context.l10n.auction_player_search,
                  prefixIcon: Icon(
                    CupertinoIcons.search,
                    size: 18,
                    color: cs.textSecondary,
                  ),
                  onChanged: (_) => setState(() {}),
                  borderType: AppTextFieldBorderType.outline,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _chip(context, null, auction.players.length),
                      for (final s in AuctionPlayerStatus.values)
                        _chip(context, s, auction.playersWith(s).length),
                    ],
                  ),
                ),
                if (_busy) const LinearProgressIndicator(minHeight: 2),
              ],
            ),
          ),
          Expanded(
            child: auction.players.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      context.l10n.auction_players_empty,
                      textAlign: TextAlign.center,
                      style:
                          AppTextStyle.body2.copyWith(color: cs.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      10,
                      16,
                      40 + context.mediaQueryPadding.bottom,
                    ),
                    itemCount: players.length,
                    itemBuilder: (context, i) =>
                        _playerTile(context, auction, players[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    final cs = context.colorScheme;
    return Expanded(
      child: Material(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: _busy ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              children: [
                Icon(icon, size: 20, color: cs.primary),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.caption.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, AuctionPlayerStatus? status, int count) =>
      Padding(
        padding: const EdgeInsets.only(right: 6),
        child: ChoiceChip(
          label: Text(
            '${status?.label(context) ?? context.l10n.auction_filter_all} ($count)',
          ),
          selected: _filter == status,
          onSelected: (_) => setState(() => _filter = status),
        ),
      );

  Widget _playerTile(
    BuildContext context,
    Auction auction,
    AuctionPlayer player,
  ) {
    final cs = context.colorScheme;
    final team = auction.teamById(player.teamId);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: cs.cardDecoration(radius: 14),
      child: ListTile(
        onTap: () => _edit(auction, player: player),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: AuctionPhoto.player(player),
        title: Text(
          player.name,
          style: AppTextStyle.subtitle2.copyWith(color: cs.textPrimary),
        ),
        subtitle: Text(
          playerDetails(context, player, team: team),
          style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
        ),
        trailing: AuctionPlayerTag(status: player.status),
      ),
    );
  }

  Future<void> _edit(Auction auction, {AuctionPlayer? player}) async {
    final result = await showDialog<_PlayerFormResult>(
      context: context,
      builder: (_) => _PlayerDialog(
        player: player,
        newId: _service.newId(),
        basePrice: auction.basePrice,
        canRemove: player != null &&
            auction.status.isSetup &&
            player.status == AuctionPlayerStatus.available,
      ),
    );
    if (result == null) return;
    await _run(() async {
      if (result.remove) {
        await _service.removePlayer(auction.id, _userId, player!.id);
        return;
      }
      var saved = result.player;
      final found = result.phone.player;
      if (found != null) saved = saved.copyWith(userId: found.id);
      final duplicate = auction.duplicateOf(saved);
      if (duplicate != null) {
        throw const AuctionActionException(AuctionError.duplicatePlayer);
      }
      if (result.phone.isNew) {
        final created =
            await ref.read(playerLinkServiceProvider).createPlayerWithPhone(
                  name: saved.name,
                  e164: result.phone.e164!,
                  organizerId: _userId,
                );
        saved = saved.copyWith(userId: created.user.id);
      }
      await _service.upsertPlayers(auction.id, _userId, [saved]);
      if (result.photo != null) {
        await _service.uploadPlayerPhotos(
          auction.id,
          _userId,
          {saved.id: result.photo!},
        );
      }
    });
  }

  Future<void> _bulkAdd(Auction auction) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: context.colorScheme.surface,
        title: Text(context.l10n.auction_bulk_title),
        content: SizedBox(
          width: 520,
          child: AppTextField(
            controller: controller,
            hintText: context.l10n.auction_bulk_hint,
            autoFocus: true,
            minLines: 8,
            maxLines: 16,
            textCapitalization: TextCapitalization.words,
            borderType: AppTextFieldBorderType.outline,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.l10n.common_cancel_title),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: Text(context.l10n.common_add_title),
          ),
        ],
      ),
    ).whenComplete(controller.dispose);
    if (text == null || text.trim().isEmpty) return;
    final players = parsePlayerLines(
      text,
      defaultBasePrice: auction.basePrice,
      newId: _service.newId,
    );
    await _run(() async {
      final skipped =
          await _service.upsertPlayers(auction.id, _userId, players);
      if (mounted) {
        showSnackBar(
          context,
          context.l10n.auction_bulk_result(players.length - skipped, skipped),
        );
      }
    });
  }

  Future<void> _uploadPhotos(Auction auction) async {
    final photos = await pickAuctionPhotos();
    if (photos.isEmpty || !mounted) return;
    final plan = await showDialog<List<_PhotoAssignment>>(
      context: context,
      builder: (_) => _PhotoMatchDialog(auction: auction, photos: photos),
    );
    if (plan == null || plan.isEmpty) return;
    await _run(() async {
      // A "new" player that already exists by name gets the photo instead.
      final newPlayers = <String, AuctionPlayer>{};
      final photosById = <String, Uint8List>{};
      for (final a in plan) {
        var playerId = a.playerId;
        if (a.newPlayerName != null) {
          final candidate = AuctionPlayer(
            id: a.playerId,
            name: a.newPlayerName!,
            basePrice: auction.basePrice,
          );
          final existing = auction.duplicateOf(candidate) ??
              newPlayers.values
                  .where((p) =>
                      p.name.toLowerCase() == candidate.name.toLowerCase())
                  .firstOrNull;
          if (existing != null) {
            playerId = existing.id;
          } else {
            newPlayers[playerId] = candidate;
          }
        }
        photosById[playerId] = a.bytes;
      }
      if (newPlayers.isNotEmpty) {
        await _service.upsertPlayers(
          auction.id,
          _userId,
          newPlayers.values.toList(),
        );
      }
      await _service.uploadPlayerPhotos(auction.id, _userId, photosById);
      if (mounted) {
        showSnackBar(
            context, context.l10n.auction_photos_done(photosById.length));
      }
    });
  }
}

/// "P001 · #7 · Batsman · Base 20 pts", plus team and price once assigned.
String playerDetails(
  BuildContext context,
  AuctionPlayer player, {
  AuctionTeam? team,
}) =>
    [
      if (player.code?.isNotEmpty ?? false) player.code!,
      if (player.number != null) '#${player.number}',
      if (player.role != null) player.role!.getString(context),
      if (team != null && player.price != null)
        '${team.name} · ${context.l10n.auction_pts(player.price!)}'
      else
        context.l10n.auction_base(player.basePrice),
    ].join(' · ');

class _PlayerFormResult {
  final AuctionPlayer player;
  final Uint8List? photo;
  final bool remove;
  final PlayerPhoneMatch phone;

  const _PlayerFormResult(
    this.player, {
    this.photo,
    this.remove = false,
    this.phone = PlayerPhoneMatch.none,
  });
}

class _PlayerDialog extends StatefulWidget {
  final AuctionPlayer? player;
  final String newId;
  final int basePrice;
  final bool canRemove;

  const _PlayerDialog({
    required this.player,
    required this.newId,
    required this.basePrice,
    required this.canRemove,
  });

  @override
  State<_PlayerDialog> createState() => _PlayerDialogState();
}

class _PlayerDialogState extends State<_PlayerDialog> {
  late final _name = TextEditingController(text: widget.player?.name);
  late final _code = TextEditingController(text: widget.player?.code);
  late final _number =
      TextEditingController(text: widget.player?.number?.toString());
  late final _price = TextEditingController(
    text: '${widget.player?.basePrice ?? widget.basePrice}',
  );
  late TournamentPlayerRole? _role = widget.player?.role;
  final _phone = TextEditingController();
  PlayerPhoneMatch _match = PlayerPhoneMatch.none;
  Uint8List? _photo;

  void _onPhoneMatch(PlayerPhoneMatch match) {
    final name = match.player?.name;
    if (widget.player == null && name != null && name.isNotEmpty) {
      _name.text = name;
    }
    setState(() => _match = match);
  }

  @override
  void dispose() {
    for (final c in [_name, _code, _number, _price, _phone]) {
      c.dispose();
    }
    super.dispose();
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) =>
      AppTextField(
        controller: c,
        label: label,
        keyboardType: number ? TextInputType.number : null,
        inputFormatters:
            number ? [FilteringTextInputFormatter.digitsOnly] : null,
        textCapitalization:
            number ? TextCapitalization.none : TextCapitalization.words,
        borderType: AppTextFieldBorderType.outline,
      );

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final existing = widget.player;
    return AlertDialog(
      backgroundColor: cs.surface,
      title: Text(
        existing == null
            ? context.l10n.auction_add_player
            : context.l10n.auction_edit_player,
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (_photo != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.memory(
                        _photo!,
                        height: 72,
                        width: 72,
                        fit: BoxFit.cover,
                      ),
                    )
                  else if (existing != null)
                    AuctionPhoto.player(existing, size: 72, radius: 14)
                  else
                    AuctionPhoto(
                      photoId: '',
                      hasPhoto: false,
                      fallback: '?',
                      size: 72,
                      radius: 14,
                    ),
                  const SizedBox(width: 12),
                  TextButton.icon(
                    onPressed: () async {
                      final bytes = await pickAuctionPhoto();
                      if (bytes != null) setState(() => _photo = bytes);
                    },
                    icon: const Icon(CupertinoIcons.photo, size: 16),
                    label: Text(
                      (existing?.hasPhoto ?? false) || _photo != null
                          ? context.l10n.auction_photo_change
                          : context.l10n.auction_photo_add,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _field(_name, context.l10n.auction_player_name),
              const SizedBox(height: 10),
              PlayerPhoneField(
                controller: _phone,
                selfId: existing?.userId,
                alreadyLinked: existing?.userId != null,
                onChanged: _onPhoneMatch,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                      child: _field(_code, context.l10n.auction_player_code)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _field(
                      _number,
                      context.l10n.auction_player_number,
                      number: true,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: TournamentPlayerRole.values
                    .map(
                      (role) => ChoiceChip(
                        label: Text(role.getString(context)),
                        selected: _role == role,
                        onSelected: (selected) =>
                            setState(() => _role = selected ? role : null),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
              _field(_price, context.l10n.auction_player_base, number: true),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.canRemove)
          TextButton(
            onPressed: () => showConfirmationDialog(
              context,
              title: context.l10n.auction_remove_player,
              message:
                  context.l10n.auction_remove_player_confirm(existing!.name),
              confirmBtnText: context.l10n.auction_remove_player,
              onConfirm: () => Navigator.of(context)
                  .pop(_PlayerFormResult(existing, remove: true)),
            ),
            child: Text(
              context.l10n.auction_remove_player,
              style: TextStyle(color: cs.alert),
            ),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.common_cancel_title),
        ),
        TextButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty || _match.checking) return;
            if (_phone.text.trim().isNotEmpty && _match.e164 == null) return;
            final found = _match.player;
            if (found != null && found.id == existing?.userId) {
              _match = PlayerPhoneMatch.none;
            }
            final code = _code.text.trim();
            final base = existing ??
                AuctionPlayer(id: widget.newId, name: name, basePrice: 0);
            Navigator.of(context).pop(
              _PlayerFormResult(
                base.copyWith(
                  name: name,
                  code: code.isEmpty ? null : code,
                  number: int.tryParse(_number.text.trim()),
                  role: _role,
                  basePrice:
                      int.tryParse(_price.text.trim()) ?? widget.basePrice,
                ),
                photo: _photo,
                phone: _match,
              ),
            );
          },
          child: Text(
            existing == null
                ? context.l10n.common_add_title
                : context.l10n.auction_save,
          ),
        ),
      ],
    );
  }
}

class _PhotoAssignment {
  final String playerId;
  final Uint8List bytes;

  /// Set when the photo creates a new player named after the file.
  final String? newPlayerName;

  const _PhotoAssignment(this.playerId, this.bytes, {this.newPlayerName});
}

/// Reviews how picked photos map to players before uploading.
class _PhotoMatchDialog extends ConsumerStatefulWidget {
  final Auction auction;
  final List<PickedPhoto> photos;

  const _PhotoMatchDialog({required this.auction, required this.photos});

  @override
  ConsumerState<_PhotoMatchDialog> createState() => _PhotoMatchDialogState();
}

class _PhotoMatchDialogState extends ConsumerState<_PhotoMatchDialog> {
  static const _skip = '__skip__';
  static const _new = '__new__';

  /// Per photo: a player id, [_new] or [_skip].
  late final List<String> _choice = [
    for (final photo in widget.photos)
      matchPhotoToPlayer(photo.name, widget.auction.players)?.id ?? _new,
  ];

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final players = widget.auction.orderedPlayers;
    final matched = _choice.where((c) => c != _skip && c != _new).length;
    final count = _choice.where((c) => c != _skip).length;
    return AlertDialog(
      backgroundColor: cs.surface,
      title: Text(context.l10n.auction_photos_title),
      content: SizedBox(
        width: 560,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.l10n.auction_photos_help,
              style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.auction_photos_summary(
                matched,
                widget.photos.length - matched,
              ),
              style: AppTextStyle.subtitle3.copyWith(
                color: cs.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: widget.photos.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final photo = widget.photos[i];
                  final stem = fileStem(photo.name);
                  return Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.memory(
                          photo.bytes,
                          height: 48,
                          width: 48,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButton<String>(
                          isExpanded: true,
                          value: _choice[i],
                          underline: const SizedBox(),
                          items: [
                            DropdownMenuItem(
                              value: _new,
                              child: Text(
                                context.l10n.auction_photo_new_player(stem),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: _skip,
                              child: Text(context.l10n.auction_photo_skip),
                            ),
                            for (final p in players)
                              DropdownMenuItem(
                                value: p.id,
                                child: Text(
                                  [
                                    p.code,
                                    p.number == null ? null : '#${p.number}',
                                    p.name
                                  ].whereType<String>().join(' · '),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => _choice[i] = v!),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.l10n.common_cancel_title),
        ),
        PrimaryButton(
          context.l10n.auction_photos_upload(count),
          expanded: false,
          enabled: count > 0,
          onPressed: () {
            final service = ref.read(auctionServiceProvider);
            Navigator.of(context).pop([
              for (var i = 0; i < widget.photos.length; i++)
                if (_choice[i] == _new)
                  _PhotoAssignment(
                    service.newId(),
                    widget.photos[i].bytes,
                    newPlayerName: fileStem(widget.photos[i].name),
                  )
                else if (_choice[i] != _skip)
                  _PhotoAssignment(_choice[i], widget.photos[i].bytes),
            ]);
          },
        ),
      ],
    );
  }
}
