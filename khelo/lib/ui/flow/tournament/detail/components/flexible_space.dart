import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

import '../../../../../components/image_avatar.dart';
import '../../../../../gen/assets.gen.dart';

class FlexibleSpace extends StatefulWidget {
  final TournamentModel tournament;

  const FlexibleSpace({
    super.key,
    required this.tournament,
  });

  @override
  State<FlexibleSpace> createState() => _FlexibleSpaceState();
}

class _FlexibleSpaceState extends State<FlexibleSpace> {
  @override
  Widget build(BuildContext context) {
    final hasBanner = widget.tournament.banner_img_url != null;

    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      final isCollapsed = constraints.biggest.height < 150;

      return FlexibleSpaceBar(
        centerTitle: true,
        title: isCollapsed
            ? AnimatedOpacity(
                opacity: isCollapsed ? 1 : 0,
                duration: const Duration(milliseconds: 100),
                child: Padding(
                  padding: const EdgeInsets.only(left: 64, right: 84),
                  child: Text(
                    widget.tournament.name,
                    style: AppTextStyle.header2.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                    textScaler: TextScaler.noScaling,
                  ),
                ),
              )
            : null,
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                color: context.colorScheme.primary,
                image: (widget.tournament.banner_img_url != null)
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(
                            widget.tournament.banner_img_url ?? ''),
                        fit: BoxFit.fill,
                      )
                    : null,
              ),
              child: (widget.tournament.banner_img_url == null)
                  ? Center(
                      child: SvgPicture.asset(
                        Assets.images.icTournaments,
                        height: 40,
                        width: 40,
                        colorFilter: ColorFilter.mode(
                          context.colorScheme.onPrimary,
                          BlendMode.srcIn,
                        ),
                      ),
                    )
                  : null,
            ),
            if (hasBanner)
              Container(color: Colors.black.withValues(alpha: 0.4)),
            Positioned(
              left: 16,
              bottom: 24,
              child: AnimatedOpacity(
                opacity: isCollapsed ? 0 : 1,
                duration: const Duration(milliseconds: 100),
                child: _profileView(context, widget.tournament),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _profileView(BuildContext context, TournamentModel tournament) {
    final (title, subtitle) = getTextColors();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ImageAvatar(
          initial: tournament.name.characters.first.toUpperCase(),
          size: 80,
          imageUrl: tournament.profile_img_url,
          border: Border.all(
            color: context.colorScheme.outline,
            width: 1.5,
          ),
          backgroundColor: context.colorScheme.onPrimary,
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: context.mediaQuerySize.width - 32,
          child: Text(
            tournament.name,
            style: AppTextStyle.header1.copyWith(
              color: title,
            ),
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            maxLines: 2,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            SvgPicture.asset(
              Assets.images.icCalendar,
              height: 24,
              width: 24,
              colorFilter: ColorFilter.mode(
                subtitle,
                BlendMode.srcIn,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.tournament_detail_start_from_title(tournament
                  .start_date
                  .format(context, DateFormatType.dayMonth)),
              style: AppTextStyle.body1.copyWith(
                color: subtitle,
              ),
            ),
          ],
        )
      ],
    );
  }

  (Color, Color) getTextColors() =>
      (Colors.white, Colors.white.withValues(alpha: 0.86));
}
