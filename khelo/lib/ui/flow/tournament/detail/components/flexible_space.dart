import 'package:data/api/match/match_model.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:style/animations/fade_slide_in.dart';
import 'package:style/animations/motion.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';

import '../../../../../components/app_image_provider.dart';
import '../../../../../components/image_avatar.dart';
import 'tournament_widgets.dart';

/// Tournament hero: cover, logo, name, format, dates, status and stat tiles.
class FlexibleSpace extends StatefulWidget {
  static const expandedHeight = 392.0;

  final TournamentModel tournament;
  final List<MatchModel> matches;

  const FlexibleSpace({
    super.key,
    required this.tournament,
    required this.matches,
  });

  @override
  State<FlexibleSpace> createState() => _FlexibleSpaceState();
}

class _FlexibleSpaceState extends State<FlexibleSpace> {
  String? _bannerUrl;
  ImageProvider? _banner;

  ImageProvider? get banner {
    final url = widget.tournament.banner_img_url;
    if (url != _bannerUrl) {
      _bannerUrl = url;
      _banner = url == null ? null : appImageProvider(url);
    }
    return _banner;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final isCollapsed = constraints.biggest.height < 150;
      return FlexibleSpaceBar(
        centerTitle: true,
        title: AnimatedOpacity(
          opacity: isCollapsed ? 1 : 0,
          duration: const Duration(milliseconds: 150),
          child: Padding(
            padding: const EdgeInsets.only(left: 64, right: 84),
            child: Text(
              widget.tournament.name,
              style: AppTextStyle.header2.copyWith(color: Colors.white),
              overflow: TextOverflow.ellipsis,
              textScaler: TextScaler.noScaling,
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            _cover(),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x66010127), Color(0xF2010127)],
                  stops: [0, 0.62],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: AnimatedOpacity(
                opacity: isCollapsed ? 0 : 1,
                duration: const Duration(milliseconds: 150),
                child: MediaQuery.withNoTextScaling(child: _details(context)),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _cover() {
    final image = banner;
    if (image == null) {
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brandNavyColor, Color(0xFF12124A)],
          ),
        ),
        alignment: const Alignment(0.7, -0.4),
        child: Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: brandRedColor.withValues(alpha: 0.35),
          ),
        ),
      );
    }
    return FadeSlideIn(
      child: Image(image: image, fit: BoxFit.cover, gaplessPlayback: true),
    );
  }

  Widget _details(BuildContext context) {
    final t = widget.tournament;
    final status = t.getTournamentStatus(widget.matches);
    final played = widget.matches
        .where((m) =>
            m.match_status == MatchStatus.finish ||
            m.match_status == MatchStatus.abandoned)
        .length;
    final players =
        t.teams.fold<int>(0, (sum, team) => sum + team.players.length);
    final white70 = Colors.white.withValues(alpha: 0.72);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        FadeSlideIn(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              ImageAvatar(
                initial: t.name.characters.first.toUpperCase(),
                imageUrl: t.profile_img_url,
                size: 68,
                border: Border.all(color: Colors.white, width: 2),
                backgroundColor: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusPill(
                      status.getString(context),
                      color: status == TournamentStatus.finish
                          ? Colors.white
                          : brandRedColor,
                      dot: status == TournamentStatus.running,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      t.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyle.header1.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FadeSlideIn(
          delay: AppStagger.of(1),
          child: Text(
            '${t.type.getString(context)}  ·  ${DateFormatter.formatDateRange(
              context,
              startDate: t.start_date,
              endDate: t.end_date,
              formatType: DateFormatType.dayMonth,
            )}',
            style: AppTextStyle.body2.copyWith(color: white70),
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            _tile(context, 2, context.l10n.common_teams_title,
                CountUp(value: t.teams.length, style: _tileValue)),
            const SizedBox(width: 8),
            _tile(
              context,
              3,
              context.l10n.tournament_stat_matches_played,
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  CountUp(value: played, style: _tileValue),
                  Text(' / ${widget.matches.length}',
                      style: AppTextStyle.caption.copyWith(color: white70)),
                ],
              ),
              progress: widget.matches.isEmpty
                  ? null
                  : played / widget.matches.length,
            ),
            const SizedBox(width: 8),
            _tile(context, 4, context.l10n.tournament_stat_players,
                CountUp(value: players, style: _tileValue)),
          ],
        ),
      ],
    );
  }

  static final _tileValue =
      AppTextStyle.header3.copyWith(color: Colors.white, height: 1.1);

  Widget _tile(
    BuildContext context,
    int index,
    String label,
    Widget value, {
    double? progress,
  }) {
    return Expanded(
      child: FadeSlideIn(
        delay: AppStagger.of(index),
        child: Container(
          height: 74,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyle.caption.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 10,
                  letterSpacing: 0.6,
                  fontWeight: FontWeight.w600,
                ),
              ),
              value,
              if (progress != null)
                GrowBar(
                  fraction: progress,
                  color: brandRedColor,
                  trackColor: Colors.white.withValues(alpha: 0.15),
                  height: 4,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
