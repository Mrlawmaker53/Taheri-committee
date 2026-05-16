import 'package:flutter/material.dart';

class AppColors {
  // Primary gradient colors
  static const Color gradientStart = Color(0xFF1e3c72);
  static const Color gradientEnd = Color(0xFF2a5298);
  
  // Accent colors
  static const Color accent = Color(0xFF17a2b8);
  static const Color accentLight = Color(0xFF5dade2);
  
  // Glassmorphism
  static const Color glassBackground = Color(0x1AFFFFFF); // Colors.white.withOpacity(0.1)
  static const Color glassBorder = Color(0x33FFFFFF); // Colors.white.withOpacity(0.2)
  
  // Text colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xB3FFFFFF); // Colors.white.withOpacity(0.7)
  static const Color textTertiary = Color(0x80FFFFFF); // Colors.white.withOpacity(0.5)
  
  // Background colors
  static const Color backgroundDark = Color(0x66000000); // Colors.black.withOpacity(0.4)
  static const Color backgroundMedium = Color(0x4D000000); // Colors.black.withOpacity(0.3)
  
  // Social media gradients
  static const List<Color> instagramGradient = [
    Color(0xFFf09433),
    Color(0xFFe6683c),
    Color(0xFFdc2743),
    Color(0xFFcc2366),
    Color(0xFFbc1888),
  ];
  
  static const List<Color> whatsappGradient = [
    Color(0xFF25D366),
    Color(0xFF128C7E),
  ];
  
  // Card hover colors
  static const Color cardHover = Color(0x26FFFFFF); // Colors.white.withOpacity(0.15)
  
  // Shadow colors
  static const Color shadow = Color(0x40000000); // Colors.black.withOpacity(0.25)
  static const Color shadowLight = Color(0x20000000); // Colors.black.withOpacity(0.125)
}

class AppGradients {
  static const LinearGradient primary = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.gradientStart, AppColors.gradientEnd],
  );
  
  static const LinearGradient accent = LinearGradient(
    colors: [AppColors.accent, AppColors.accentLight],
  );
  
  static const LinearGradient instagram = LinearGradient(
    colors: AppColors.instagramGradient,
  );
  
  static const LinearGradient whatsapp = LinearGradient(
    colors: AppColors.whatsappGradient,
  );
  
  static const LinearGradient glass = LinearGradient(
    colors: [AppColors.glassBackground, AppColors.glassBackground],
  );
}
