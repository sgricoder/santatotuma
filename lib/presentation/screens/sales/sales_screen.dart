import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../controllers/sales_controller.dart';
import '../../widgets/premium_app_bar.dart';

class SalesScreen extends GetView<SalesController> {
  const SalesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: PremiumAppBar(
        titulo: 'Reportes',
        subtitulo: 'Ventas y estadísticas',
        icono: Icons.bar_chart_rounded,
      ),
      body: Column(
        children: [
          _SelectorPeriodo(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.cargando.value) {
                return const Center(child: CircularProgressIndicator());
              }
              return RefreshIndicator(
                onRefresh: controller.cargar,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                  children: [
                    _ResumenCards(ctrl: controller),
                    const SizedBox(height: 20),
                    if (controller.pedidos.isNotEmpty) ...[
                      _GraficaVentas(ctrl: controller),
                      const SizedBox(height: 20),
                      _DesglosePago(ctrl: controller),
                      const SizedBox(height: 20),
                      _TopProductos(ctrl: controller),
                    ] else
                      const _SinDatos(),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Selector de período ───────────────────────────────────────────────────

class _SelectorPeriodo extends StatelessWidget {
  final SalesController controller;
  const _SelectorPeriodo({required this.controller});

  @override
  Widget build(BuildContext context) {
    const opciones = ['Hoy', 'Semana', 'Mes'];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Obx(
        () => Row(
          children: List.generate(
            opciones.length,
            (i) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: i > 0 ? 8 : 0),
                child: GestureDetector(
                  onTap: () => controller.periodoActivo.value = i,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: controller.periodoActivo.value == i
                          ? AppColors.verdeOlivo
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: controller.periodoActivo.value == i
                            ? AppColors.verdeOlivo
                            : AppColors.cremaOscura,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      opciones[i],
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: controller.periodoActivo.value == i
                            ? AppColors.crema
                            : AppColors.cafeMedio,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Tarjetas de resumen ───────────────────────────────────────────────────

class _ResumenCards extends StatelessWidget {
  final SalesController ctrl;
  const _ResumenCards({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: _StatCard(
            label: 'Total',
            valor: CurrencyFormatter.format(ctrl.totalVentas),
            icono: Icons.attach_money,
            color: AppColors.verdeOlivo,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: _StatCard(
            label: 'Órdenes',
            valor: '${ctrl.numOrdenes}',
            icono: Icons.receipt_long_outlined,
            color: AppColors.dorado,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 4,
          child: _StatCard(
            label: 'Promedio',
            valor: CurrencyFormatter.format(ctrl.ticketPromedio),
            icono: Icons.trending_up,
            color: AppColors.cafeMedio,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String valor;
  final IconData icono;
  final Color color;

  const _StatCard({
    required this.label,
    required this.valor,
    required this.icono,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icono, size: 18, color: color),
          const SizedBox(height: 6),
          Text(
            valor,
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.cafeOscuro,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 11,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Gráfica de barras ─────────────────────────────────────────────────────

class _GraficaVentas extends StatelessWidget {
  final SalesController ctrl;
  const _GraficaVentas({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final datos = ctrl.getDatosGrafica();
    if (datos.isEmpty) return const SizedBox.shrink();

    final maxY = datos.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    final yMax = maxY <= 0 ? 1.0 : maxY * 1.25;

    final titulo = switch (ctrl.periodoActivo.value) {
      0 => 'Ventas por hora',
      1 => 'Ventas por día',
      _ => 'Ventas por semana',
    };

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: yMax,
                barGroups: datos.asMap().entries.map((entry) {
                  final isMax = entry.value.value == maxY;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: isMax
                            ? AppColors.dorado
                            : AppColors.verdeOlivo,
                        width: datos.length <= 7 ? 20 : 12,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx >= datos.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            datos[idx].key,
                            style: GoogleFonts.nunito(
                              fontSize: 11,
                              color: AppColors.textoSecundario,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(show: false),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipColor: (_) => AppColors.cafeOscuro,
                    getTooltipItem: (group, _, rod, __) => BarTooltipItem(
                      CurrencyFormatter.format(rod.toY),
                      GoogleFonts.nunito(
                        color: AppColors.crema,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Desglose por método de pago ───────────────────────────────────────────

class _DesglosePago extends StatelessWidget {
  final SalesController ctrl;
  const _DesglosePago({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final efectivo = ctrl.totalEfectivo;
    final bancolombia = ctrl.totalBancolombia;
    final total = efectivo + bancolombia;
    if (total == 0) return const SizedBox.shrink();

    final pctEfectivo = efectivo / total;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Método de pago',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 14),
          // Barra de progreso bicolor
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  Flexible(
                    flex: (pctEfectivo * 100).round(),
                    child: Container(color: AppColors.verdeOlivo),
                  ),
                  Flexible(
                    flex: ((1 - pctEfectivo) * 100).round(),
                    child: Container(color: AppColors.azulTransferencia),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _PagoItem(
                label: 'Efectivo',
                valor: CurrencyFormatter.format(efectivo),
                porcentaje: pctEfectivo,
                color: AppColors.verdeOlivo,
              ),
              const SizedBox(width: 16),
              _PagoItem(
                label: 'Bancolombia',
                valor: CurrencyFormatter.format(bancolombia),
                porcentaje: 1 - pctEfectivo,
                color: AppColors.bancolombia,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PagoItem extends StatelessWidget {
  final String label;
  final String valor;
  final double porcentaje;
  final Color color;

  const _PagoItem({
    required this.label,
    required this.valor,
    required this.porcentaje,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    color: AppColors.textoSecundario,
                  ),
                ),
                Text(
                  '$valor  (${(porcentaje * 100).toStringAsFixed(0)}%)',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cafeOscuro,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Top 5 productos ───────────────────────────────────────────────────────

class _TopProductos extends StatelessWidget {
  final SalesController ctrl;
  const _TopProductos({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final top = ctrl.getTopProductos();
    if (top.isEmpty) return const SizedBox.shrink();

    final maxUnidades = top.first.value;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Más vendidos',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 12),
          ...top.asMap().entries.map(
            (entry) => _TopItem(
              posicion: entry.key + 1,
              nombre: entry.value.key,
              unidades: entry.value.value,
              maxUnidades: maxUnidades,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopItem extends StatelessWidget {
  final int posicion;
  final String nombre;
  final int unidades;
  final int maxUnidades;

  const _TopItem({
    required this.posicion,
    required this.nombre,
    required this.unidades,
    required this.maxUnidades,
  });

  @override
  Widget build(BuildContext context) {
    final pct = maxUnidades > 0 ? unidades / maxUnidades : 0.0;
    final esTop = posicion == 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 22,
            child: Text(
              '$posicion',
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: esTop ? AppColors.dorado : AppColors.textoSecundario,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 5,
                    backgroundColor: AppColors.cremaOscura,
                    valueColor: AlwaysStoppedAnimation(
                      esTop ? AppColors.dorado : AppColors.verdeOlivo,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$unidades ud.',
            style: GoogleFonts.nunito(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.cafeMedio,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado sin datos ──────────────────────────────────────────────────────

class _SinDatos extends StatelessWidget {
  const _SinDatos();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 60),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.bar_chart_outlined,
            size: 72,
            color: AppColors.cremaOscura,
          ),
          const SizedBox(height: 16),
          Text(
            'Sin ventas en este período',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Las ventas aparecen aquí cuando\nse cobra un pedido',
            style: GoogleFonts.nunito(
              fontSize: 14,
              color: AppColors.textoSecundario,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
