import 'package:flutter/material.dart';

abstract final class AppColors {
  // Paleta Santa Totuma — earthy artisan
  static const Color verdeOlivo = Color(0xFFA9B388);   // Laurel Green
  static const Color dorado = Color(0xFFC4661F);        // Alloy Orange
  static const Color crema = Color(0xFFFEFAE0);         // Cornsilk
  static const Color cafeOscuro = Color(0xFF783D19);    // Russet

  // Variantes
  static const Color verdeOscuro = Color(0xFF7A8F68);   // Darker Laurel
  static const Color doradoClaro = Color(0xFFD4813E);   // Lighter Orange
  static const Color cremaOscura = Color(0xFFF9EBC7);   // Lemon Meringue
  static const Color cafeClaro = Color(0xFF9A6440);
  static const Color cafeMedio = Color(0xFFB99470);     // Camel

  // Estados de mesa
  static const Color mesaLibre = Color(0xFFB99470);     // Camel — neutral/disponible
  static const Color mesaOcupada = Color(0xFFC4661F);   // Alloy Orange — activa
  static const Color mesaPendiente = Color(0xFF783D19); // Russet — cobro pendiente
  static const Color mesaPagada = Color(0xFFA9B388);    // Laurel Green — pagada

  // Estados de tiempo en cocina
  static const Color tiempoOk = Color(0xFFA9B388);      // Laurel Green
  static const Color tiempoAlerta = Color(0xFFC4661F);  // Alloy Orange
  static const Color tiempoCritico = Color(0xFF783D19); // Russet

  // UI general
  static const Color error = Color(0xFF783D19);
  static const Color exito = Color(0xFFA9B388);
  static const Color fondo = crema;
  static const Color superficie = Color(0xFFFEFAE0);
  static const Color textoSecundario = cafeMedio;
}
