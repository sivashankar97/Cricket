import 'package:data/api/auction/auction_models.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_field.dart';
import 'package:style/text/app_text_style.dart';

import '../players/auction_players_screen.dart';
import 'auction_widgets.dart';

/// Searchable list of auction players; returns the one tapped.
Future<AuctionPlayer?> showPickAuctionPlayerSheet(
  BuildContext context, {
  required List<AuctionPlayer> players,
}) =>
    showModalBottomSheet<AuctionPlayer>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _PickPlayerSheet(players: players),
    );

class _PickPlayerSheet extends StatefulWidget {
  final List<AuctionPlayer> players;

  const _PickPlayerSheet({required this.players});

  @override
  State<_PickPlayerSheet> createState() => _PickPlayerSheetState();
}

class _PickPlayerSheetState extends State<_PickPlayerSheet> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final query = _search.text.trim().toLowerCase();
    final players = widget.players
        .where((p) =>
            query.isEmpty ||
            p.name.toLowerCase().contains(query) ||
            (p.code?.toLowerCase().contains(query) ?? false) ||
            '${p.number ?? ''}' == query,)
        .toList();
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.auction_pick_player,
                    style: AppTextStyle.header4.copyWith(
                      color: cs.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  AppTextField(
                    controller: _search,
                    autoFocus: true,
                    hintText: context.l10n.auction_player_search,
                    prefixIcon: Icon(CupertinoIcons.search,
                        size: 18, color: cs.textSecondary,),
                    onChanged: (_) => setState(() {}),
                    borderType: AppTextFieldBorderType.outline,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: players.length,
                itemBuilder: (context, i) {
                  final player = players[i];
                  return ListTile(
                    onTap: () => Navigator.of(context).pop(player),
                    leading: AuctionPhoto.player(player),
                    title: Text(
                      player.name,
                      style: AppTextStyle.subtitle2
                          .copyWith(color: cs.textPrimary),
                    ),
                    subtitle: Text(
                      playerDetails(context, player),
                      style: AppTextStyle.caption
                          .copyWith(color: cs.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
