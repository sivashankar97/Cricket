import 'package:flutter/cupertino.dart';
import 'package:style/platform.dart';
import 'package:flutter/material.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/widgets/custom_cupertino_navigation_bar.dart';

/// Cross-platform page scaffold.
///
/// On iOS → [CupertinoPageScaffold] with a translucent nav bar and
///           `systemGroupedBackground` scaffold color.
/// On Android → [Scaffold] with a zero-elevation [AppBar].
class AppPage extends StatelessWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? floatingActionButton;
  final Widget? body;
  final EdgeInsets? padding;
  final bool automaticallyImplyLeading;
  final bool resizeToAvoidBottomInset;
  final Color? appBarBackgroundColor;

  const AppPage({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.body,
    this.padding,
    this.automaticallyImplyLeading = true,
    this.resizeToAvoidBottomInset = true,
    this.floatingActionButton,
    this.appBarBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (isIOS) {
      return _cupertino(context);
    } else {
      return _material(context);
    }
  }

  /// iOS scaffold: grouped background + translucent nav bar.
  Widget _cupertino(BuildContext context) => CupertinoPageScaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: context.colorScheme.groupedBackground,
        navigationBar: _hasNavBar
            ? CustomCupertinoNavigationBar(
                leading: leading,
                padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
                backgroundColor: appBarBackgroundColor,
                middle: titleWidget ?? _titleWidget(),
                trailing: _trailingActions(),
                automaticallyImplyLeading: automaticallyImplyLeading,
                previousPageTitle: automaticallyImplyLeading
                    ? MaterialLocalizations.of(context).backButtonTooltip
                    : null,
              )
            : null,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: [
            body ?? const SizedBox(),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(right: 16, bottom: 16),
                child: floatingActionButton ?? const SizedBox(),
              ),
            ),
          ],
        ),
      );

  /// Material scaffold: flat app bar, no tint.
  Widget _material(BuildContext context) => Scaffold(
        resizeToAvoidBottomInset: resizeToAvoidBottomInset,
        backgroundColor: context.colorScheme.groupedBackground,
        appBar: _hasNavBar
            ? AppBar(
                backgroundColor: appBarBackgroundColor ??
                    context.colorScheme.groupedBackground,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                toolbarHeight: kToolbarHeight + (padding?.vertical ?? 0),
                title: Padding(
                  padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
                  child: titleWidget ?? _titleWidget(),
                ),
                actions: actions,
                leading: leading,
                automaticallyImplyLeading: automaticallyImplyLeading,
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(0.5),
                  child: Container(
                    height: 0.5,
                    color: context.colorScheme.outline,
                  ),
                ),
              )
            : null,
        body: body,
        floatingActionButton: floatingActionButton,
      );

  bool get _hasNavBar =>
      title != null ||
      titleWidget != null ||
      actions != null ||
      leading != null;

  Widget? _titleWidget() => title != null
      ? Text(
          title!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyle.navTitle,
        )
      : null;

  Widget? _trailingActions() {
    if (actions == null) return null;
    if (actions!.length == 1) return actions!.first;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: actions!,
    );
  }
}
