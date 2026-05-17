import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

final class AppTheme {
  static ThemeData get tema {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: AppColors.verdeProfundo,
        onPrimary: Colors.white,
        primaryContainer: AppColors.verdeMuyOscuro,
        onPrimaryContainer: AppColors.crema,
        secondary: AppColors.naranja,
        onSecondary: Colors.white,
        secondaryContainer: AppColors.naranjaOscuro,
        onSecondaryContainer: AppColors.crema,
        surface: AppColors.superficie,
        onSurface: AppColors.cafeOscuro,
        surfaceContainerHighest: AppColors.cremaOscura,
        error: AppColors.error,
        onError: Colors.white,
        outline: AppColors.cafeMedio,
      ),
      scaffoldBackgroundColor: AppColors.fondo,
      textTheme: GoogleFonts.nunitoTextTheme().copyWith(
        displayLarge: GoogleFonts.cormorantGaramond(
          fontSize: 48, fontWeight: FontWeight.w700, color: AppColors.cafeOscuro,
        ),
        displayMedium: GoogleFonts.cormorantGaramond(
          fontSize: 36, fontWeight: FontWeight.w600, color: AppColors.cafeOscuro,
        ),
        headlineLarge: GoogleFonts.cormorantGaramond(
          fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.cafeOscuro,
        ),
        headlineMedium: GoogleFonts.cormorantGaramond(
          fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.cafeOscuro,
        ),
        headlineSmall: GoogleFonts.cormorantGaramond(
          fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.cafeOscuro,
        ),
        titleLarge: GoogleFonts.nunito(
          fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.cafeOscuro,
        ),
        bodyLarge: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w400, color: AppColors.cafeOscuro,
        ),
        bodyMedium: GoogleFonts.nunito(
          fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.cafeOscuro,
        ),
        labelLarge: GoogleFonts.nunito(
          fontSize: 16, fontWeight: FontWeight.w700,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.verdeProfundo,
        foregroundColor: AppColors.crema,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cormorantGaramond(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.crema,
          letterSpacing: 0.3,
        ),
        iconTheme: const IconThemeData(color: AppColors.crema),
        actionsIconTheme: const IconThemeData(color: AppColors.crema),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: AppColors.verdeProfundo,
        elevation: 16,
        shadowColor: AppColors.verdeProfundo,
        surfaceTintColor: Colors.transparent,
        height: 65,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: Colors.white, size: 24);
          }
          return const IconThemeData(color: AppColors.grisNeutro, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.nunito(
              fontSize: 11, fontWeight: FontWeight.w700,
              color: AppColors.verdeProfundo,
            );
          }
          return GoogleFonts.nunito(
            fontSize: 11, fontWeight: FontWeight.w500,
            color: AppColors.grisNeutro,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.naranja,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.cremaOscura,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.dorado,
          side: const BorderSide(color: AppColors.dorado, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          textStyle: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.dorado,
          textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.superficie,
        elevation: 2,
        shadowColor: AppColors.cafeOscuro.withAlpha(40),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: EdgeInsets.zero,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.dorado,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: CircleBorder(),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.cremaOscura,
        selectedColor: AppColors.dorado,
        labelStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.cafeOscuro),
        secondaryLabelStyle: GoogleFonts.nunito(fontSize: 13, color: AppColors.crema),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide.none,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.superficie,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cafeClaro),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.cafeClaro),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.dorado, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.nunito(color: AppColors.textoSecundario),
        labelStyle: GoogleFonts.nunito(color: AppColors.textoSecundario),
        prefixIconColor: AppColors.textoSecundario,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.cafeOscuro,
        contentTextStyle: GoogleFonts.nunito(color: AppColors.crema, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.cafeMedio,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.dorado,
      ),
    );
  }
}
