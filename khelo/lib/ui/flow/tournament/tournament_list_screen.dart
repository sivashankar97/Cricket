import 'package:data/api/tournament/tournament_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_image_provider.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/components/grouped_list.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/domain/extensions/enum_extensions.dart';
import 'package:khelo/domain/formatter/date_formatter.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/tournament/tournament_list_view_model.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/indicator/progress_indicator.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

import '../../../components/error_screen.dart';
import 'components/sliver_header_delegate.dart';

class TournamentListScreen extends ConsumerStatefulWidget {
  const TournamentListScreen({super.key});

  @override
  ConsumerState<TournamentListScreen> createState() =>
      _TournamentListScreenState();
}

class _TournamentListScreenState extends ConsumerState<TournamentListScreen>
    with WidgetsBindingObserver {
  late TournamentListViewNotifier notifier;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
    notifier = ref.read(tournamentListViewStateProvider.notifier);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // deallocate resources
      notifier.dispose();
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppPage(
      body: Builder(
        builder: (context) => _body(context),
      ),
    );
  }

  Widget _body(BuildContext context) {
    final state = ref.watch(tournamentListViewStateProvider);
    if (state.loading) {
      return const Center(child: AppProgressIndicator());
    }
    if (state.error != null) {
      return ErrorScreen(
        error: state.error,
        onRetryTap: notifier.loadTournaments,
      );
    }
    if (state.groupTournaments.isEmpty) {
      return BrandEmptyState(
        icon: CupertinoIcons.rosette,
        title: context.l10n.tournament_list_empty_list_title,
        description: context.l10n.my_cricket_empty_tournaments_body,
        buttonTitle: context.l10n.home_screen_create_tournament_btn,
        onTap: () => AppRoute.addTournament().push(context),
      );
    }

    return _content(context, state);
  }

  Widget _content(BuildContext context, TournamentListViewState state) {
    return CustomScrollView(
      slivers: [
        ..._tournaments(context, state),
        SliverToBoxAdapter(
          child: SizedBox(height: 120 + context.mediaQueryPadding.bottom),
        ),
      ],
    );
  }

  List<Widget> _tournaments(
      BuildContext context, TournamentListViewState state) {
    return List.generate(state.groupTournaments.length, (bookingIndex) {
      final DateTime key = state.groupTournaments.keys.elementAt(bookingIndex);
      final List<TournamentModel> tournaments = state.groupTournaments[key]!;
      return SliverMainAxisGroup(
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: SliverPersistentDelegate(
              size: 44,
              child: SizedBox.expand(
                child: ColoredBox(
                  color: context.colorScheme.groupedBackground,
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: MediaQuery.withNoTextScaling(
                      child: SectionCaption(
                        key.format(context, DateFormatType.monthYear),
                        padding: const EdgeInsets.fromLTRB(32, 0, 32, 6),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverList.builder(
            itemBuilder: (BuildContext context, int index) {
              final tournament = tournaments[index];
              return _tournamentItem(context, tournament);
            },
            itemCount: tournaments.length,
          ),
        ],
      );
    });
  }

  Widget _tournamentItem(BuildContext context, TournamentModel tournament) {
    final cs = context.colorScheme;
    return OnTapScale(
      onTap: () =>
          AppRoute.tournamentDetail(tournamentId: tournament.id).push(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        decoration: cs.cardDecoration(radius: 18),
        child: Row(
          children: [
            _profileImage(tournament.profile_img_url),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tournament.name,
                    style: AppTextStyle.subtitle1.copyWith(
                      color: cs.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      InfoChip(
                        DateFormatter.formatDateRange(
                          context,
                          startDate: tournament.start_date,
                          endDate: tournament.end_date,
                          formatType: DateFormatType.dayMonth,
                        ),
                        icon: CupertinoIcons.calendar,
                      ),
                      InfoChip(
                        context.l10n.tournament_list_match_title(
                            tournament.match_ids.length),
                        icon: CupertinoIcons.sportscourt,
                      ),
                      InfoChip(
                        tournament.type.getString(context),
                        color: brandRedColor,
                        background: brandRedColor.withValues(alpha: 0.1),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              CupertinoIcons.chevron_forward,
              size: 15,
              color: cs.textDisabled,
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileImage(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return const BrandIconThumb(CupertinoIcons.rosette);
    }
    return Container(
      height: 64,
      width: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        image: DecorationImage(
          image: appImageProvider(imageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
