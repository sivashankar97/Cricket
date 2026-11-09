import 'package:data/api/match/match_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:khelo/components/image_avatar.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/string_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/home/components/match_summary.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

/// Big red hero card for a running match: both teams, the chase and the
/// run rates.
class LiveMatchCard extends StatelessWidget {
  static const height = 268.0;

  final MatchModel match;

  const LiveMatchCard({super.key, required this.match});

  static const _white = textPrimaryDarkColor;
  static const _soft = textSecondaryDarkColor;

  @override
  Widget build(BuildContext context) {
    final summary = MatchSummary.of(match);
    return OnTapScale(
      onTap: () => AppRoute.matchDetailTab(matchId: match.id).push(context),
      child: MediaQuery.withNoTextScaling(
        child: Container(
          height: height,
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            gradient: liveCardGradient,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: brandRedColor.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
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
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _team(context, summary, summary.first)),
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: _vs(),
                        ),
                        Expanded(
                          child: _team(context, summary, summary.second,
                              end: true),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _status(context, summary),
                    const SizedBox(height: 10),
                    _rates(context, summary),
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
          color: _white.withValues(alpha: 0.07),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        LiveBadge(),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            [
              context.l10n.home_match_overs(match.number_of_over),
              if (match.ground.trim().isNotEmpty) match.ground.trim(),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyle.caption.copyWith(color: _soft),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: _white,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            CupertinoIcons.arrow_up_right,
            size: 15,
            color: brandRedDeepColor,
          ),
        ),
      ],
    );
  }

  Widget _team(
    BuildContext context,
    MatchSummary summary,
    MatchTeamModel team, {
    bool end = false,
  }) {
    final opponent = match.teams.firstWhere(
      (t) => t.team_id != team.team_id,
      orElse: () => team,
    );
    final batting = summary.batting?.team_id == team.team_id;
    final hasScore = team.over > 0 || batting;
    final align = end ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: align,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _white, width: 2),
              ),
              child: ImageAvatar(
                initial:
                    team.team.name_initial ?? team.team.name.initials(limit: 1),
                imageUrl: team.team.profile_img_url,
                size: 40,
              ),
            ),
            if (batting)
              Positioned(
                right: end ? null : -2,
                left: end ? -2 : null,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: _white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    CupertinoIcons.sportscourt_fill,
                    size: 10,
                    color: brandRedDeepColor,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          team.team.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: end ? TextAlign.end : TextAlign.start,
          style: AppTextStyle.subtitle3.copyWith(
            color: _white,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: end ? Alignment.centerRight : Alignment.centerLeft,
          child: Text.rich(
            TextSpan(
              text: hasScore ? '${team.run}/${opponent.wicket}' : '—',
              style: AppTextStyle.header2.copyWith(
                color: _white,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
              children: [
                if (hasScore)
                  TextSpan(
                    text: '  (${team.over})',
                    style: AppTextStyle.caption.copyWith(color: _soft),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _vs() {
    return Container(
      width: 34,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _white.withValues(alpha: 0.18),
        border: Border.all(color: _white.withValues(alpha: 0.35)),
      ),
      child: Text(
        'VS',
        style: AppTextStyle.caption.copyWith(
          color: _white,
          fontWeight: FontWeight.w800,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _status(BuildContext context, MatchSummary summary) {
    final batting = summary.batting;
    final tossWinner = match.teams
        .where((t) => t.team_id == match.toss_winner_id)
        .map((t) => t.team.name)
        .firstOrNull;
    final text = summary.isChasing
        ? context.l10n.home_live_need(
            summary.second.team.name,
            summary.runsNeeded ?? 0,
            summary.ballsLeft ?? 0,
          )
        : batting != null
            ? context.l10n.home_live_batting(batting.team.name)
            : tossWinner != null
                ? context.l10n.home_live_toss(tossWinner)
                : context.l10n.home_live_starting;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: _white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: AppTextStyle.subtitle3.copyWith(
          color: _white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _rates(BuildContext context, MatchSummary summary) {
    final pills = [
      if (summary.currentRate != null)
        context.l10n.home_crr(summary.currentRate!.toStringAsFixed(2)),
      if (summary.requiredRate != null)
        context.l10n.home_rrr(summary.requiredRate!.toStringAsFixed(2)),
      if (summary.target != null)
        context.l10n.home_live_target(summary.target!),
    ];
    if (pills.isEmpty) return const SizedBox(height: 24);
    return SizedBox(
      height: 24,
      child: Row(
        children: [
          for (final pill in pills)
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: brandNavyColor.withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  pill,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.caption.copyWith(
                    color: _white,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
        ],
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

/// White "● LIVE" pill used on red cards.
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: textPrimaryDarkColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 6,
            width: 6,
            decoration: const BoxDecoration(
              color: brandRedColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            context.l10n.home_screen_live_title.toUpperCase(),
            style: AppTextStyle.caption.copyWith(
              color: brandRedDeepColor,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
