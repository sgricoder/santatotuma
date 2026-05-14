import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTextStyles {
  // --- Títulos: Cormorant Garamond ---

  static TextStyle displayGrande = GoogleFonts.cormorantGaramond(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.cafeOscuro,
    letterSpacing: -0.5,
  );

  static TextStyle tituloPantalla = GoogleFonts.cormorantGaramond(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppColors.cafeOscuro,
  );

  static TextStyle tituloSeccion = GoogleFonts.cormorantGaramond(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.cafeOscuro,
  );

  static TextStyle subtitulo = GoogleFonts.cormorantGaramond(
    fontSize: 20,
    fontWeight: FontWeight.w500,
    color: AppColors.cafeOscuro,
  );

  // --- Cuerpo: Nunito ---

  static TextStyle cuerpoGrande = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppColors.cafeOscuro,
  );

  static TextStyle cuerpoNormal = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.cafeOscuro,
  );

  static TextStyle cuerpoPequeno = GoogleFonts.nunito(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textoSecundario,
  );

  static TextStyle etiqueta = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textoSecundario,
    letterSpacing: 0.5,
  );

  static TextStyle precio = GoogleFonts.nunito(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.verdeOlivo,
  );

  static TextStyle precioGrande = GoogleFonts.nunito(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.verdeOlivo,
  );

  static TextStyle boton = GoogleFonts.nunito(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.3,
  );

  static TextStyle badge = GoogleFonts.nunito(
    fontSize: 12,
    fontWeight: FontWeight.w800,
    color: Colors.white,
  );
}
