import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:style/extensions/context_extensions.dart';

/// iOS-style Cupertino navigation bar with no bottom separator.
///
/// Uses a frosted-glass-like translucent background by default (matching
/// native iOS navigation bar behaviour). Supports leading, middle, trailing.
class CustomCupertinoNavigationBar extends StatelessWidget
    implements ObstructingPreferredSizeWidget {
  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;
  final bool automaticallyImplyLeading;
  final String? previousPageTitle;
  final Color? backgroundColor;
  final EdgeInsets padding;

  const CustomCupertinoNavigationBar({
    Key? key,
    this.leading,
    this.middle,
    this.trailing,
    this.automaticallyImplyLeading = true,
    this.previousPageTitle,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = context.brightness == Brightness.dark;
    SystemChrome.setSystemUIOverlayStyle(
      isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    );

    // iOS nav bar background: slightly translucent white / dark
    final bgColor = backgroundColor ??
        (isDark
            ? const Color(0xF0000000) // 94% opaque true-black
            : const Color(0xF2F9F9F9)); // ~95% opaque white

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bgColor,
        // iOS uses a hairline separator at the bottom — no elevation
        border: Border(
          bottom: BorderSide(
            color: context.colorScheme.outline,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: kMinInteractiveDimension,
          child: NavigationToolbar(
            leading: _leading(context),
            middle: _middle(context),
            trailing: _trailing(),
            middleSpacing: 6.0,
          ),
        ),
      ),
    );
  }

  Widget _leading(BuildContext context) {
    if (automaticallyImplyLeading && Navigator.of(context).canPop()) {
      return CupertinoNavigationBarBackButton(
        previousPageTitle: previousPageTitle,
        onPressed: () => Navigator.maybePop(context),
      );
    }
    if (leading != null && !automaticallyImplyLeading) return leading!;
    return const SizedBox();
  }

  Widget _middle(BuildContext context) {
    return DefaultTextStyle(
      style: CupertinoTheme.of(context).textTheme.navTitleTextStyle,
      child: middle ?? const SizedBox(),
    );
  }

  Widget _trailing() {
    return (trailing != null)
        ? Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: trailing!,
          )
        : const SizedBox();
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kMinInteractiveDimension + padding.vertical);

  @override
  bool shouldFullyObstruct(BuildContext context) => true;
}
