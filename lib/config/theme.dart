import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // ═══ BACKGROUNDS ═══
  static const Color background = Color(0xFFFFF9F0);          // Cream
  static const Color backgroundSecondary = Color(0xFFF5F3FF); // Lavender tint
  static const Color cardBg = Color(0xFFFFFFFF);              // Pure white
  static const Color overlay = Color(0x80000000);             // Black 50%

  // ═══ BRAND COLORS ═══
  static const Color primary = Color(0xFF8B5CF6);      // Vibrant Purple
  static const Color secondary = Color(0xFF6366F1);    // Indigo AI Blue
  static const Color tertiary = Color(0xFF7C3AED);     // Deep Violet
  static const Color primaryDark = Color(0xFF6D28D9);  // For 3D button shadow

  // ═══ SUBJECT COLORS ═══
  // Math (Calculo Robot)
  static const Color mathPrimary = Color(0xFF8B5CF6);
  static const Color mathLightBg = Color(0xFFF5F3FF);
  static const Color mathBorder = Color(0xFFA78BFA);
  static const Color mathDark = Color(0xFF6D28D9);

  // Science (Dr. Spark)
  static const Color sciencePrimary = Color(0xFF10B981);
  static const Color scienceLightBg = Color(0xFFECFDF5);
  static const Color scienceBorder = Color(0xFF34D399);
  static const Color scienceDark = Color(0xFF059669);

  // English (Owly Owl)
  static const Color englishPrimary = Color(0xFFF59E0B);
  static const Color englishLightBg = Color(0xFFFFFBEB);
  static const Color englishBorder = Color(0xFFFBBF24);
  static const Color englishDark = Color(0xFFD97706);

  // Social Science (Indy Explorer)
  static const Color sstPrimary = Color(0xFFEC4899);
  static const Color sstLightBg = Color(0xFFFDF2F8);
  static const Color sstBorder = Color(0xFFF472B6);
  static const Color sstDark = Color(0xFFDB2777);

  // Hindi (Kavi Sahitya)
  static const Color hindiPrimary = Color(0xFF06B6D4);
  static const Color hindiLightBg = Color(0xFFECFEFF);
  static const Color hindiBorder = Color(0xFF22D3EE);
  static const Color hindiDark = Color(0xFF0891B2);

  // AI Tutor (Aria Orb)
  static const Color aiPrimary = Color(0xFF6366F1);
  static const Color aiLightBg = Color(0xFFEEF2FF);
  static const Color aiBorder = Color(0xFF818CF8);
  static const Color aiDark = Color(0xFF4F46E5);

  // ═══ SEMANTIC COLORS ═══
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF06B6D4);

  // ═══ TEXT COLORS ═══
  static const Color textPrimary = Color(0xFF2D2342);
  static const Color textSecondary = Color(0xFF4B5563);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // ═══ BORDER COLORS ═══
  static const Color border = Color(0xFFF3E8FF);          // Soft Lavender
  static const Color borderMedium = Color(0xFFDDD6FE);    // Medium Purple
  static const Color borderFocused = Color(0xFF8B5CF6);   // Purple

  // ═══ GRADIENTS ═══
  static const List<Color> gradientHero = [
    Color(0xFF8B5CF6), Color(0xFF4C1D95),
  ];
  
  static const List<Color> gradientAI = [
    Color(0xFFC7D2FE), Color(0xFF818CF8), Color(0xFF4F46E5),
  ];
  
  static const List<Color> gradientStreak = [
    Color(0xFFF59E0B), Color(0xFFEA580C),
  ];
  
  static const List<Color> gradientProgress = [
    Color(0xFFF59E0B), Color(0xFFFBBF24),
  ];
  
  static const List<Color> gradientBoardTarget = [
    Color(0xFF31104B), Color(0xFF1E1B4B),
  ];
  
  static const List<Color> gradientPurple = [
    Color(0xFF8B5CF6), Color(0xFF7C3AED),
  ];

  // ═══ TEMPORARY COMPATIBILITY COLORS (to prevent compiler errors before screen redesign) ═══
  static const Color cardGlass = Color(0x0DFFFFFF);
  static const Color accent = Color(0xFF06B6D4);
  static const List<Color> gradientBlue = [
    Color(0xFF4F8EF7), Color(0xFF8B5CF6),
  ];
  static const List<Color> gradientOrange = [
    Color(0xFF06B6D4), Color(0xFF10B981),
  ];
}

class AppSizes {
  // Spacing
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double xxl = 24;
  static const double xxxl = 32;

  // Border Radius
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXL = 24;
  static const double radiusFull = 9999;
  
  // 3D Button Effect
  static const double button3DDepth = 4;
}

class AppTextStyles {
  static String get _fontFamily => GoogleFonts.plusJakartaSans().fontFamily!;

  // Display
  static TextStyle displayLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  static TextStyle displayMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w900,
    color: AppColors.textPrimary,
    height: 1.2,
  );

  // Headings
  static TextStyle heading1 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle heading2 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static TextStyle heading3 = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // Body
  static TextStyle bodyLarge = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle bodyMedium = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static TextStyle bodySmall = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    color: AppColors.textMuted,
  );

  // Special
  static TextStyle caption = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.textMuted,
    letterSpacing: 1.2,
  );

  static TextStyle button = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: Colors.white,
    letterSpacing: 0.5,
  );

  static TextStyle label = TextStyle(
    fontFamily: _fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );
}

class AppShadows {
  static List<BoxShadow> small = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.08),
      offset: const Offset(0, 2),
      blurRadius: 4,
    ),
  ];

  static List<BoxShadow> medium = [
    BoxShadow(
      color: AppColors.primary.withOpacity(0.12),
      offset: const Offset(0, 4),
      blurRadius: 12,
    ),
  ];

  static List<BoxShadow> large = [
    BoxShadow(
      color: const Color(0xFF4C1D95).withOpacity(0.20),
      offset: const Offset(0, 10),
      blurRadius: 25,
    ),
  ];
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.background,
    primaryColor: AppColors.primary,
    fontFamily: GoogleFonts.plusJakartaSans().fontFamily,
    
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.cardBg,
      error: AppColors.error,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: AppColors.textPrimary,
    ),
    
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.background,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: AppTextStyles.heading1,
      iconTheme: const IconThemeData(color: AppColors.textPrimary),
    ),
    
    textTheme: TextTheme(
      displayLarge: AppTextStyles.displayLarge,
      displayMedium: AppTextStyles.displayMedium,
      headlineLarge: AppTextStyles.heading1,
      headlineMedium: AppTextStyles.heading2,
      headlineSmall: AppTextStyles.heading3,
      bodyLarge: AppTextStyles.bodyLarge,
      bodyMedium: AppTextStyles.bodyMedium,
      bodySmall: AppTextStyles.bodySmall,
      labelLarge: AppTextStyles.button,
      labelMedium: AppTextStyles.label,
      labelSmall: AppTextStyles.caption,
    ),
  );
}
