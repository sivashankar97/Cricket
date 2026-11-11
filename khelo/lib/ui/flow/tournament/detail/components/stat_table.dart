import 'package:flutter/material.dart';
import 'package:style/animations/motion.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

import '../summary/tournament_summary.dart';
import 'tournament_widgets.dart';

class StatTableRow {
  final SummaryPlayer player;
  final List<String> values;

  const StatTableRow(this.player, this.values);
}

/// Ranked player table: fixed rank / player column, scrollable stat columns.
/// The [highlight] column is bold and counts up.
class StatTable extends StatelessWidget {
  static const _rowHeight = 52.0;
  static const _cellWidth = 52.0;

  final String playerTitle;
  final List<String> columns;
  final int highlight;
  final List<StatTableRow> rows;

  const StatTable({
    super.key,
    required this.playerTitle,
    required this.columns,
    required this.rows,
    this.highlight = 0,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final header = AppTextStyle.caption.copyWith(
      color: cs.textDisabled,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    return MediaQuery.withNoTextScaling(
      child: TournamentCard(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 172,
              child: Column(
                children: [
                  _headerCell(
                    Row(children: [
                      SizedBox(width: 28, child: Text('#', style: header)),
                      Text(playerTitle.toUpperCase(), style: header),
                    ]),
                  ),
                  for (var i = 0; i < rows.length; i++)
                    Appear(
                      key: ValueKey('p-${rows[i].player.id}'),
                      index: i,
                      child: _playerCell(context, i, rows[i].player),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    _headerCell(Row(
                      children: [
                        for (var c = 0; c < columns.length; c++)
                          SizedBox(
                            width: _cellWidth,
                            child: Text(
                              columns[c].toUpperCase(),
                              textAlign: TextAlign.center,
                              style: c == highlight
                                  ? header.copyWith(color: cs.primary)
                                  : header,
                            ),
                          ),
                      ],
                    )),
                    for (var i = 0; i < rows.length; i++)
                      Appear(
                        key: ValueKey('v-${rows[i].player.id}'),
                        index: i,
                        child: _valuesRow(context, i, rows[i]),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCell(Widget child) => Container(
        height: 36,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 12),
        child: child,
      );

  Widget _playerCell(BuildContext context, int index, SummaryPlayer player) {
    final cs = context.colorScheme;
    return Container(
      height: _rowHeight,
      padding: const EdgeInsets.only(left: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              '${index + 1}',
              style: AppTextStyle.subtitle3.copyWith(
                color: index < 3 ? cs.primary : cs.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PlayerAvatar(player, size: 30),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.user.name ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subtitle3.copyWith(
                      color: cs.textPrimary, fontWeight: FontWeight.w600),
                ),
                Text(
                  teamShortName(player.team),
                  style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _valuesRow(BuildContext context, int index, StatTableRow row) {
    final cs = context.colorScheme;
    return Container(
      height: _rowHeight,
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 0.5)),
      ),
      child: Row(
        children: [
          for (var c = 0; c < row.values.length; c++)
            SizedBox(
              width: _cellWidth,
              child: c == highlight
                  ? _countUp(row.values[c], cs.primary)
                  : Text(
                      row.values[c],
                      textAlign: TextAlign.center,
                      style: AppTextStyle.body2.copyWith(color: cs.textPrimary),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _countUp(String value, Color color) {
    final style = AppTextStyle.subtitle2
        .copyWith(color: color, fontWeight: FontWeight.w800);
    final number = double.tryParse(value);
    if (number == null) {
      return Text(value, textAlign: TextAlign.center, style: style);
    }
    final dot = value.indexOf('.');
    return CountUp(
      value: number,
      decimals: dot < 0 ? 0 : value.length - dot - 1,
      style: style,
      textAlign: TextAlign.center,
    );
  }
}
