import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Naranja ladrillo — las paredes del contenedor ─────────────────────────
  static const Color naranja = Color(0xFFC0421A);       // terracota vivo (wall)
  static const Color naranjaOscuro = Color(0xFF8B2D09); // russet profundo (gradient end)
  static const Color naranjaClaro = Color(0xFFD4621F);  // naranja suave

  // ── Verde neón — el letrero de la entrada ─────────────────────────────────
  static const Color verde = Color(0xFF2EAE45);         // verde vivo (logo neon)
  static const Color verdeOscuro = Color(0xFF1D7A30);   // verde oscuro (texto legible)

  // Verde profundo para header (blanco sobre él: 6:1 ✅)
  static const Color verdeProfundo = Color(0xFF1A7A32);
  static const Color verdeMuyOscuro = Color(0xFF0F4E20);
  static const Color verdeClaro = Color(0xFFE8F5E9);    // superficie verde tenue

  // ── Alias para compatibilidad con el resto del código ─────────────────────
  // El NARANJA pasa a ser el acento/CTA (botones de acción)
  static const Color dorado = naranja;
  static const Color doradoClaro = naranjaClaro;
  // El VERDE es ahora el color identidad principal
  static const Color verdeOlivo = verde;
  // Barra de nav: espresso oscuro cálido
  static const Color verdeAppBar = Color(0xFF3D1A08);

  // ── Marca externa ─────────────────────────────────────────────────────────
  static const Color bancolombia = Color(0xFFFFCC00);   // amarillo Bancolombia (botón)
  static const Color azulTransferencia = Color(0xFF1E88E5); // azul consignación/transferencia
  static const Color doradoOscuro = Color(0xFFB8860B);  // dark goldenrod (Bancolombia pago)

  // ── Gradiente bebidas ─────────────────────────────────────────────────────
  static const Color azulBebida = Color(0xFF1B4F72);       // bebidas card — inicio
  static const Color azulBebidaOscuro = Color(0xFF0D2137); // bebidas card — fin

  // ── UI neutros adicionales ────────────────────────────────────────────────
  static const Color grisNeutro = Color(0xFF9E9E9E);    // gris navegación inactivo
  static const Color cafeNegro = Color(0xFF1C1408);     // espresso muy oscuro (textos fuertes)
  static const Color cremaAlerta = Color(0xFFFFF0E8);   // fondo badge alerta stock
  static const Color overlayClaro = Color(0x55000000);  // negro semitransparente 33%
  static const Color overlayMedio = Color(0x66000000);  // negro semitransparente 40%

  // ── Neutros cálidos ───────────────────────────────────────────────────────
  static const Color crema = Color(0xFFFEFAE0);
  static const Color cremaOscura = Color(0xFFF9EBC7);
  static const Color cafeMedio = Color(0xFFB99470);
  static const Color cafeClaro = Color(0xFF9A6440);
  static const Color cafeOscuro = Color(0xFF3D1A08);    // espresso oscuro (texto)

  // ── Estados de mesa ───────────────────────────────────────────────────────
  static const Color mesaLibre = Color(0xFFB99470);
  static const Color mesaOcupada = naranja;
  static const Color mesaPendiente = naranjaOscuro;
  static const Color mesaPagada = verde;

  // ── Tiempos en cocina ─────────────────────────────────────────────────────
  static const Color tiempoOk = verde;
  static const Color tiempoAlerta = naranja;
  static const Color tiempoCritico = naranjaOscuro;

  // ── UI general ────────────────────────────────────────────────────────────
  static const Color error = naranjaOscuro;
  static const Color exito = verde;
  // Fondo: blanco cálido — tarjetas y contenido se leen perfectamente
  static const Color fondo = Color(0xFFFFFCF5);
  static const Color superficie = Color(0xFFFFFFFF);
  // Texto secundario: café oscuro — 9:1 sobre blanco ✅ WCAG AAA
  static const Color textoSecundario = Color(0xFF5E3820);
}
