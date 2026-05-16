import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_tokens.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final double blurSigma;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? tintColor;
  final Color? borderColor;
  final List<BoxShadow>? shadows;

  const GlassCard({
    super.key,
    required this.child,
    this.blurSigma = 12.0,
    this.opacity = 0.13,
    this.borderRadius,
    this.padding,
    this.tintColor,
    this.borderColor,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(AppTokens.radiusCard);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (isDark) {
      // Dark mode: use glass morphism
      final tint = tintColor ?? Colors.white;
      return ClipRRect(
        borderRadius: br,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              borderRadius: br,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  tint.withOpacity(opacity + 0.08),
                  tint.withOpacity(opacity),
                ],
              ),
              border: Border.all(
                color: borderColor ?? Colors.white.withOpacity(0.22),
                width: 1.2,
              ),
              boxShadow: shadows ??
                  [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      );
    } else {
      // Light mode: use clean card styling
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: AppTokens.surfaceWhite,
          borderRadius: br,
          border: Border.all(color: AppTokens.borderLight, width: 0.5),
          boxShadow: AppTokens.cardShadow,
        ),
        child: child,
      );
    }
  }
}

class GlassButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final double? width;
  final double height;
  final Color? accentColor;
  final BorderRadius? borderRadius;

  const GlassButton({
    super.key,
    required this.child,
    this.onTap,
    this.width,
    this.height = 52,
    this.accentColor,
    this.borderRadius,
  });

  @override
  State<GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<GlassButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.96).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = widget.accentColor ?? AppTokens.primary;
    final br = widget.borderRadius ?? BorderRadius.circular(14);

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: ClipRRect(
          borderRadius: br,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              width: widget.width,
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: br,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withOpacity(0.35),
                    accent.withOpacity(0.15),
                  ],
                ),
                border: Border.all(
                  color: accent.withOpacity(0.6),
                  width: 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.25),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}

class LiquidBackground extends StatelessWidget {
  final Widget child;
  final List<Color>? colors;

  const LiquidBackground({super.key, required this.child, this.colors});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors ??
              (isDark
                  ? const [
                      Color(0xFF0C0A09),
                      Color(0xFF1C1917),
                      Color(0xFF292524),
                    ]
                  : const [
                      Color(0xFF059669),
                      Color(0xFF047857),
                      Color(0xFF0891B2),
                    ]),
        ),
      ),
      child: child,
    );
  }
}
