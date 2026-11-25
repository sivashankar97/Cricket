import 'package:data/api/match/match_model.dart';
import 'package:data/service/pocketbase/pocketbase_match_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/home/components/match_summary.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

/// Broadcast Stadium Hero Live Match Card matching the modern sports reference design:
/// 2-row team scores, BAT badge, run rates, live chase flame banner,
/// this over ball-by-ball indicators, and wide white Scorecard CTA.
class LiveMatchCard extends StatelessWidget {
  static const height = 335.0;

  final MatchModel match;

  const LiveMatchCard({super.key, required this.match});

  static const _white = textPrimaryDarkColor;

  @override
  Widget build(BuildContext context) {
    final summary = MatchSummary.of(match);

    // Chasing/batting team on top row, defending on second row
    final team1 = summary.batting ?? summary.second;
    final team2 = match.teams.firstWhere(
      (t) => t.team_id != team1.team_id,
      orElse: () => summary.first,
    );

    return OnTapScale(
      onTap: () {
        if (PocketBaseMatchService.isPocketBaseMatchId(match.id)) {
          // Scoreboard/detail for PocketBase matches lands in the next slice.
          Fluttertoast.showToast(
            msg: 'PocketBase live match — scoring screen coming next',
          );
          return;
        }
        AppRoute.matchDetailTab(matchId: match.id).push(context);
      },
      child: MediaQuery.withNoTextScaling(
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0B0E23),
                Color(0xFF141738),
                Color(0xFF220B13),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: brandRedColor.withValues(alpha: 0.3),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
          child: Stack(
            children: [
              _glow(top: -60, right: -40, size: 170),
              _glow(bottom: -70, left: -50, size: 150),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _header(context),
                    const SizedBox(height: 14),
                    _teamRow(context, summary, team1, isBatting: true),
                    const SizedBox(height: 10),
                    _teamRow(context, summary, team2, isBatting: false),
                    const Spacer(),
                    _chaseBanner(context, summary),
                    const SizedBox(height: 10),
                    _thisOverRow(context),
                    const SizedBox(height: 12),
                    _scorecardButton(context),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _glow({
    double? top,
    double? right,
    double? bottom,
    double? left,
    required double size,
  }) {
    return Positioned(
      top: top,
      right: right,
      bottom: bottom,
      left: left,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _white.withValues(alpha: 0.05),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final oversText = context.l10n.home_match_overs(match.number_of_over);
    final groundText = match.ground.trim();

    return Row(
      children: [
        const LiveBadge(),
        const SizedBox(width: 8),
        Text(
          oversText,
          style: AppTextStyle.caption.copyWith(
            color: const Color(0xFF94A3B8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        if (groundText.isNotEmpty)
          Flexible(
            child: Text(
              groundText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: AppTextStyle.caption.copyWith(
                color: const Color(0xFF94A3B8),
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _teamRow(
    BuildContext context,
    MatchSummary summary,
    MatchTeamModel team, {
    required bool isBatting,
  }) {
    final opponent = match.teams.firstWhere(
      (t) => t.team_id != team.team_id,
      orElse: () => team,
    );
    final hasScore = team.over > 0 || isBatting;

    return Row(
      children: [
        // Circular avatar
        ImageAvatar(
          initial: team.team.name_initial ?? team.team.name.initials(limit: 2),
          imageUrl: team.team.profile_img_url,
          size: 34,
        ),
        const SizedBox(width: 8),

        // Team name + BAT badge
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  team.team.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.subtitle2.copyWith(
                    color: _white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isBatting) ...[
                const SizedBox(width: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: brandRedColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'BAT',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 8,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(width: 6),

        // Score + Subtitle
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text.rich(
                TextSpan(
                  text: hasScore ? '${team.run}' : '—',
                  style: AppTextStyle.header3.copyWith(
                    color: _white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                    height: 1.1,
                  ),
                  children: [
                    if (hasScore)
                      TextSpan(
                        text: '/${opponent.wicket}',
                        style: TextStyle(
                          color: isBatting
                              ? brandRedColor
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 2),
              if (isBatting &&
                  (summary.currentRate != null || summary.requiredRate != null))
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (summary.currentRate != null) ...[
                        Text(
                          context.l10n
                              .home_crr(summary.currentRate!.toStringAsFixed(2)),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (summary.requiredRate != null)
                          const Text(
                            ' • ',
                            style: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 10,
                            ),
                          ),
                      ],
                      if (summary.requiredRate != null)
                        Text(
                          context.l10n
                              .home_rrr(summary.requiredRate!.toStringAsFixed(2)),
                          style: const TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                )
              else
                Text(
                  hasScore ? '${team.over} ov' : '',
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _chaseBanner(BuildContext context, MatchSummary summary) {
    final isChasing = summary.isChasing;
    final batting = summary.batting;
    final tossWinner = match.teams
        .where((t) => t.team_id == match.toss_winner_id)
        .map((t) => t.team.name)
        .firstOrNull;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: isChasing
          ? Row(
              children: [
                const Text('🔥', style: TextStyle(fontSize: 12)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    context.l10n.home_live_need(
                      summary.second.team.name,
                      summary.runsNeeded ?? 0,
                      summary.ballsLeft ?? 0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFD54F),
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (summary.target != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF090C1F),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.15),
                      ),
                    ),
                    child: Text(
                      'Target ${summary.target}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            )
          : Text(
              batting != null
                  ? context.l10n.home_live_batting(batting.team.name)
                  : tossWinner != null
                      ? context.l10n.home_live_toss(tossWinner)
                      : context.l10n.home_live_starting,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyle.caption.copyWith(
                color: _white,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _thisOverRow(BuildContext context) {
    // Placeholder balls were confusing (totals 0/0 while "this over" looked live).
    // Hide until ball-by-ball for the current over is wired from Firestore.
    return const SizedBox.shrink();
  }

  Widget _scorecardButton(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.center,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Scorecard & Commentary',
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 4),
            Icon(
              CupertinoIcons.chevron_right,
              size: 13,
              color: Color(0xFF0F172A),
            ),
          ],
        ),
      ),
    );
  }
}

/// Swipeable row of [LiveMatchCard]s: one per page on phones, about 460 px
/// cards side by side on wider screens.
class LiveMatchCarousel extends StatefulWidget {
  final List<MatchModel> matches;

  const LiveMatchCarousel({super.key, required this.matches});

  @override
  State<LiveMatchCarousel> createState() => _LiveMatchCarouselState();
}

class _LiveMatchCarouselState extends State<LiveMatchCarousel> {
  PageController? _controller;
  double _fraction = 1;
  int _page = 0;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  PageController _controllerFor(double width) {
    final fraction = width > 600 ? (460 / width).clamp(0.3, 1.0) : 1.0;
    if (_controller == null || fraction != _fraction) {
      _controller?.dispose();
      _fraction = fraction;
      _controller = PageController(viewportFraction: fraction);
    }
    return _controller!;
  }

  @override
  Widget build(BuildContext context) {
    final matches = widget.matches;
    return LayoutBuilder(builder: (context, constraints) {
      final controller = _controllerFor(constraints.maxWidth);
      final perScreen = (1 / _fraction).floor().clamp(1, 99);
      final pages = (matches.length - perScreen + 1).clamp(1, matches.length);
      return Column(
        children: [
          SizedBox(
            height: LiveMatchCard.height + 12,
            child: PageView.builder(
              controller: controller,
              padEnds: false,
              itemCount: matches.length,
              onPageChanged: (page) => setState(() => _page = page),
              itemBuilder: (context, index) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: LiveMatchCard(match: matches[index]),
              ),
            ),
          ),
          if (pages > 1) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (var i = 0; i < pages; i++)
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: i == _page ? 18 : 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      color: i == _page
                          ? brandRedColor
                          : brandRedColor.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
          ],
        ],
      );
    });
  }
}

/// Red "LIVE" badge used on cards.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: brandRedColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
