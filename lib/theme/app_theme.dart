import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  // Primary palette from Figma
  static const primary      = Color(0xFF6C5CE7);
  static const primaryLight = Color(0xFFA29BFE);
  static const secondary    = Color(0xFF00B894);
  static const warning      = Color(0xFFFDCB6E);
  static const danger       = Color(0xFFE17055);
  static const pink         = Color(0xFFE84393);

  // Backgrounds
  static const bg     = Color(0xFFF7F6FF);
  static const card   = Color(0xFFFFFFFF);
  static const text   = Color(0xFF1A1A2E);
  static const muted  = Color(0xFF7C7C9E);
  static const border = Color(0x1F6C5CE7);

  // Category gradients (from Figma)
  static const gradConference   = [Color(0xFF6C5CE7), Color(0xFFA29BFE)];
  static const gradSports       = [Color(0xFF00B894), Color(0xFF55EFC4)];
  static const gradWorkshop     = [Color(0xFF0984E3), Color(0xFF74B9FF)];
  static const gradSocial       = [Color(0xFFE17055), Color(0xFFFAB1A0)];
  static const gradArt          = [Color(0xFFFDCB6E), Color(0xFFFFEAA7)];
  static const gradMusic        = [Color(0xFFE84393), Color(0xFFFD79A8)];
  static const gradSeminar      = [Color(0xFF00CEC9), Color(0xFF81ECEC)];
  static const gradOther        = [Color(0xFF636E72), Color(0xFFB2BEC3)];
}

class AppTheme {
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.bg,
    colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
    textTheme: GoogleFonts.dmSansTextTheme().copyWith(
      displayLarge: GoogleFonts.spaceGrotesk(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.text),
      headlineLarge: GoogleFonts.spaceGrotesk(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.text),
      headlineMedium: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
      titleLarge: GoogleFonts.spaceGrotesk(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.text),
      titleMedium: GoogleFonts.dmSans(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
      bodyLarge: GoogleFonts.dmSans(fontSize: 14, color: AppColors.text),
      bodyMedium: GoogleFonts.dmSans(fontSize: 13, color: AppColors.muted),
      labelSmall: GoogleFonts.dmSans(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.muted, letterSpacing: 0.6),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.card,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      shadowColor: AppColors.border,
      iconTheme: const IconThemeData(color: AppColors.text),
      titleTextStyle: GoogleFonts.spaceGrotesk(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.text),
    ),
  );
}

// Gradient helper
LinearGradient categoryGradient(String category) {
  final colors = {
    'Conference': AppColors.gradConference,
    'Sports':     AppColors.gradSports,
    'Workshop':   AppColors.gradWorkshop,
    'Social':     AppColors.gradSocial,
    'Art':        AppColors.gradArt,
    'Music':      AppColors.gradMusic,
    'Seminar':    AppColors.gradSeminar,
  }[category] ?? AppColors.gradOther;
  return LinearGradient(colors: colors, begin: Alignment.topLeft, end: Alignment.bottomRight);
}

// Category label i18n
String categoryLabel(String category, String lang) {
  final map = {
    'Conference': {'ru': 'Конференция', 'kz': 'Конференция', 'en': 'Conference'},
    'Sports':     {'ru': 'Спорт',       'kz': 'Спорт',       'en': 'Sports'},
    'Workshop':   {'ru': 'Воркшоп',     'kz': 'Воркшоп',     'en': 'Workshop'},
    'Social':     {'ru': 'Культура',    'kz': 'Мәдениет',    'en': 'Social'},
    'Art':        {'ru': 'Искусство',   'kz': 'Өнер',        'en': 'Art'},
    'Music':      {'ru': 'Музыка',      'kz': 'Музыка',      'en': 'Music'},
    'Seminar':    {'ru': 'Семинар',     'kz': 'Семинар',     'en': 'Seminar'},
  };
  return map[category]?[lang] ?? category;
}
