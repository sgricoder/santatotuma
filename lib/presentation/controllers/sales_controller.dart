import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

class SalesController extends GetxController {
  OrderRepository get _repo => Get.find<OrderRepository>();

  // 0=hoy  1=semana  2=mes
  final periodoActivo = 0.obs;
  final cargando = false.obs;
  final pedidos = <OrderModel>[].obs;

  // ── Resumen derivado ──────────────────────────────────────────────────

  double get totalVentas => pedidos.fold(0.0, (s, p) => s + p.total);
  int get numOrdenes => pedidos.length;
  double get ticketPromedio => numOrdenes > 0 ? totalVentas / numOrdenes : 0;

  double get totalEfectivo => pedidos
      .where((p) => p.metodoPago == MetodoPago.efectivo)
      .fold(0.0, (s, p) => s + p.total);

  double get totalBancolombia => pedidos
      .where((p) => p.metodoPago == MetodoPago.bancolombia)
      .fold(0.0, (s, p) => s + p.total);

  @override
  void onInit() {
    super.onInit();
    cargar();
    ever(periodoActivo, (_) => cargar());
  }

  Future<void> cargar() async {
    cargando.value = true;
    try {
      final ahora = DateTime.now();
      late DateTime desde;
      late DateTime hasta;

      switch (periodoActivo.value) {
        case 0: // hoy
          desde = DateTime(ahora.year, ahora.month, ahora.day);
          hasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        case 1: // semana — lunes a hoy
          final lunes = ahora.subtract(Duration(days: ahora.weekday - 1));
          desde = DateTime(lunes.year, lunes.month, lunes.day);
          hasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        case 2: // mes — día 1 a hoy
          desde = DateTime(ahora.year, ahora.month, 1);
          hasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
        default:
          desde = DateTime(ahora.year, ahora.month, ahora.day);
          hasta = DateTime(ahora.year, ahora.month, ahora.day, 23, 59, 59);
      }

      pedidos.value = await _repo.getPorFecha(desde, hasta);
    } catch (e) {
      debugPrint('❌ SalesController.cargar: $e');
    } finally {
      cargando.value = false;
    }
  }

  // ── Datos para gráfica de barras ──────────────────────────────────────

  /// Retorna pares (etiqueta, total) para el período activo.
  List<MapEntry<String, double>> getDatosGrafica() {
    if (pedidos.isEmpty) return [];

    switch (periodoActivo.value) {
      case 0: // hoy — agrupar por hora
        final Map<int, double> porHora = {};
        for (final p in pedidos) {
          final h = p.fechaCreacion.hour;
          porHora[h] = (porHora[h] ?? 0) + p.total;
        }
        final lista = porHora.entries
            .map((e) => MapEntry('${e.key}h', e.value))
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));
        return lista;

      case 1: // semana — 7 días (lunes a domingo)
        const etiquetas = ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
        final Map<int, double> porDia = {
          for (int i = 1; i <= 7; i++) i: 0.0
        };
        for (final p in pedidos) {
          final d = p.fechaCreacion.weekday;
          porDia[d] = (porDia[d] ?? 0) + p.total;
        }
        return List.generate(
          7,
          (i) => MapEntry(etiquetas[i], porDia[i + 1]!),
        );

      case 2: // mes — agrupar por semana (S1-S5)
        final Map<int, double> porSemana = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
        for (final p in pedidos) {
          final sem = ((p.fechaCreacion.day - 1) ~/ 7) + 1;
          porSemana[sem] = (porSemana[sem] ?? 0) + p.total;
        }
        return [1, 2, 3, 4, 5]
            .map((s) => MapEntry('S$s', porSemana[s]!))
            .toList();

      default:
        return [];
    }
  }

  // ── Top 5 productos por unidades vendidas ─────────────────────────────

  List<MapEntry<String, int>> getTopProductos() {
    final Map<String, int> conteos = {};
    for (final p in pedidos) {
      for (final item in p.items) {
        conteos[item.nombre] = (conteos[item.nombre] ?? 0) + item.cantidad;
      }
    }
    return (conteos.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .take(5)
        .toList();
  }
}
