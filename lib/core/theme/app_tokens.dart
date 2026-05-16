import 'package:flutter/material.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// EMERALD OASIS Design System — Taheri Committee
/// Culturally resonant · WCAG AAA · Modern Material 3
/// ═══════════════════════════════════════════════════════════════════════════════
class AppTokens {
  // ── Primary (Emerald) ──────────────────────────────────────────────────
  static const Color primary = Color(0xFF059669); // Emerald-600
  static const Color primaryDark = Color(0xFF047857); // Emerald-700
  static const Color primaryLight = Color(0xFFD1FAE5); // Emerald-100
  static const Color primarySubtle = Color(0xFFECFDF5); // Emerald-50

  // ── Secondary (Cyan) ──────────────────────────────────────────────────
  static const Color secondary = Color(0xFF0891B2); // Cyan-600
  static const Color secondaryDark = Color(0xFF0E7490); // Cyan-700
  static const Color secondaryLight = Color(0xFFCFFAFE); // Cyan-100

  // ── Accent ─────────────────────────────────────────────────────────────
  static const Color accentGold = Color(0xFFD97706); // Amber-600
  static const Color accentRose = Color(0xFFE11D48); // Rose-600
  static const Color accentPurple = Color(0xFF7C3AED); // Violet-600

  // ── Semantic ───────────────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981); // Emerald-500
  static const Color warning = Color(0xFFF59E0B); // Amber-500
  static const Color danger = Color(0xFFEF4444); // Red-500
  static const Color info = Color(0xFF06B6D4); // Cyan-500

  // ── Light Neutrals (Stone palette — warmer than gray) ──────────────────
  static const Color surfaceBackground = Color(0xFFFAFAF9); // Stone-50
  static const Color surfaceWhite = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF5F5F4); // Stone-100
  static const Color surfaceInput = Color(0xFFF5F5F4); // Stone-100
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceWarm = Color(0xFFFAFAF9); // Stone-50

  // ── Dark Neutrals (Stone palette) ──────────────────────────────────────
  static const Color darkBg = Color(0xFF0C0A09); // Stone-950
  static const Color darkSurface = Color(0xFF1C1917); // Stone-900
  static const Color darkCard = Color(0xFF292524); // Stone-800
  static const Color darkBorder = Color(0xFF44403C); // Stone-700

  // ── Text (Light) ───────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1C1917); // Stone-900
  static const Color textSecondary = Color(0xFF78716C); // Stone-500
  static const Color textMuted = Color(0xFFA8A29E); // Stone-400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // ── Text (Dark) ────────────────────────────────────────────────────────
  static const Color darkTextPrimary = Color(0xFFFAFAF9); // Stone-50
  static const Color darkTextSecondary = Color(0xFFD6D3D1); // Stone-300
  static const Color darkTextMuted = Color(0xFFA8A29E); // Stone-400

  // ── Role colors ────────────────────────────────────────────────────────
  static const Color roleAdmin = Color(0xFFD97706); // Gold
  static const Color roleLeader = Color(0xFFE11D48); // Rose
  static const Color roleSupervisor = Color(0xFF7C3AED); // Purple
  static const Color roleMember = Color(0xFF059669); // Emerald

  // ── Border ─────────────────────────────────────────────────────────────
  static const Color border = Color(0xFFE7E5E4); // Stone-200
  static const Color borderLight = Color(0xFFF5F5F4); // Stone-100

  // ── Radius (8px grid aligned) ──────────────────────────────────────────
  static const double radiusXs = 4;
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radius2xl = 24;
  static const double radiusFull = 9999;

  // ── Component radius (semantic aliases) ────────────────────────────────
  static const double radiusCard = 12;
  static const double radiusButton = 8;
  static const double radiusInput = 8;
  static const double radiusChip = 4;
  static const double radiusModal = 16;
  static const double radiusAvatar = 9999;

  // ── Spacing (8px grid) ─────────────────────────────────────────────────
  static const double sp2 = 2;
  static const double sp4 = 4;
  static const double sp8 = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp32 = 32;
  static const double sp40 = 40;
  static const double sp48 = 48;
  static const double sp64 = 64;
  static const double sp96 = 96;

  // ── Shadows (Light mode) ───────────────────────────────────────────────
  static List<BoxShadow> get shadowXs => [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 2,
          offset: const Offset(0, 1),
        ),
      ];
  static List<BoxShadow> get shadowSm => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
  static List<BoxShadow> get shadowLg => [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
      ];
  static List<BoxShadow> get modalShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.15),
          blurRadius: 30,
          offset: const Offset(0, 20),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          blurRadius: 15,
          offset: const Offset(0, 10),
        ),
      ];

  // ── Colored glows (hover/interactive) ──────────────────────────────────
  static List<BoxShadow> get emeraldGlow => [
        BoxShadow(
          color: primary.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
  static List<BoxShadow> get goldGlow => [
        BoxShadow(
          color: accentGold.withOpacity(0.3),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  // ── Gradients ──────────────────────────────────────────────────────────
  static const LinearGradient heroGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF0891B2)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Keep legacy aliases for backward compatibility
  static const LinearGradient primaryGradient = heroGradient;
  static const LinearGradient navGradient = heroGradient;
  static const LinearGradient accentGradient = goldGradient;

  // Legacy aliases
  static const Color accent = secondary;
  static const Color gold = accentGold;

  // ── Legacy shadow alias ────────────────────────────────────────────────
  static List<BoxShadow> get blueShadow => emeraldGlow;

  // ── Breakpoints ────────────────────────────────────────────────────────
  static const double mobile = 640;
  static const double tablet = 1024;
  static const double desktop = 1200;
}

class AppBreakpoints {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppTokens.mobile;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppTokens.mobile &&
      MediaQuery.of(context).size.width < AppTokens.tablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppTokens.tablet;
}
