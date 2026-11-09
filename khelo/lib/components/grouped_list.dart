import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:style/animations/on_tap_scale.dart';
import 'package:style/extensions/context_extensions.dart';
import 'package:style/text/app_text_style.dart';
import 'package:style/theme/colors.dart';
import 'package:style/theme/shadows.dart';

/// Small uppercase grey heading above an iOS inset grouped list.
class SectionCaption extends StatelessWidget {
  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionCaption(
    this.title, {
    super.key,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 6),
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return Padding(
      padding: padding,
      child: Row(
        children: [
          Expanded(
            child: Text(
              title.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.caption.copyWith(
                color: cs.textSecondary,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Rounded square with a white icon, as in iOS Settings rows.
class IconTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;

  const IconTile(this.icon, this.color, {super.key, this.size = 30});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size * 0.26),
      ),
      child: Icon(icon, size: size * 0.56, color: Colors.white),
    );
  }
}

/// Navy gradient card with a red glow, used for screen headers.
class BrandHeroCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double glowSize;

  const BrandHeroCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 18),
    this.glowSize = 170,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandNavyCardColor, brandNavyColor],
        ),
        boxShadow: context.colorScheme.cardShadow,
      ),
      child: Stack(
        children: [
          Positioned(
            top: -60,
            right: -50,
            child: _glow(glowSize, brandRedColor.withValues(alpha: 0.9)),
          ),
          Positioned(
            bottom: -80,
            left: -40,
            child: _glow(160, Colors.white.withValues(alpha: 0.05)),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }

  Widget _glow(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      );
}

/// Navy tile with a red glow and a white icon; stands in for missing images.
class BrandIconThumb extends StatelessWidget {
  final IconData icon;
  final double size;

  const BrandIconThumb(this.icon, {super.key, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [brandNavyCardColor, brandNavyColor],
        ),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -size * 0.35,
            right: -size * 0.35,
            child: Container(
              width: size * 0.8,
              height: size * 0.8,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: brandRedColor,
              ),
            ),
          ),
          Icon(icon, size: size * 0.42, color: Colors.white),
        ],
      ),
    );
  }
}

/// Small rounded label with an optional leading icon.
class InfoChip extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;

  const InfoChip(
    this.label, {
    super.key,
    this.icon,
    this.color,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final fg = color ?? cs.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? cs.containerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.caption
                  .copyWith(color: fg, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

/// Empty state with an icon tile, title, text and a red pill button.
class BrandEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? buttonTitle;
  final VoidCallback? onTap;

  const BrandEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.buttonTitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return LayoutBuilder(
      builder: (context, constraints) {
        const padding = EdgeInsets.symmetric(horizontal: 32, vertical: 24);
        final content = _content(cs);
        if (!constraints.hasBoundedHeight) {
          return Padding(padding: padding, child: Center(child: content));
        }
        return Center(
          child: SingleChildScrollView(padding: padding, child: content),
        );
      },
    );
  }

  Widget _content(AppColorScheme cs) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandIconThumb(icon, size: 76),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyle.header3.copyWith(
              color: cs.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: AppTextStyle.body2.copyWith(color: cs.textSecondary),
          ),
          if (buttonTitle != null && onTap != null) ...[
            const SizedBox(height: 22),
            OnTapScale(
              onTap: onTap,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                decoration: BoxDecoration(
                  color: brandRedColor,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: brandRedColor.withValues(alpha: 0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.add,
                        size: 16, color: Colors.white),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        buttonTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyle.subtitle2.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
