import 'package:flutter/material.dart';

import '../extensions/context_extensions.dart';
import '../text/app_text_style.dart';
import '../theme/colors.dart';

typedef TabTapMethodBuilder = void Function(
    BuildContext context, void Function(int) onTabTap);

class TabItem {
  final Widget tabIcon;
  final Widget tabActiveIcon;
  final String tabLabel;
  final String route;
  final Function onTap;

  const TabItem({
    required this.tabIcon,
    required this.tabActiveIcon,
    required this.tabLabel,
    required this.route,
    required this.onTap,
  });

  BottomNavigationBarItem toBottomNavigationBarItem(BuildContext context) {
    return BottomNavigationBarItem(
      icon: tabIcon,
      label: tabLabel,
      activeIcon: tabActiveIcon,
    );
  }
}

/// Floating deep-indigo pill bar. The selected tab's icon sits in a glowing
/// mint circle; [leading] (e.g. the app logo) is shown in a white circle on
/// the left.
class AppBottomNavigationBar extends StatefulWidget {
  final TabTapMethodBuilder builder;
  final List<TabItem> tabs;
  final Widget? leading;

  const AppBottomNavigationBar({
    super.key,
    required this.tabs,
    required this.builder,
    this.leading,
  });

  @override
  State<AppBottomNavigationBar> createState() => _AppBottomNavigationBarState();
}

class _AppBottomNavigationBarState extends State<AppBottomNavigationBar> {
  int _selectedIndex = 0;

  void onTab(index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    widget.builder.call(context, onTab);
    final colors = context.colorScheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: brandNavyBarColor,
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: brandNavyColor.withValues(alpha: 0.35),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              if (widget.leading != null) ...[
                Container(
                  height: 56,
                  width: 56,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                  ),
                  child: widget.leading,
                ),
                const SizedBox(width: 4),
              ],
              for (int index = 0; index < widget.tabs.length; index++)
                Expanded(child: _tab(context, index)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(BuildContext context, int index) {
    final colors = context.colorScheme;
    final tab = widget.tabs[index];
    final selected = index == _selectedIndex;
    final foreground =
        selected ? colors.onPrimary : colors.onPrimary.withValues(alpha: 0.75);

    void select() {
      onTab(index);
      tab.onTap.call();
    }

    return Semantics(
      button: true,
      selected: selected,
      label: tab.tabLabel,
      onTap: select,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: select,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              height: 36,
              width: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? brandRedColor : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: brandRedColor.withValues(alpha: 0.55),
                          blurRadius: 14,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: SizedBox(
                height: 22,
                width: 22,
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
                  child: selected ? tab.tabActiveIcon : tab.tabIcon,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              tab.tabLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.caption.copyWith(
                color: foreground,
                fontSize: 11,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
