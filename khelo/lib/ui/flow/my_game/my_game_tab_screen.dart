import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:khelo/components/app_page.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/ui/app_route.dart';
import 'package:khelo/ui/flow/matches/match_list_screen.dart';
import 'package:khelo/ui/flow/my_game/my_game_tab_view_model.dart';
import 'package:khelo/ui/flow/team/team_list_screen.dart';
import 'package:khelo/ui/flow/team/team_list_view_model.dart';
import 'package:khelo/ui/flow/tournament/tournament_list_screen.dart';
import 'package:style/animations/app_animations.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

class MyGameTabScreen extends ConsumerStatefulWidget {
  const MyGameTabScreen({super.key});

  @override
  ConsumerState createState() => _MyGameTabScreenState();
}

class _MyGameTabScreenState extends ConsumerState<MyGameTabScreen>
    with WidgetsBindingObserver {
  final List<Widget> _tabs = [
    const MatchListScreen(),
    const TeamListScreen(),
    const TournamentListScreen(),
  ];

  late PageController _controller;

  int get _selectedTab => _controller.hasClients
      ? _controller.page?.round() ?? 0
      : _controller.initialPage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = PageController(
      initialPage: ref.read(myGameTabViewStateProvider).selectedTab,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // deallocate resources
      _controller.dispose();
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(myGameTabViewStateProvider.notifier);

    return AppPage(
      body: Builder(
        builder: (context) {
          return _content(context, notifier);
        },
      ),
    );
  }

  Widget _content(BuildContext context, MyGameTabViewNotifier notifier) {
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: Column(
            children: [
              _header(context),
              _segmentedControl(context),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (tab) {
                    notifier.onTabChange(tab);
                    setState(() {});
                  },
                  children: _tabs,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final cs = context.colorScheme;
    final showFilter = _selectedTab == 1 &&
        ref.watch(teamListViewStateProvider).teams.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.my_cricket_screen_title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.header1.copyWith(
                    color: cs.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  context.l10n.my_cricket_header_subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyle.caption.copyWith(color: cs.textSecondary),
                ),
              ],
            ),
          ),
          if (showFilter) ...[
            _circleButton(
              icon: CupertinoIcons.slider_horizontal_3,
              background: cs.surface,
              foreground: cs.textPrimary,
              onTap: () => ref
                  .read(teamListViewStateProvider.notifier)
                  .onFilterButtonTap(),
            ),
            const SizedBox(width: 10),
          ],
          _circleButton(
            icon: CupertinoIcons.add,
            background: brandRedColor,
            foreground: Colors.white,
            onTap: () {
              final actions = [
                AppRoute.addMatch(),
                AppRoute.addTeam(),
                AppRoute.addTournament(),
              ];
              actions[_selectedTab].push(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color background,
    required Color foreground,
    required VoidCallback onTap,
  }) {
    return OnTapScale(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          boxShadow: context.colorScheme.cardShadow,
        ),
        child: Icon(icon, size: 20, color: foreground),
      ),
    );
  }

  Widget _segmentedControl(BuildContext context) {
    final cs = context.colorScheme;
    final labels = [
      context.l10n.common_matches_title,
      context.l10n.common_teams_title,
      context.l10n.common_tournaments,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        height: 38,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: cs.containerNormal,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            AnimatedAlign(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              alignment: Alignment(-1 + _selectedTab.toDouble(), 0),
              child: FractionallySizedBox(
                widthFactor: 1 / labels.length,
                heightFactor: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: cs.surface,
                    borderRadius: BorderRadius.circular(9),
                    boxShadow: cs.cardShadow,
                  ),
                ),
              ),
            ),
            Row(
              children: [
                for (var i = 0; i < labels.length; i++)
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        _controller.animateToTab(i);
                        setState(() {});
                      },
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            labels[i],
                            maxLines: 1,
                            style: AppTextStyle.subtitle3.copyWith(
                              color: _selectedTab == i
                                  ? cs.textPrimary
                                  : cs.textSecondary,
                              fontWeight: _selectedTab == i
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
