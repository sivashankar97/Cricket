import 'package:cached_network_image/cached_network_image.dart';
import 'package:data/api/tournament/tournament_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_svg/svg.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

import '../../../../components/match_status_tag.dart';
import '../../../../domain/formatter/date_formatter.dart';
import '../../../../gen/assets.gen.dart';

/// iOS-style tournament card for the home screen horizontal list.
///
/// Banner image fills 55% height. Footer has name + status badge + date.
class TournamentItem extends StatelessWidget {
  final TournamentModel tournament;
  final EdgeInsets margin;
  final Size? size;

  const TournamentItem({
    super.key,
    this.size,
    required this.tournament,
    this.margin = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final width = size?.width ?? context.mediaQuerySize.width;
    return OnTapScale(
      onTap: () =>
          AppRoute.tournamentDetail(tournamentId: tournament.id).push(context),
      child: Container(
        height: width * 0.52,
        width: width,
        margin: margin,
        clipBehavior: Clip.antiAlias,
        decoration: context.colorScheme.cardDecoration(radius: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _banner(context, width)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _titleAndStatus(context),
                  const SizedBox(height: 3),
                  _dateAndType(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _banner(BuildContext context, double width) {
    final bannerUrl = tournament.banner_img_url;
    if (bannerUrl == null) {
      return DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [brandNavyCardColor, brandNavyColor],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -24,
              child: Container(
                height: 96,
                width: 96,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: brandRedColor.withValues(alpha: 0.85),
                ),
              ),
            ),
            Center(
              child: SvgPicture.asset(
                Assets.images.icTournaments,
                height: 32,
                width: 32,
                colorFilter: const ColorFilter.mode(
                  textPrimaryDarkColor,
                  BlendMode.srcATop,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: bannerUrl,
      fit: BoxFit.cover,
      width: width,
      errorWidget: (context, url, error) =>
          ColoredBox(color: context.colorScheme.containerLowOnSurface),
    );
  }

  Widget _titleAndStatus(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            tournament.name,
            style: AppTextStyle.subtitle2.copyWith(
              color: context.colorScheme.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            overflow: TextOverflow.ellipsis,
            textScaler: TextScaler.noScaling,
            maxLines: 1,
          ),
        ),
        const SizedBox(width: 12),
        StatusTag(tournamentStatus: tournament.status),
      ],
    );
  }

  Widget _dateAndType(BuildContext context) {
    final color = context.colorScheme.textSecondary;
    return Text.rich(
      overflow: TextOverflow.ellipsis,
      textScaler: TextScaler.noScaling,
      TextSpan(
        text: DateFormatter.formatDateRange(
          context,
          startDate: tournament.start_date,
          endDate: tournament.end_date,
          formatType: DateFormatType.dayMonth,
        ),
        style: AppTextStyle.caption.copyWith(color: color),
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              height: 3,
              width: 3,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            ),
          ),
          TextSpan(text: tournament.type.getString(context)),
        ],
      ),
    );
  }
}
