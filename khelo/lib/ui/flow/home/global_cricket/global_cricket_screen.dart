import 'package:data/api/global_cricket/global_cricket_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/error_screen.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/shimmer.dart';
import 'package:style/text/app_text_style.dart';

import 'global_cricket_providers.dart';
import 'global_cricket_widgets.dart';

/// "View all" for Global cricket: International / Premier leagues tabs, each
/// filtered to Live, Recent or Upcoming and grouped by series.
class GlobalCricketScreen extends ConsumerWidget {
  final GlobalMatchCategory initialCategory;

  const GlobalCricketScreen({
    super.key,
    this.initialCategory = GlobalMatchCategory.international,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feed = ref.watch(globalCricketFeedProvider);
    return DefaultTabController(
      length: GlobalMatchCategory.values.length,
      initialIndex: initialCategory.index,
      child: AppPage(
        title: context.l10n.home_global_cricket_title,
        body: Column(
          children: [
            TabBar(
              labelStyle:
                  AppTextStyle.subtitle2.copyWith(fontWeight: FontWeight.w700),
              tabs: [
                for (final c in GlobalMatchCategory.values)
                  Tab(text: c.label(context)),
              ],
            ),
            Expanded(
              child: feed.when(
                loading: () => const SkeletonCards(),
                error: (error, _) => ErrorScreen(
                  error: error,
                  onRetryTap: () => ref.invalidate(globalCricketFeedProvider),
                ),
                data: (feed) => TabBarView(
                  children: [
                    for (final c in GlobalMatchCategory.values)
                      _CategoryList(
                        matches: feed.of(c),
                        fetchedAt: feed.fetchedAt,
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
}

enum _Filter { live, recent, upcoming }

class _CategoryList extends StatefulWidget {
  final List<GlobalMatch> matches;
  final DateTime? fetchedAt;

  const _CategoryList({required this.matches, required this.fetchedAt});

  @override
  State<_CategoryList> createState() => _CategoryListState();
}

class _CategoryListState extends State<_CategoryList>
    with AutomaticKeepAliveClientMixin {
  _Filter? _filter;

  @override
  bool get wantKeepAlive => true;

  bool _matches(GlobalMatch m, _Filter filter) => switch (filter) {
        _Filter.live => m.isLive,
        _Filter.recent => m.isResult,
        _Filter.upcoming => m.isUpcoming,
      };

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = context.colorScheme;
    final filter = _filter ??
        _Filter.values.firstWhere(
          (f) => widget.matches.any((m) => _matches(m, f)),
          orElse: () => _Filter.recent,
        );
    final shown = GlobalCricketFeed.sortForDisplay(
      widget.matches.where((m) => _matches(m, filter)),
    );
    final bySeries = <String, List<GlobalMatch>>{};
    for (final match in shown) {
      bySeries.putIfAbsent(match.series, () => []).add(match);
    }

    return ListView(
      padding:
          context.mediaQueryPadding + const EdgeInsets.fromLTRB(10, 12, 10, 24),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: GlobalFilterPills<_Filter>(
            options: {
              _Filter.live: context.l10n.global_cricket_live,
              _Filter.recent: context.l10n.global_cricket_recent,
              _Filter.upcoming: context.l10n.global_cricket_upcoming,
            },
            selected: filter,
            onSelected: (f) => setState(() => _filter = f),
          ),
        ),
        if (shown.isEmpty)
          Padding(
            padding: const EdgeInsets.all(32),
            child: Text(
              context.l10n.global_cricket_no_matches,
              textAlign: TextAlign.center,
              style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
            ),
          ),
        for (final entry in bySeries.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 18, 6, 6),
            child: Text(
              entry.key,
              style: AppTextStyle.subtitle1.copyWith(
                color: cs.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          for (final match in entry.value) GlobalMatchCard(match: match),
        ],
        if (widget.fetchedAt != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 16, 6, 0),
            child: Text(
              context.l10n.home_global_cricket_updated(
                widget.fetchedAt!.format(context, DateFormatType.time),
              ),
              style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
            ),
          ),
      ],
    );
  }
}
