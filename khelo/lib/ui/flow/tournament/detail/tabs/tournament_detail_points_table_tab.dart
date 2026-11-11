import 'package:data/api/tournament/tournament_extras.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/animations/motion.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

import '../../../../../components/empty_screen.dart';
import '../../../../app_route.dart';
import '../components/tournament_widgets.dart';
import '../summary/tournament_summary.dart';
import '../summary/tournament_summary_provider.dart';

class TournamentDetailPointsTableTab extends ConsumerWidget {
  const TournamentDetailPointsTableTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(tournamentSummaryProvider);
    final extras = ref.watch(tournamentTeamExtrasProvider);
    final rows = summary.standings.where((r) => r.played > 0).toList();
    if (rows.isEmpty) {
      return EmptyScreen(
        title: context.l10n.tournament_detail_points_table_empty_title,
        description:
            context.l10n.tournament_detail_points_table_empty_description,
        isShowButton: false,
      );
    }
    return ListView(
      padding: context.mediaQueryPadding.copyWith(top: 0) +
          const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        PointsTable(rows: rows, extras: extras),
        const SizedBox(height: 12),
        Appear(
          index: rows.length,
          child: Text(
            context.l10n.tournament_points_note,
            style: AppTextStyle.caption
                .copyWith(color: context.colorScheme.textDisabled),
          ),
        ),
      ],
    );
  }
}

class PointsTable extends StatelessWidget {
  final List<StandingRow> rows;
  final Map<String, TeamExtras> extras;
  final bool showForm;

  const PointsTable({
    super.key,
    required this.rows,
    required this.extras,
    this.showForm = true,
  });

  static const _numWidth = 30.0;
  static const _nrrWidth = 50.0;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final header = AppTextStyle.caption.copyWith(
      color: cs.textDisabled,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.4,
    );
    final l10n = context.l10n;
    Widget num(String text, {double width = _numWidth, TextStyle? style}) =>
        SizedBox(
          width: width,
          child: Text(text, textAlign: TextAlign.center, style: style),
        );
    return MediaQuery.withNoTextScaling(
      child: TournamentCard(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(width: 22, child: Text('#', style: header)),
                Expanded(
                    child: Text(l10n.tournament_col_team.toUpperCase(),
                        style: header)),
                num(l10n.tournament_col_played, style: header),
                num(l10n.tournament_col_won, style: header),
                num(l10n.tournament_col_lost, style: header),
                num(l10n.tournament_col_nrr, width: _nrrWidth, style: header),
                num(l10n.tournament_col_points,
                    style: header.copyWith(color: cs.primary)),
              ],
            ),
            const SizedBox(height: 6),
            for (var i = 0; i < rows.length; i++)
              Appear(
                key: ValueKey(rows[i].team.id),
                index: i,
                child: OnTapScale(
                  onTap: () => AppRoute.teamDetail(teamId: rows[i].team.id)
                      .push(context),
                  child: _row(context, i, rows[i], num),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    int index,
    StandingRow row,
    Widget Function(String, {double width, TextStyle? style}) num,
  ) {
    final cs = context.colorScheme;
    final value = AppTextStyle.body2.copyWith(color: cs.textPrimary);
    final owner = extras[row.team.id]?.ownerName;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: cs.outline, width: 0.5)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 22,
                child: Text(
                  '${index + 1}',
                  style: AppTextStyle.subtitle3.copyWith(
                    color: index < 4 ? cs.primary : cs.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              TeamBadge(row.team, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.team.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.subtitle3.copyWith(
                          color: cs.textPrimary, fontWeight: FontWeight.w600),
                    ),
                    if (owner != null)
                      Text(
                        owner,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.caption
                            .copyWith(color: cs.textDisabled),
                      ),
                  ],
                ),
              ),
              num('${row.played}', style: value),
              num('${row.won}', style: value),
              num('${row.lost}', style: value),
              SizedBox(
                width: _nrrWidth,
                child: CountUp(
                  value: row.nrr,
                  decimals: 2,
                  format: formatNrr,
                  textAlign: TextAlign.center,
                  style: value.copyWith(
                    color: row.nrr >= 0 ? cs.textPrimary : cs.alert,
                  ),
                ),
              ),
              SizedBox(
                width: _numWidth,
                child: CountUp(
                  value: row.points,
                  textAlign: TextAlign.center,
                  style: AppTextStyle.subtitle2.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (showForm && row.form.isNotEmpty) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FormDots(row.form, size: 18),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
