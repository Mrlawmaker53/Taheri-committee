import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_tokens.dart';

class ThemeController extends GetxController {
  static const String _key = 'isDarkMode';
  final Rx<ThemeMode> themeMode = ThemeMode.light.obs;

  @override
  void onInit() {
    super.onInit();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_key) ?? false;
    themeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggleTheme() async {
    final isDark = themeMode.value == ThemeMode.dark;
    themeMode.value = isDark ? ThemeMode.light : ThemeMode.dark;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, !isDark);
  }

  bool get isDark => themeMode.value == ThemeMode.dark;

  ThemeData get lightTheme => _buildTheme(Brightness.light);
  ThemeData get darkTheme => _buildTheme(Brightness.dark);

  ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final bgColor = isDark ? AppTokens.darkBg : AppTokens.surfaceBackground;
    final surfaceColor =
        isDark ? AppTokens.darkSurface : AppTokens.surfaceWhite;
    final cardColor = isDark ? AppTokens.darkCard : AppTokens.surfaceCard;
    final textColor =
        isDark ? AppTokens.darkTextPrimary : AppTokens.textPrimary;
    final secondaryTextColor =
        isDark ? AppTokens.darkTextSecondary : AppTokens.textSecondary;
    final mutedTextColor =
        isDark ? AppTokens.darkTextMuted : AppTokens.textMuted;
    final dividerColor = isDark ? AppTokens.darkBorder : AppTokens.border;
    final borderColor = isDark ? AppTokens.darkBorder : AppTokens.border;

    final baseTextTheme = GoogleFonts.plusJakartaSansTextTheme();

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: AppTokens.primary,
        onPrimary: Colors.white,
        primaryContainer: AppTokens.primaryLight,
        onPrimaryContainer: AppTokens.primaryDark,
        secondary: AppTokens.secondary,
        onSecondary: Colors.white,
        secondaryContainer: AppTokens.secondaryLight,
        onSecondaryContainer: AppTokens.secondaryDark,
        tertiary: AppTokens.accentGold,
        onTertiary: Colors.white,
        tertiaryContainer: const Color(0xFFFEF3C7),
        onTertiaryContainer: const Color(0xFF92400E),
        error: AppTokens.danger,
        onError: Colors.white,
        errorContainer: const Color(0xFFFEE2E2),
        onErrorContainer: const Color(0xFF991B1B),
        surface: surfaceColor,
        onSurface: textColor,
        surfaceContainerHighest:
            isDark ? AppTokens.darkCard : AppTokens.surfaceElevated,
        onSurfaceVariant: secondaryTextColor,
        outline: borderColor,
        outlineVariant:
            isDark ? const Color(0xFF292524) : AppTokens.borderLight,
        inverseSurface:
            isDark ? AppTokens.surfaceBackground : AppTokens.darkSurface,
        onInverseSurface:
            isDark ? AppTokens.textPrimary : AppTokens.darkTextPrimary,
        inversePrimary: AppTokens.primaryLight,
        shadow: Colors.black,
        scrim: Colors.black,
        surfaceTint: AppTokens.primary,
      ),
      scaffoldBackgroundColor: bgColor,
      primaryColor: AppTokens.primary,

      // ── AppBar ──────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? AppTokens.darkSurface : Colors.white,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        iconTheme: IconThemeData(color: textColor),
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),

      // ── Card ────────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusCard),
          side: BorderSide(color: borderColor, width: 1),
        ),
      ),

      // ── Elevated Button (Primary) ──────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTokens.primary,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Outlined Button (Secondary) ────────────────────────────────────────
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppTokens.primary,
          side: const BorderSide(color: AppTokens.primary, width: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusButton),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Text Button (Ghost) ─────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppTokens.primary,
          textStyle: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ── Input / TextField ───────────────────────────────────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppTokens.darkCard : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: BorderSide(color: borderColor, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusInput),
          borderSide: const BorderSide(color: AppTokens.danger, width: 2),
        ),
        labelStyle: TextStyle(color: secondaryTextColor),
        hintStyle: TextStyle(color: mutedTextColor),
        prefixIconColor: secondaryTextColor,
        suffixIconColor: secondaryTextColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // ── Divider ─────────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: 1,
        space: 1,
      ),

      // ── List Tile ───────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        textColor: textColor,
        iconColor: secondaryTextColor,
        tileColor: Colors.transparent,
        selectedTileColor: AppTokens.primaryLight,
        selectedColor: AppTokens.primaryDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
      ),

      // ── Dialog ──────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppTokens.darkSurface : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusModal),
        ),
        elevation: 8,
        titleTextStyle: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: secondaryTextColor,
          fontSize: 16,
        ),
      ),

      // ── Popup Menu ──────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: isDark ? AppTokens.darkCard : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        elevation: 8,
        textStyle: TextStyle(color: textColor),
      ),

      // ── Chip ────────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppTokens.darkCard : AppTokens.surfaceElevated,
        labelStyle: TextStyle(
            color: textColor, fontSize: 12, fontWeight: FontWeight.w600),
        side: BorderSide(color: borderColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusFull),
        ),
      ),

      // ── Typography ──────────────────────────────────────────────────────────
      textTheme: baseTextTheme.copyWith(
        displayLarge: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 48,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
        ),
        displayMedium: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 36,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.02,
        ),
        displaySmall: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 30,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 28,
          fontWeight: FontWeight.w700,
        ),
        headlineMedium: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 24,
          fontWeight: FontWeight.w600,
        ),
        headlineSmall: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        titleLarge: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        titleSmall: GoogleFonts.plusJakartaSans(
          color: secondaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.plusJakartaSans(
          color: secondaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        labelLarge: GoogleFonts.plusJakartaSans(
          color: textColor,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
        labelMedium: GoogleFonts.plusJakartaSans(
          color: secondaryTextColor,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        labelSmall: GoogleFonts.plusJakartaSans(
          color: mutedTextColor,
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // ── Icon ────────────────────────────────────────────────────────────────
      iconTheme: IconThemeData(color: secondaryTextColor),

      // ── FAB ─────────────────────────────────────────────────────────────────
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppTokens.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // ── Bottom Sheet ────────────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark ? AppTokens.darkSurface : Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      // ── Snack Bar ───────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppTokens.textPrimary,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          color: AppTokens.surfaceBackground,
          fontSize: 14,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusSm),
        ),
        behavior: SnackBarBehavior.floating,
        elevation: 6,
      ),

      // ── Switch ──────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? Colors.white
              : AppTokens.textMuted,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppTokens.primary
              : AppTokens.border,
        ),
      ),

      // ── Checkbox ────────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppTokens.primary
              : Colors.transparent,
        ),
        checkColor: WidgetStateProperty.all(Colors.white),
        side: BorderSide(color: borderColor, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusXs),
        ),
      ),

      // ── Radio ───────────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected)
              ? AppTokens.primary
              : borderColor,
        ),
      ),

      // ── Progress Indicator ──────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppTokens.primary,
        linearTrackColor: AppTokens.border,
      ),

      // ── Tab Bar ─────────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppTokens.primary,
        unselectedLabelColor: secondaryTextColor,
        indicatorColor: AppTokens.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),

      // ── Navigation Bar (Bottom) ─────────────────────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: isDark ? AppTokens.darkSurface : Colors.white,
        indicatorColor: AppTokens.primaryLight,
        iconTheme: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppTokens.primary);
          }
          return IconThemeData(color: secondaryTextColor);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((s) {
          if (s.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              color: AppTokens.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            );
          }
          return GoogleFonts.plusJakartaSans(
            color: secondaryTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          );
        }),
      ),
    );
  }
}
