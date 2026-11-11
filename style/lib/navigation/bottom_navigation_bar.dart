import 'package:flutter/material.dart';

import '../animations/fade_slide_in.dart';
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

/// Floating navy pill bar. A glowing red circle springs to the selected tab
/// and its icon pops up; [leading] (e.g. the app logo) is shown in a white
/// circle on the left. Motion is skipped when reduced motion is on.
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
  static const _indicatorSize = 36.0;
  static const _indicatorTop = 10.0;

  int _selectedIndex = 0;
  int? _pressedIndex;

  void onTab(index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  bool get _reduceMotion =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  Duration _motion(Duration duration) =>
      _reduceMotion ? Duration.zero : duration;

  @override
  Widget build(BuildContext context) {
    widget.builder.call(context, onTab);
    final colors = context.colorScheme;

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
        child: FadeSlideIn(
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
                Expanded(child: _tabs(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// One red indicator that springs between tabs (like Framer Motion's
  /// shared `layoutId`), under the tab icons.
  Widget _tabs(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final slot = constraints.maxWidth / widget.tabs.length;
      return Stack(
        children: [
          AnimatedPositioned(
            duration: _motion(const Duration(milliseconds: 520)),
            curve: Curves.easeOutBack,
            top: _indicatorTop,
            left: slot * _selectedIndex + (slot - _indicatorSize) / 2,
            width: _indicatorSize,
            height: _indicatorSize,
            child: IgnorePointer(
              child: AnimatedScale(
                duration: _motion(const Duration(milliseconds: 120)),
                scale: _pressedIndex == _selectedIndex ? 0.88 : 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: brandRedColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: brandRedColor.withValues(alpha: 0.55),
                        blurRadius: 14,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (int index = 0; index < widget.tabs.length; index++)
                Expanded(child: _tab(context, index)),
            ],
          ),
        ],
      );
    });
  }

  Widget _tab(BuildContext context, int index) {
    final colors = context.colorScheme;
    final tab = widget.tabs[index];
    final selected = index == _selectedIndex;
    final pressed = index == _pressedIndex;
    final foreground =
        selected ? colors.onPrimary : colors.onPrimary.withValues(alpha: 0.75);

    void select() {
      onTab(index);
      tab.onTap.call();
    }

    void press(bool down) =>
        setState(() => _pressedIndex = down ? index : null);

    return Semantics(
      button: true,
      selected: selected,
      label: tab.tabLabel,
      onTap: select,
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: select,
        onTapDown: (_) => press(true),
        onTapUp: (_) => press(false),
        onTapCancel: () => press(false),
        child: AnimatedScale(
          duration: _motion(const Duration(milliseconds: 120)),
          curve: Curves.easeOut,
          scale: pressed ? 0.9 : 1,
          child: Column(
            children: [
              const SizedBox(height: _indicatorTop),
              SizedBox(
                height: _indicatorSize,
                width: _indicatorSize,
                child: Center(
                  child: AnimatedSlide(
                    duration: _motion(const Duration(milliseconds: 420)),
                    curve: Curves.easeOutBack,
                    offset: selected ? Offset.zero : const Offset(0, 0.08),
                    child: AnimatedScale(
                      duration: _motion(const Duration(milliseconds: 420)),
                      curve: Curves.easeOutBack,
                      scale: selected ? 1.12 : 1,
                      child: SizedBox(
                        height: 22,
                        width: 22,
                        child: TweenAnimationBuilder<Color?>(
                          duration: _motion(const Duration(milliseconds: 220)),
                          tween: ColorTween(end: foreground),
                          builder: (context, color, child) => ColorFiltered(
                            colorFilter: ColorFilter.mode(
                                color ?? foreground, BlendMode.srcIn),
                            child: child,
                          ),
                          child: selected ? tab.tabActiveIcon : tab.tabIcon,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              AnimatedDefaultTextStyle(
                duration: _motion(const Duration(milliseconds: 220)),
                curve: Curves.easeOut,
                style: AppTextStyle.caption.copyWith(
                  color: foreground,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
                child: Text(
                  tab.tabLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
