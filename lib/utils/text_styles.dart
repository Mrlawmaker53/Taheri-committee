import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTextStyles {
  // Hero Section
  static TextStyle get heroTitle => GoogleFonts.poppins(
    fontSize: 48, // 3rem
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static TextStyle get heroSubtitle => GoogleFonts.poppins(
    fontSize: 24, // 1.5rem
    fontWeight: FontWeight.w600,
    color: AppColors.accent,
    height: 1.3,
  );
  
  static TextStyle get heroTagline => GoogleFonts.poppins(
    fontSize: 16,
    color: AppColors.textSecondary,
    height: 1.5,
  );
  
  // Section Headers
  static TextStyle get sectionTitle => GoogleFonts.poppins(
    fontSize: 32, // 2rem
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    height: 1.3,
  );
  
  static TextStyle get sectionSubtitle => GoogleFonts.poppins(
    fontSize: 20,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Stats Section
  static TextStyle get statsNumber => GoogleFonts.poppins(
    fontSize: 40, // 2.5rem
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    height: 1.0,
  );
  
  static TextStyle get statsLabel => GoogleFonts.poppins(
    fontSize: 16,
    color: AppColors.textSecondary,
    fontWeight: FontWeight.w500,
  );
  
  // About Section
  static TextStyle get aboutContent => GoogleFonts.poppins(
    fontSize: 16,
    color: AppColors.textSecondary,
    height: 1.6,
  );
  
  // Mission Section
  static TextStyle get missionTitle => GoogleFonts.poppins(
    fontSize: 40, // 2.5rem
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    height: 1.2,
  );
  
  static TextStyle get missionIntro => GoogleFonts.poppins(
    fontSize: 18,
    color: AppColors.textPrimary,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );
  
  static TextStyle get missionItem => GoogleFonts.poppins(
    fontSize: 16,
    color: AppColors.textSecondary,
    height: 1.4,
  );
  
  // Social Section
  static TextStyle get socialTitle => GoogleFonts.poppins(
    fontSize: 40, // 2.5rem
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    height: 1.2,
  );
  
  static TextStyle get socialCardTitle => GoogleFonts.poppins(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get socialCardText => GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.textSecondary,
  );
  
  // Prayer Section
  static TextStyle get prayerArabic => GoogleFonts.poppins(
    fontSize: 24,
    color: AppColors.textPrimary,
    height: 1.8,
    fontWeight: FontWeight.w500,
  );
  
  static TextStyle get prayerOrganization => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.accent,
    letterSpacing: 2,
  );
  
  static TextStyle get prayerTranslation => GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.textSecondary,
    fontStyle: FontStyle.italic,
  );
  
  // Button Text
  static TextStyle get buttonText => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  
  // AppBar Text
  static TextStyle get appBarTitle => GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
    letterSpacing: 1.5,
  );
  
  // Footer
  static TextStyle get footer => GoogleFonts.poppins(
    fontSize: 12,
    color: AppColors.textTertiary,
  );
  
  // Gallery Card
  static TextStyle get galleryTitle => GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );
  
  static TextStyle get galleryDescription => GoogleFonts.poppins(
    fontSize: 14,
    color: AppColors.textSecondary,
    height: 1.4,
  );
}
