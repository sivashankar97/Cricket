import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:style/animations/app_animations.dart';
import 'package:style/animations/motion.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/text/app_text_style.dart';

import '../../../../../components/empty_screen.dart';
import '../components/leader_card.dart';
import '../components/stat_table.dart';
import '../components/tournament_widgets.dart';
import '../summary/tournament_summary.dart';
import '../summary/tournament_summary_provider.dart';

enum _StatsView { batting, bowling, fielding, records, mvp }

class TournamentDetailStatsTab extends ConsumerStatefulWidget {
  const TournamentDetailStatsTab({super.key});

  @override
  ConsumerState<TournamentDetailStatsTab> createState() =>
      _TournamentDetailStatsTabState();
}

class _TournamentDetailStatsTabState
    extends ConsumerState<TournamentDetailStatsTab> {
  _StatsView _view = _StatsView.batting;

  String _label(BuildContext context, _StatsView view) => switch (view) {
        _StatsView.batting => context.l10n.tournament_stats_batting,
        _StatsView.bowling => context.l10n.tournament_stats_bowling,
        _StatsView.fielding => context.l10n.tournament_stats_fielding,
        _StatsView.records => context.l10n.tournament_stats_records,
        _StatsView.mvp => context.l10n.tournament_stats_mvp,
      };

  @override
  Widget build(BuildContext context) {
    final summary = ref.watch(tournamentSummaryProvider);
    final loading = ref.watch(tournamentSummaryLoadingProvider);

    if (summary.batting.isEmpty && summary.bowling.isEmpty) {
      if (loading) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                context.l10n.tournament_stats_loading,
                style: AppTextStyle.body2
                    .copyWith(color: context.colorScheme.textSecondary),
              ),
            ),
            const Expanded(child: SkeletonList(itemCount: 6)),
          ],
        );
      }
      return EmptyScreen(
        title: context.l10n.tournament_stats_empty_title,
        description: context.l10n.tournament_stats_empty_description,
        isShowButton: false,
      );
    }

    return ListView(
      padding: context.mediaQueryPadding.copyWith(top: 0) +
          const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        _viewSelector(context),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: AppAnimations.fast,
          switchInCurve: AppAnimations.curve,
          child: KeyedSubtree(
            key: ValueKey(_view),
            child: switch (_view) {
              _StatsView.batting => _batting(context, summary),
              _StatsView.bowling => _bowling(context, summary),
              _StatsView.fielding => _fielding(context, summary),
              _StatsView.records => _records(context, summary),
              _StatsView.mvp => _mvp(context, summary),
            },
          ),
        ),
      ],
    );
  }

  Widget _viewSelector(BuildContext context) {
    final cs = context.colorScheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final view in _StatsView.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: OnTapScale(
                onTap: () => setState(() => _view = view),
                child: AnimatedContainer(
                  duration: AppAnimations.fast,
                  curve: AppAnimations.curve,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                  decoration: BoxDecoration(
                    color: view == _view ? cs.primary : cs.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: view == _view
                          ? cs.primary
                          : cs.outline.withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    _label(context, view),
                    style: AppTextStyle.subtitle3.copyWith(
                      color: view == _view ? cs.onPrimary : cs.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  static String _avg(double? value) => value?.toStringAsFixed(2) ?? '-';

  Widget _batting(BuildContext context, TournamentSummary summary) {
    final rows = summary.batting;
    if (rows.isEmpty) return const SizedBox();
    final top = rows.first;
    final l10n = context.l10n;
    return Column(
      children: [
        Appear(
          index: 0,
          child: LeaderCard(
            title: l10n.tournament_stats_most_runs,
            player: top.player,
            value: top.runs,
            unit: l10n.tournament_col_runs,
            detail: l10n.tournament_stats_innings_sr(
                top.innings, top.strikeRate.toStringAsFixed(1)),
          ),
        ),
        const SizedBox(height: 12),
        StatTable(
          playerTitle: l10n.tournament_col_player,
          highlight: 1,
          columns: [
            l10n.tournament_col_innings,
            l10n.tournament_col_runs,
            l10n.tournament_col_highest,
            l10n.tournament_col_average,
            l10n.tournament_col_strike_rate,
            l10n.tournament_col_fours,
            l10n.tournament_col_sixes,
            l10n.tournament_col_fifties,
            l10n.tournament_col_hundreds,
          ],
          rows: [
            for (final r in rows)
              StatTableRow(r.player, [
                '${r.innings}',
                '${r.runs}',
                '${r.highest}${r.highestNotOut ? '*' : ''}',
                _avg(r.average),
                r.strikeRate.toStringAsFixed(1),
                '${r.fours}',
                '${r.sixes}',
                '${r.fifties}',
                '${r.hundreds}',
              ]),
          ],
        ),
      ],
    );
  }

  Widget _bowling(BuildContext context, TournamentSummary summary) {
    final rows = summary.bowling.where((r) => r.balls > 0).toList();
    if (rows.isEmpty) return const SizedBox();
    final top = rows.first;
    final l10n = context.l10n;
    return Column(
      children: [
        Appear(
          index: 0,
          child: LeaderCard(
            title: l10n.tournament_stats_most_wickets,
            player: top.player,
            value: top.wickets,
            unit: l10n.tournament_col_wickets,
            detail: l10n.tournament_stats_best_economy(
                '${top.bestWickets}/${top.bestRuns}',
                top.economy.toStringAsFixed(2)),
          ),
        ),
        const SizedBox(height: 12),
        StatTable(
          playerTitle: l10n.tournament_col_player,
          highlight: 3,
          columns: [
            l10n.tournament_col_overs,
            l10n.tournament_col_maidens,
            l10n.tournament_col_runs_conceded,
            l10n.tournament_col_wickets,
            l10n.tournament_col_best,
            l10n.tournament_col_economy,
          ],
          rows: [
            for (final r in rows)
              StatTableRow(r.player, [
                r.overs,
                '${r.maidens}',
                '${r.runs}',
                '${r.wickets}',
                '${r.bestWickets}/${r.bestRuns}',
                r.economy.toStringAsFixed(2),
              ]),
          ],
        ),
      ],
    );
  }

  Widget _fielding(BuildContext context, TournamentSummary summary) {
    final rows = summary.fielding;
    if (rows.isEmpty) return const SizedBox();
    final top = rows.first;
    final l10n = context.l10n;
    return Column(
      children: [
        Appear(
          index: 0,
          child: LeaderCard(
            title: l10n.tournament_stats_best_fielder,
            player: top.player,
            value: top.total,
            unit: l10n.tournament_stats_dismissals,
            detail: l10n.tournament_stats_catches(top.catches),
          ),
        ),
        const SizedBox(height: 12),
        StatTable(
          playerTitle: l10n.tournament_col_player,
          highlight: 3,
          columns: [
            l10n.tournament_col_catches,
            l10n.tournament_col_run_outs,
            l10n.tournament_col_stumpings,
            l10n.tournament_col_total,
          ],
          rows: [
            for (final r in rows)
              StatTableRow(r.player, [
                '${r.catches}',
                '${r.runOuts}',
                '${r.stumpings}',
                '${r.total}',
              ]),
          ],
        ),
      ],
    );
  }

  Widget _records(BuildContext context, TournamentSummary summary) {
    final l10n = context.l10n;
    final batting = summary.batting;
    final bowlers = summary.bowling.where((r) => r.balls > 0).toList();
    final records = <(String, String?, List<(SummaryPlayer, String)>)>[
      (
        l10n.tournament_stats_most_runs,
        null,
        [for (final r in batting.take(5)) (r.player, '${r.runs}')],
      ),
      (
        l10n.tournament_record_highest_score,
        null,
        [
          for (final i in (summary.innings.toList()
                ..sort((a, b) => b.runs.compareTo(a.runs)))
              .take(5))
            (i.player, '${i.runs}${i.out ? '' : '*'} (${i.balls})'),
        ],
      ),
      (
        l10n.tournament_record_best_average,
        l10n.tournament_record_min_innings(3),
        [
          for (final r in (batting
                  .where((r) => r.innings >= 3 && r.average != null)
                  .toList()
                ..sort((a, b) => b.average!.compareTo(a.average!)))
              .take(5))
            (r.player, r.average!.toStringAsFixed(2)),
        ],
      ),
      (
        l10n.tournament_record_best_strike_rate,
        l10n.tournament_record_min_balls(30),
        [
          for (final r in (batting.where((r) => r.balls >= 30).toList()
                ..sort((a, b) => b.strikeRate.compareTo(a.strikeRate)))
              .take(5))
            (r.player, r.strikeRate.toStringAsFixed(1)),
        ],
      ),
      (
        l10n.tournament_record_most_fours,
        null,
        [
          for (final r in (batting.toList()
                ..sort((a, b) => b.fours.compareTo(a.fours)))
              .take(5))
            (r.player, '${r.fours}'),
        ],
      ),
      (
        l10n.tournament_record_most_sixes,
        null,
        [
          for (final r in (batting.toList()
                ..sort((a, b) => b.sixes.compareTo(a.sixes)))
              .take(5))
            (r.player, '${r.sixes}'),
        ],
      ),
      (
        l10n.tournament_stats_most_wickets,
        null,
        [for (final r in bowlers.take(5)) (r.player, '${r.wickets}')],
      ),
      (
        l10n.tournament_record_best_bowling,
        null,
        [
          for (final r in (bowlers.toList()
                ..sort((a, b) {
                  final w = b.bestWickets.compareTo(a.bestWickets);
                  return w != 0 ? w : a.bestRuns.compareTo(b.bestRuns);
                }))
              .take(5))
            (r.player, '${r.bestWickets}/${r.bestRuns}'),
        ],
      ),
      (
        l10n.tournament_record_best_economy,
        l10n.tournament_record_min_overs(6),
        [
          for (final r in (bowlers.where((r) => r.balls >= 36).toList()
                ..sort((a, b) => a.economy.compareTo(b.economy)))
              .take(5))
            (r.player, r.economy.toStringAsFixed(2)),
        ],
      ),
    ].where((record) => record.$3.isNotEmpty).toList();

    return Column(
      children: [
        for (var i = 0; i < records.length; i++)
          Appear(
            index: i,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _recordCard(context, records[i]),
            ),
          ),
      ],
    );
  }

  Widget _recordCard(
    BuildContext context,
    (String, String?, List<(SummaryPlayer, String)>) record,
  ) {
    final cs = context.colorScheme;
    final (title, note, rows) = record;
    return TournamentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: AppTextStyle.subtitle1.copyWith(color: cs.textPrimary),
                ),
              ),
              if (note != null)
                Text(note,
                    style:
                        AppTextStyle.caption.copyWith(color: cs.textDisabled)),
            ],
          ),
          const SizedBox(height: 8),
          for (var i = 0; i < rows.length; i++)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${i + 1}',
                      style: AppTextStyle.subtitle3.copyWith(
                        color: i == 0 ? cs.primary : cs.textSecondary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  PlayerAvatar(rows[i].$1, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${rows[i].$1.user.name ?? ''}  ·  ${teamShortName(rows[i].$1.team)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.body2.copyWith(color: cs.textPrimary),
                    ),
                  ),
                  Text(
                    rows[i].$2,
                    style: AppTextStyle.subtitle2.copyWith(
                      color: i == 0 ? cs.primary : cs.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _mvp(BuildContext context, TournamentSummary summary) {
    final rows = summary.mvp;
    if (rows.isEmpty) return const SizedBox();
    final cs = context.colorScheme;
    final l10n = context.l10n;
    final top = rows.first;
    final max = top.total.toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Appear(
          index: 0,
          child: LeaderCard(
            title: l10n.tournament_stats_mvp_leader,
            player: top.player,
            value: top.total,
            unit: l10n.tournament_col_points,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _legend(context, cs.primary, l10n.tournament_col_bat),
            _legend(context, cs.textPrimary, l10n.tournament_col_bowl),
            _legend(context, cs.textDisabled, l10n.tournament_col_field),
          ],
        ),
        const SizedBox(height: 8),
        TournamentCard(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < rows.length && i < 40; i++)
                Appear(
                  key: ValueKey(rows[i].player.id),
                  index: i,
                  child: _mvpRow(context, i, rows[i], max),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.tournament_stats_mvp_formula,
          style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
        ),
      ],
    );
  }

  Widget _legend(BuildContext context, Color color, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(3)),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: AppTextStyle.caption
                  .copyWith(color: context.colorScheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _mvpRow(BuildContext context, int index, MvpRow row, double max) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        border: index == 0
            ? null
            : Border(top: BorderSide(color: cs.outline, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 24,
            child: Text(
              '${index + 1}',
              style: AppTextStyle.subtitle3.copyWith(
                color: index < 3 ? cs.primary : cs.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          PlayerAvatar(row.player),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${row.player.user.name ?? ''}  ·  ${teamShortName(row.player.team)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subtitle3.copyWith(
                      color: cs.textPrimary, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                LayoutBuilder(builder: (context, constraints) {
                  final width = constraints.maxWidth * row.total / max;
                  final segments = [
                    (row.batting, cs.primary),
                    (row.bowling, cs.textPrimary),
                    (row.fielding, cs.textDisabled),
                  ].where((s) => s.$1 > 0).toList();
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: GrowIn(
                      delay: AppStagger.of(index),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final (value, color) in segments)
                              Container(
                                width: width * value / row.total,
                                height: 6,
                                color: color,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 4),
                Text(
                  '${row.batting} · ${row.bowling} · ${row.fielding}',
                  style: AppTextStyle.caption.copyWith(color: cs.textDisabled),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          CountUp(
            value: row.total,
            style: AppTextStyle.subtitle1
                .copyWith(color: cs.primary, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
