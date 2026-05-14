import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/inventory_model.dart';
import '../../controllers/inventory_controller.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/premium_app_bar.dart';

class InventoryScreen extends GetView<InventoryController> {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: PremiumAppBar(
        titulo: 'Inventario',
        subtitulo: 'Control de insumos',
        mostrarBack: true,
        trailing: Obx(() {
          final bajo = controller.totalBajoStock;
          if (bajo == 0) return const SizedBox(width: 36, height: 36);
          return GestureDetector(
            onTap: () => controller.mostrarBajoStock(context),
            child: HeaderBadge(
              texto: '$bajo bajo stock',
              color: AppColors.tiempoAlerta,
            ),
          );
        }),
      ),
      body: Column(
        children: [
          _Buscador(controller: controller),
          _FiltrosCategorias(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.cargando.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMsg.isNotEmpty) {
                return ErrorRetry(
                  mensaje: controller.errorMsg.value,
                  onRetry: controller.recargar,
                );
              }
              final lista = controller.filtrados;
              if (lista.isEmpty) return const _SinResultados();
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                itemCount: lista.length,
                itemBuilder: (_, i) {
                  final mostrarHeader = i == 0 ||
                      lista[i].categoria != lista[i - 1].categoria;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (mostrarHeader)
                        _CategoriaHeader(categoria: lista[i].categoria),
                      _InsumoTile(
                        insumo: lista[i],
                        onTap: () => controller.abrirMovimiento(
                            context, lista[i]),
                      ),
                    ],
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }
}

// ── Buscador ──────────────────────────────────────────────────────────────

class _Buscador extends StatelessWidget {
  final InventoryController controller;
  const _Buscador({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.superficie,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: TextField(
        onChanged: controller.buscar,
        decoration: InputDecoration(
          hintText: 'Buscar insumo...',
          prefixIcon: const Icon(Icons.search, size: 20),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}

// ── Filtros de categoría ──────────────────────────────────────────────────

class _FiltrosCategorias extends StatelessWidget {
  final InventoryController controller;
  const _FiltrosCategorias({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.superficie,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
        child: Obx(
          () => Row(
            children: [
              _Chip(
                label: 'Todos',
                activo: controller.categoriaActiva.value == null,
                onTap: () => controller.seleccionarCategoria(null),
              ),
              ...CategoriaInsumo.values.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _Chip(
                    label: cat.etiqueta,
                    activo: controller.categoriaActiva.value == cat,
                    onTap: () => controller.seleccionarCategoria(cat),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  const _Chip({required this.label, required this.activo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: activo ? AppColors.verdeOlivo : AppColors.cremaOscura,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: activo ? AppColors.crema : AppColors.cafeOscuro,
          ),
        ),
      ),
    );
  }
}

// ── Header de categoría ───────────────────────────────────────────────────

class _CategoriaHeader extends StatelessWidget {
  final CategoriaInsumo categoria;
  const _CategoriaHeader({required this.categoria});

  static const _iconos = {
    CategoriaInsumo.carnes: Icons.set_meal_outlined,
    CategoriaInsumo.vegetales: Icons.eco_outlined,
    CategoriaInsumo.lacteos: Icons.icecream_outlined,
    CategoriaInsumo.salsas: Icons.water_drop_outlined,
    CategoriaInsumo.empaque: Icons.inventory_2_outlined,
    CategoriaInsumo.otros: Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(
        children: [
          Icon(
            _iconos[categoria] ?? Icons.category_outlined,
            size: 15,
            color: AppColors.verdeOlivo,
          ),
          const SizedBox(width: 6),
          Text(
            categoria.etiqueta.toUpperCase(),
            style: GoogleFonts.nunito(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.verdeOlivo,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tile de insumo ────────────────────────────────────────────────────────

class _InsumoTile extends StatelessWidget {
  final InventoryItemModel insumo;
  final VoidCallback onTap;
  const _InsumoTile({required this.insumo, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final agotado = insumo.cantidadActual == 0;
    final bajo = insumo.esBajoStock;
    final pct = insumo.stockMinimo > 0
        ? (insumo.cantidadActual / (insumo.stockMinimo * 2)).clamp(0.0, 1.0)
        : 1.0;

    final Color borderColor = agotado
        ? AppColors.tiempoCritico
        : bajo
            ? AppColors.tiempoAlerta.withAlpha(200)
            : Colors.transparent;

    final Color bgColor = agotado
        ? AppColors.tiempoCritico.withAlpha(14)
        : bajo
            ? AppColors.tiempoAlerta.withAlpha(10)
            : Colors.white;

    final Color cantidadColor = agotado
        ? AppColors.tiempoCritico
        : bajo
            ? AppColors.tiempoAlerta
            : AppColors.verdeOlivo;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(14),
          border: bajo
              ? Border.all(color: borderColor, width: agotado ? 2 : 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: AppColors.cafeOscuro.withAlpha(bajo ? 22 : 12),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            _NivelIndicator(pct: pct, bajo: bajo, agotado: agotado),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          insumo.nombre,
                          style: GoogleFonts.nunito(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: bajo
                                ? AppColors.tiempoCritico
                                : AppColors.cafeOscuro,
                          ),
                        ),
                      ),
                      if (agotado)
                        _EstadoChip(
                          label: 'Agotado',
                          color: AppColors.tiempoCritico,
                        )
                      else if (bajo)
                        _EstadoChip(
                          label: 'Bajo',
                          color: AppColors.tiempoAlerta,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _BarraStock(pct: pct, bajo: bajo),
                ],
              ),
            ),
            const SizedBox(width: 12),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  insumo.cantidadActual % 1 == 0
                      ? '${insumo.cantidadActual.toInt()}'
                      : '${insumo.cantidadActual}',
                  style: GoogleFonts.nunito(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: cantidadColor,
                  ),
                ),
                Text(
                  insumo.unidad,
                  style: GoogleFonts.nunito(
                    fontSize: 11,
                    color: AppColors.textoSecundario,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NivelIndicator extends StatelessWidget {
  final double pct;
  final bool bajo;
  final bool agotado;
  const _NivelIndicator(
      {required this.pct, required this.bajo, this.agotado = false});

  @override
  Widget build(BuildContext context) {
    final color = agotado
        ? AppColors.tiempoCritico
        : bajo
            ? AppColors.tiempoAlerta
            : AppColors.tiempoOk;
    // Agotado: show full bar in red (pct would be 0, useless visually)
    final barPct = agotado ? 1.0 : pct;
    return Container(
      width: 6,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.cremaOscura,
        borderRadius: BorderRadius.circular(3),
      ),
      alignment: Alignment.bottomCenter,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        width: 6,
        height: 48 * barPct,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
  }
}

class _EstadoChip extends StatelessWidget {
  final String label;
  final Color color;
  const _EstadoChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withAlpha(80), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BarraStock extends StatelessWidget {
  final double pct;
  final bool bajo;
  const _BarraStock({required this.pct, required this.bajo});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: pct,
        minHeight: 5,
        backgroundColor: AppColors.cremaOscura,
        valueColor: AlwaysStoppedAnimation(
          bajo ? AppColors.tiempoCritico : AppColors.tiempoOk,
        ),
      ),
    );
  }
}


// ── Sin resultados ────────────────────────────────────────────────────────

class _SinResultados extends StatelessWidget {
  const _SinResultados();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.search_off, size: 64, color: AppColors.cremaOscura),
          const SizedBox(height: 12),
          Text(
            'Sin insumos encontrados',
            style: GoogleFonts.nunito(
              fontSize: 15,
              color: AppColors.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}
