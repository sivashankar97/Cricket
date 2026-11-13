import 'package:data/api/global_cricket/global_cricket_models.dart';
import 'package:data/service/global_cricket/global_cricket_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

import 'global_cricket_providers.dart';
import 'global_cricket_widgets.dart';

/// Cricbuzz-style match page for a Global cricket match: score header, then
/// Scorecard (batting / bowling per innings) and Info tabs.
class GlobalMatchScreen extends ConsumerWidget {
  final GlobalMatch match;

  const GlobalMatchScreen({super.key, required this.match});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(globalCricketFeedProvider).valueOrNull;
    final current = feed?.byId(match.id) ?? match;
    final scorecard = ref.watch(globalScorecardProvider(current.id));
    final block = ref.watch(globalScorecardBlockProvider(current));

    return DefaultTabController(
      length: 2,
      initialIndex: current.isUpcoming ? 1 : 0,
      child: AppPage(
        title: '${current.team1.label} vs ${current.team2.label}',
        body: NestedScrollView(
          headerSliverBuilder: (context, _) => [
            SliverToBoxAdapter(child: _ScoreHeader(match: current)),
            SliverToBoxAdapter(
              child: TabBar(
                labelStyle: AppTextStyle.subtitle2
                    .copyWith(fontWeight: FontWeight.w700),
                tabs: [
                  Tab(text: context.l10n.global_cricket_scorecard),
                  Tab(text: context.l10n.global_cricket_info),
                ],
              ),
            ),
          ],
          body: TabBarView(
            children: [
              _ScorecardTab(
                scorecard: scorecard.valueOrNull,
                loading: scorecard.isLoading || block.isLoading,
                block: block.valueOrNull ?? ScorecardBlock.none,
              ),
              _InfoTab(match: current, scorecard: scorecard.valueOrNull),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  final GlobalMatch match;

  const _ScoreHeader({required this.match});

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandNavyCardColor, brandNavyColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: cs.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (match.isLive) ...[
                const GlobalLiveBadge(),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  [
                    if (match.matchType.isNotEmpty)
                      match.matchType.toUpperCase(),
                    match.series,
                  ].join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.caption
                      .copyWith(color: textSecondaryDarkColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _team(match.team1, match.score1),
          const SizedBox(height: 10),
          _team(match.team2, match.score2),
          const SizedBox(height: 14),
          Text(
            match.statusText(context),
            style: AppTextStyle.subtitle3.copyWith(
              color: match.isLive ? const Color(0xFFFF8A8E) : Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _team(GlobalTeam team, String score) => Row(
        children: [
          GlobalTeamFlag(team: team, size: 34),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              team.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subtitle1.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            score,
            style: AppTextStyle.header4.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _ScorecardTab extends StatelessWidget {
  final GlobalScorecard? scorecard;
  final bool loading;
  final ScorecardBlock block;

  const _ScorecardTab({
    required this.scorecard,
    required this.loading,
    required this.block,
  });

  @override
  Widget build(BuildContext context) {
    final card = scorecard;
    if (card == null || card.innings.isEmpty) {
      if (loading) return const SkeletonDetail();
      return _message(
          context,
          switch (block) {
            ScorecardBlock.notStarted =>
              context.l10n.global_cricket_scorecard_not_started,
            ScorecardBlock.signedOut =>
              context.l10n.global_cricket_scorecard_sign_in,
            ScorecardBlock.dailyLimit ||
            ScorecardBlock.none =>
              context.l10n.global_cricket_scorecard_limit,
          });
    }

    final cs = context.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        for (var i = 0; i < card.innings.length; i++)
          _InningsCard(
            innings: card.innings[i],
            total: card.totalFor(card.innings[i].title),
            initiallyExpanded: i == card.innings.length - 1,
          ),
        if (card.fetchedAt != null)
          Text(
            context.l10n.global_cricket_scorecard_updated(
              card.fetchedAt!.format(context, DateFormatType.time),
            ),
            style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
          ),
      ],
    );
  }

  Widget _message(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: AppTextStyle.body2
              .copyWith(color: context.colorScheme.textSecondary),
        ),
      );
}

class _InningsCard extends StatefulWidget {
  final GlobalInnings innings;
  final String total;
  final bool initiallyExpanded;

  const _InningsCard({
    required this.innings,
    required this.total,
    required this.initiallyExpanded,
  });

  @override
  State<_InningsCard> createState() => _InningsCardState();
}

class _InningsCardState extends State<_InningsCard> {
  late bool _expanded = widget.initiallyExpanded;

  static const _statWidth = 38.0;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final innings = widget.innings;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: cs.cardDecoration(radius: 16),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Container(
              color: brandNavyColor,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      innings.title.replaceFirst('Inning ', 'Innings '),
                      style: AppTextStyle.subtitle2.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Text(
                    widget.total,
                    style: AppTextStyle.subtitle2.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _expanded
                        ? CupertinoIcons.chevron_up
                        : CupertinoIcons.chevron_down,
                    size: 16,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            _headerRow(
              context,
              context.l10n.global_cricket_batter,
              const ['R', 'B', '4s', '6s', 'SR'],
            ),
            for (final batter in innings.batting) _batterRow(context, batter),
            if (innings.bowling.isNotEmpty)
              _headerRow(
                context,
                context.l10n.global_cricket_bowler,
                const ['O', 'M', 'R', 'W', 'ER'],
              ),
            for (final bowler in innings.bowling) _bowlerRow(context, bowler),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  Widget _headerRow(BuildContext context, String title, List<String> stats) {
    final cs = context.colorScheme;
    final style = AppTextStyle.caption.copyWith(
      color: cs.textSecondary,
      fontWeight: FontWeight.w700,
    );
    return Container(
      color: cs.containerLowOnSurface,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Text(title, style: style)),
          for (final stat in stats)
            SizedBox(
              width: _statWidth,
              child: Text(stat, textAlign: TextAlign.end, style: style),
            ),
        ],
      ),
    );
  }

  Widget _statsRow(
    BuildContext context, {
    required String name,
    String? subtitle,
    required List<String> stats,
    int boldIndex = 0,
  }) {
    final cs = context.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: cs.outline, width: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyle.subtitle3.copyWith(
                    color: cs.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null && subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: AppTextStyle.caption
                        .copyWith(color: cs.textSecondary, fontSize: 11),
                  ),
              ],
            ),
          ),
          for (var i = 0; i < stats.length; i++)
            SizedBox(
              width: _statWidth,
              child: Text(
                stats[i],
                textAlign: TextAlign.end,
                style: AppTextStyle.subtitle3.copyWith(
                  color: cs.textPrimary,
                  fontWeight:
                      i == boldIndex ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _batterRow(BuildContext context, GlobalBatter batter) => _statsRow(
        context,
        name: batter.name,
        subtitle: batter.dismissal.isEmpty
            ? context.l10n.global_cricket_batting
            : batter.dismissal,
        stats: [
          '${batter.runs}',
          '${batter.balls}',
          '${batter.fours}',
          '${batter.sixes}',
          batter.strikeRate.toStringAsFixed(1),
        ],
      );

  Widget _bowlerRow(BuildContext context, GlobalBowler bowler) => _statsRow(
        context,
        name: bowler.name,
        stats: [
          bowler.oversText,
          '${bowler.maidens}',
          '${bowler.runs}',
          '${bowler.wickets}',
          bowler.economy.toStringAsFixed(1),
        ],
        boldIndex: 3,
      );
}

class _InfoTab extends StatelessWidget {
  final GlobalMatch match;
  final GlobalScorecard? scorecard;

  const _InfoTab({required this.match, required this.scorecard});

  @override
  Widget build(BuildContext context) {
    final card = scorecard;
    final start = card?.startTime ?? match.startTime;
    final toss = card == null || card.tossWinner.isEmpty
        ? ''
        : context.l10n.global_cricket_toss_text(
            _titleCase(card.tossWinner),
            card.tossChoice,
          );
    final rows = <(String, String)>[
      (
        context.l10n.global_cricket_info_match,
        card?.name.isNotEmpty == true ? card!.name : match.title,
      ),
      (context.l10n.global_cricket_info_series, match.series),
      if (match.matchType.isNotEmpty)
        (
          context.l10n.global_cricket_info_format,
          match.matchType.toUpperCase()
        ),
      if (start != null)
        (
          context.l10n.global_cricket_info_date,
          start.format(context, DateFormatType.dateAndTime),
        ),
      if (card != null && card.venue.isNotEmpty)
        (context.l10n.global_cricket_info_venue, card.venue),
      if (toss.isNotEmpty) (context.l10n.global_cricket_info_toss, toss),
    ];

    final cs = context.colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        Container(
          decoration: cs.cardDecoration(radius: 16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            children: [
              for (final (label, value) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          label,
                          style: AppTextStyle.subtitle3
                              .copyWith(color: cs.textSecondary),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          value,
                          style: AppTextStyle.subtitle3.copyWith(
                            color: cs.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static String _titleCase(String text) => text
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}
