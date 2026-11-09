import 'package:data/service/auth/auth_service.dart';
import 'package:data/service/device/device_service.dart';
import 'package:data/storage/app_preferences.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:khelo/domain/extensions/context_extensions.dart';
import 'package:khelo/components/sign_in_required_view.dart';
import 'package:khelo/gen/assets.gen.dart';
import 'package:khelo/ui/flow/app_links/app_links_handler.dart';
import 'package:khelo/ui/flow/my_game/my_game_tab_screen.dart';
import 'package:khelo/ui/flow/play/play_screen.dart';
import 'package:khelo/ui/flow/profile/profile_screen.dart';
import 'package:khelo/ui/flow/auction/auction_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:style/animations/fade_indexed_stack.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/platform.dart';
import 'package:style/navigation/bottom_navigation_bar.dart';

import '../../../domain/extensions/widget_extension.dart';
import '../home/home_screen.dart';
import '../notification/notification_permission_bottom_sheet.dart';
import 'main_screen_state_notifier.dart';
import 'notification_handler.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen>
    with WidgetsBindingObserver {
  int _currentTab = 0;
  final _cupertinoTabController = CupertinoTabController();
  void Function(int) onTabChange = (_) {};
  late final NotificationHandler notificationHandler;
  late final AppLinksHandler _appLinksHandler;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _appLinksHandler = AppLinksHandler();
    notificationHandler = ref.read(notificationHandlerProvider);
    runPostFrame(() {
      notificationHandler.init(context);
      _appLinksHandler.init(context);
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // deallocate resources
      _cupertinoTabController.dispose();
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  void dispose() {
    _appLinksHandler.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _observerShowNotificationPermissionPrompt(context);
    final hasSession = ref.watch(hasUserSession);
    final isGuest = ref.watch(guestUserIdProvider).valueOrNull != null;
    ref.listen(guestUserIdProvider, (previous, next) {
      final wasGuest = previous?.valueOrNull != null;
      if (!wasGuest && next.valueOrNull != null) changeTab(2);
    });
    final List<Widget> widgets = <Widget>[
      const HomeScreen(),
      hasSession
          ? const MyGameTabScreen()
          : SignInRequiredView(title: context.l10n.my_cricket_screen_title),
      hasSession || isGuest
          ? const PlayScreen()
          : SignInRequiredView(title: context.l10n.play_screen_title),
      const AuctionScreen(),
      hasSession
          ? ProfileScreen(changeTabToMyCricket: () {
              changeTab(1);
            })
          : SignInRequiredView(title: context.l10n.tab_profile_title),
    ];

    if (isIOS) {
      return _cupertinoTabs(context, widgets);
    }
    return _materialTabs(context, widgets);
  }

  void _observerShowNotificationPermissionPrompt(BuildContext context) {
    ref.listen(
        mainScreenStateNotifierProvider
            .select((value) => value.showNotificationPermissionPrompt),
        (previous, next) async {
      if (next != null) {
        final isNotificationPermissionRequired =
            await DeviceService.isNotificationPermissionRequired();
        final bool hasPermission =
            await Permission.notification.status.isGranted;
        if (context.mounted &&
            isNotificationPermissionRequired &&
            !hasPermission) {
          ref
              .read(mainScreenStateNotifierProvider.notifier)
              .notificationPermissionPromptShown();
          await showPermissionBottomSheet(context);
        }
      }
    });
  }

  Widget _cupertinoTabs(BuildContext context, List<Widget> widgets) =>
      CupertinoTabScaffold(
        // Grouped background behind the tab content
        backgroundColor: context.colorScheme.groupedBackground,
        controller: _cupertinoTabController,
        tabBar: CupertinoTabBar(
          // iOS-standard white / dark bar background
          backgroundColor: context.colorScheme.surface,
          // iOS standard tab bar height
          height: 49,
          border: Border(
            top: BorderSide(
              // iOS 0.5pt hairline separator
              color: context.colorScheme.outline,
              width: 0.5,
            ),
          ),
          activeColor: context.colorScheme.primary,
          inactiveColor: context.colorScheme.textDisabled,
          items: _tabItems(context)
              .map((e) => e.toBottomNavigationBarItem(context))
              .toList(),
        ),
        tabBuilder: (BuildContext context, int index) {
          return CupertinoTabView(
            builder: (BuildContext context) => widgets[index],
          );
        },
      );

  Widget _materialTabs(BuildContext context, List<Widget> widgets) => Scaffold(
        backgroundColor: context.colorScheme.groupedBackground,
        body: FadeIndexedStack(
          index: _currentTab,
          children: widgets,
        ),
        bottomNavigationBar: AppBottomNavigationBar(
          leading: Padding(
            padding: const EdgeInsets.all(3),
            child: SvgPicture.asset(Assets.images.appLogoMark),
          ),
          tabs: _tabItems(context, onPrimaryBar: true),
          builder: (BuildContext context, void Function(int) onTabTap) {
            onTabChange = onTabTap;
          },
        ),
      );

  List<TabItem> _tabItems(BuildContext context, {bool onPrimaryBar = false}) =>
      [
        TabItem(
          tabIcon: _tabImage(context,
              onPrimaryBar: onPrimaryBar, imagePath: Assets.images.icHome),
          tabActiveIcon: _tabImage(context,
              onPrimaryBar: onPrimaryBar,
              imagePath: Assets.images.icHome,
              isActive: true),
          tabLabel: context.l10n.home_screen_title,
          route: '',
          onTap: () => setState(() => _currentTab = 0),
        ),
        TabItem(
          tabIcon: _tabImage(context,
              onPrimaryBar: onPrimaryBar, imagePath: Assets.images.icCricket),
          tabActiveIcon: _tabImage(
            context,
            onPrimaryBar: onPrimaryBar,
            imagePath: Assets.images.icCricket,
            isActive: true,
          ),
          tabLabel: context.l10n.my_cricket_screen_title,
          route: '',
          onTap: () => setState(() => _currentTab = 1),
        ),
        TabItem(
          tabIcon: _tabIcon(context,
              onPrimaryBar: onPrimaryBar, icon: CupertinoIcons.game_controller),
          tabActiveIcon: _tabIcon(context,
              onPrimaryBar: onPrimaryBar,
              icon: CupertinoIcons.game_controller_solid,
              isActive: true),
          tabLabel: context.l10n.tab_play_title,
          route: '',
          onTap: () => setState(() => _currentTab = 2),
        ),
        TabItem(
          tabIcon: _tabIcon(context,
              onPrimaryBar: onPrimaryBar, icon: CupertinoIcons.hammer),
          tabActiveIcon: _tabIcon(context,
              onPrimaryBar: onPrimaryBar,
              icon: CupertinoIcons.hammer_fill,
              isActive: true),
          tabLabel: context.l10n.tab_auction_title,
          route: '',
          onTap: () => setState(() => _currentTab = 3),
        ),
        TabItem(
          tabIcon: _tabImage(context,
              onPrimaryBar: onPrimaryBar, imagePath: Assets.images.icProfile),
          tabActiveIcon: _tabImage(context,
              onPrimaryBar: onPrimaryBar,
              imagePath: Assets.images.icProfile,
              isActive: true),
          tabLabel: context.l10n.tab_profile_title,
          route: '',
          onTap: () => setState(() => _currentTab = 4),
        ),
      ];

  /// iOS tab icon: simple color tween between disabled gray and primary blue.
  /// No pill capsule — native iOS tab bars only tint the icon+label.
  Widget _tabImage(
    BuildContext context, {
    required String imagePath,
    bool isActive = false,
    bool onPrimaryBar = false,
  }) {
    final color = onPrimaryBar
        ? context.colorScheme.onPrimary
        : isActive
            ? context.colorScheme.primary
            : context.colorScheme.textDisabled;
    return SvgPicture.asset(
      imagePath,
      height: 24,
      width: 24,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }

  Widget _tabIcon(
    BuildContext context, {
    required IconData icon,
    bool isActive = false,
    bool onPrimaryBar = false,
  }) {
    final color = onPrimaryBar
        ? context.colorScheme.onPrimary
        : isActive
            ? context.colorScheme.primary
            : context.colorScheme.textDisabled;
    return Icon(icon, size: 24, color: color);
  }

  void changeTab(int tabNumber) {
    if (isIOS) {
      _cupertinoTabController.index = tabNumber;
    } else {
      setState(() => _currentTab = tabNumber);
      onTabChange.call(tabNumber);
    }
  }
}
