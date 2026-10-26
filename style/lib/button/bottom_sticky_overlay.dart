import 'package:flutter/cupertino.dart';

import '../extensions/context_extensions.dart';
import '../theme/shadows.dart';

/// iOS-style bottom sticky action bar.
///
/// Uses a hairline top separator + white/dark surface, matching
/// iOS tab bar and action sheet anatomy. No heavy shadow.
class BottomStickyOverlay extends StatelessWidget {
  static const padding = EdgeInsets.only(bottom: 80);

  final Widget child;

  const BottomStickyOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // iOS hairline separator at the top edge
          Container(
            height: 0.5,
            color: context.colorScheme.outline,
          ),
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: 16 + MediaQuery.of(context).padding.bottom,
            ),
            decoration: BoxDecoration(
              color: context.colorScheme.surface,
              boxShadow: context.colorScheme.bottomBarShadow,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}
