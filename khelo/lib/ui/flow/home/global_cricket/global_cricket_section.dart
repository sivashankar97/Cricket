import 'package:data/api/global_cricket/global_cricket_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';

import 'global_cricket_providers.dart';
import 'global_cricket_widgets.dart';

/// Home section with international and premier-league scores from
/// CricketData.org: a few key matches per category, the rest in "View all".
/// Hidden until the shared cache has at least one match.
class GlobalCricketSection extends ConsumerStatefulWidget {
  final Widget Function(String title, VoidCallback onViewAll) header;

  const GlobalCricketSection({super.key, required this.header});

  static const maxCards = 6;

  @override
  ConsumerState<GlobalCricketSection> createState() =>
      _GlobalCricketSectionState();
}

class _GlobalCricketSectionState extends ConsumerState<GlobalCricketSection> {
  GlobalMatchCategory? _category;

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(globalCricketFeedProvider).valueOrNull;
    if (feed == null || feed.matches.isEmpty) return const SizedBox.shrink();

    final category = _category ??
        (feed.of(GlobalMatchCategory.international).isNotEmpty
            ? GlobalMatchCategory.international
            : GlobalMatchCategory.league);
    final matches = GlobalCricketFeed.highlights(
      feed.of(category),
      limit: GlobalCricketSection.maxCards,
    );
    final cs = context.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        widget.header(
          context.l10n.home_global_cricket_title,
          () => AppRoute.globalCricket(category: category).push(context),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: GlobalFilterPills<GlobalMatchCategory>(
            options: {
              for (final c in GlobalMatchCategory.values) c: c.label(context),
            },
            selected: category,
            onSelected: (c) => setState(() => _category = c),
          ),
        ),
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              context.l10n.global_cricket_no_matches,
              style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
            ),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final match in matches)
                  SizedBox(
                    height: 180,
                    child: GlobalMatchCard(match: match, width: 280),
                  ),
              ],
            ),
          ),
        if (feed.fetchedAt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Text(
              context.l10n.home_global_cricket_updated(
                feed.fetchedAt!.format(context, DateFormatType.time),
              ),
              style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
            ),
          ),
      ],
    );
  }
}
