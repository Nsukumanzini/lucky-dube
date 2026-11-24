// ignore: deprecated_member_use
import 'dart:ui' as ui;

// ignore: deprecated_member_use
import 'package:flutter/material.dart';

/// A light, restrained frosted surface for featured content and grouped panels.
/// Blur is kept intentionally modest so the effect stays comfortable on phones.
class FrostedSurface extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final BorderRadiusGeometry borderRadius;
  final Color? tint;
  final double blur;

  const FrostedSurface({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.tint,
    this.blur = 0,
  });

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = DecoratedBox(
      decoration: BoxDecoration(
        color:
            tint ?? (dark ? const Color(0xdd18253a) : const Color(0xdfffffff)),
        borderRadius: borderRadius,
        border: Border.all(
          color: dark ? Colors.white.withValues(alpha: .10) : Colors.white,
          width: 1.1,
        ),
        boxShadow: dark
            ? const []
            : const [
                BoxShadow(
                  color: Color(0x10213c66),
                  blurRadius: 22,
                  offset: Offset(0, 8),
                ),
              ],
      ),
      child: Padding(padding: padding, child: child),
    );
    return ClipRRect(
      borderRadius: borderRadius,
      child: blur <= 0
          ? surface
          : BackdropFilter(
              filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: surface,
            ),
    );
  }
}

/// Compact entrance used when a destination changes. Respects reduced motion.
class PageReveal extends StatelessWidget {
  final Widget child;
  const PageReveal({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : 0, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(0, reduce ? 0 : 12 * (1 - value)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}

/// A material icon badge with a short scale-in and tap response.
class AnimatedIconBadge extends StatefulWidget {
  final IconData icon;
  final Color color;
  final Color? background;
  final double size;
  const AnimatedIconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.background,
    this.size = 44,
  });

  @override
  State<AnimatedIconBadge> createState() => _AnimatedIconBadgeState();
}

class _AnimatedIconBadgeState extends State<AnimatedIconBadge> {
  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: reduce ? 1 : .82, end: 1),
      duration: reduce ? Duration.zero : const Duration(milliseconds: 380),
      curve: Curves.easeOutBack,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.background ?? widget.color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(widget.size * .32),
        ),
        alignment: Alignment.center,
        child: Icon(widget.icon, color: widget.color, size: widget.size * .5),
      ),
    );
  }
}
