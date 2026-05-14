import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../data/models/order_model.dart';
import '../../controllers/kitchen_controller.dart';
import '../../widgets/error_retry.dart';
import '../../widgets/premium_app_bar.dart';

class KitchenScreen extends GetView<KitchenController> {
  const KitchenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: PremiumAppBar(
        titulo: 'Cocina',
        subtitulo: 'Pedidos en curso',
        trailing: Obx(() {
          final count = controller.pedidos.length;
          if (count == 0) return const SizedBox(width: 36, height: 36);
          return HeaderBadge(
            texto: '$count ${count == 1 ? 'pedido' : 'pedidos'}',
            color: AppColors.tiempoCritico,
          );
        }),
      ),
      body: Obx(() {
        if (controller.cargando.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.errorMsg.isNotEmpty) {
          return ErrorRetry(
            mensaje: controller.errorMsg.value,
            onRetry: controller.recargar,
          );
        }
        if (controller.pedidos.isEmpty) {
          return const _SinPedidos();
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          itemCount: controller.pedidos.length,
          itemBuilder: (_, i) => _OrderCard(
            pedido: controller.pedidos[i],
            ctrl: controller,
          ),
        );
      }),
    );
  }
}

// ── Tarjeta de pedido ─────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final OrderModel pedido;
  final KitchenController ctrl;

  const _OrderCard({required this.pedido, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      ctrl.ticker.value;
      final isDespachando = ctrl.despachando.contains(pedido.id);
      final color = ctrl.colorTiempo(pedido.fechaCreacion);

      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withAlpha(60),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(28),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: AppColors.cafeOscuro.withAlpha(12),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Barra lateral de urgencia
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 10,
                color: color,
              ),
              // Contenido
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OrderHeader(pedido: pedido, ctrl: ctrl, color: color),
                      const SizedBox(height: 12),
                      const Divider(height: 1, thickness: 1),
                      const SizedBox(height: 10),
                      ...pedido.items.asMap().entries.map((e) => _ItemTile(
                            item: e.value,
                            ultimo: e.key == pedido.items.length - 1,
                          )),
                      if (pedido.observaciones.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        _ObservacionRow(texto: pedido.observaciones),
                        const SizedBox(height: 6),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: isDespachando
                              ? null
                              : pedido.mesa != null
                                  ? () => ctrl.marcarDespachado(pedido.id)
                                  : () => ctrl.mostrarCobroSinMesa(
                                        context, pedido),
                          icon: isDespachando
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.crema,
                                  ),
                                )
                              : Icon(
                                  pedido.mesa != null
                                      ? Icons.whatshot_rounded
                                      : Icons.payments_outlined,
                                  size: 22,
                                ),
                          label: Text(
                            isDespachando
                                ? 'Procesando...'
                                : pedido.mesa != null
                                    ? 'Listo — Despachar'
                                    : 'Listo — Cobrar',
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.dorado,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

// ── Encabezado de pedido ──────────────────────────────────────────────────

class _OrderHeader extends StatelessWidget {
  final OrderModel pedido;
  final KitchenController ctrl;
  final Color color;

  const _OrderHeader({
    required this.pedido,
    required this.ctrl,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Número de orden — protagonista visual
        Text(
          '#${pedido.numeroOrden.toString().padLeft(3, '0')}',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.cafeOscuro,
            height: 1,
          ),
        ),
        if (pedido.mesa != null) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cremaOscura,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.table_restaurant_outlined,
                  size: 13,
                  color: AppColors.cafeMedio,
                ),
                const SizedBox(width: 4),
                Text(
                  'Mesa ${pedido.mesa}',
                  style: GoogleFonts.nunito(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cafeMedio,
                  ),
                ),
              ],
            ),
          ),
        ],
        const Spacer(),
        _TimerBadge(
          color: color,
          label: ctrl.etiquetaTiempo(pedido.fechaCreacion),
        ),
      ],
    );
  }
}

class _TimerBadge extends StatelessWidget {
  final Color color;
  final String label;

  const _TimerBadge({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.nunito(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fila de ítem ──────────────────────────────────────────────────────────

class _ItemTile extends StatelessWidget {
  final OrderItemModel item;
  final bool ultimo;

  const _ItemTile({required this.item, required this.ultimo});

  @override
  Widget build(BuildContext context) {
    final tieneSalsas = item.salsas.isNotEmpty;
    final tieneIngredientes = item.ingredientes.isNotEmpty;

    return Padding(
      padding: EdgeInsets.only(bottom: ultimo ? 0 : 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _CantidadBadge(cantidad: item.cantidad),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.nombre,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cafeOscuro,
                    height: 1.2,
                  ),
                ),
              ),
            ],
          ),
          if (tieneIngredientes) ...[
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: item.ingredientes
                    .map((ing) => _IngredienteChip(texto: ing))
                    .toList(),
              ),
            ),
          ],
          if (tieneSalsas) ...[
            const SizedBox(height: 5),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Wrap(
                spacing: 4,
                runSpacing: 4,
                children: item.salsas
                    .map((s) => _SalsaChip(texto: s))
                    .toList(),
              ),
            ),
          ],
          if (!ultimo) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, thickness: 0.6, indent: 42),
          ],
        ],
      ),
    );
  }
}

class _CantidadBadge extends StatelessWidget {
  final int cantidad;

  const _CantidadBadge({required this.cantidad});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.dorado,
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        '$cantidad',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _IngredienteChip extends StatelessWidget {
  final String texto;

  const _IngredienteChip({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.cremaOscura,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        texto,
        style: GoogleFonts.nunito(
          fontSize: 12,
          color: AppColors.cafeClaro,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SalsaChip extends StatelessWidget {
  final String texto;

  const _SalsaChip({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.verdeOlivo.withAlpha(20),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: AppColors.verdeOlivo.withAlpha(80),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            size: 11,
            color: AppColors.verdeOlivo,
          ),
          const SizedBox(width: 3),
          Text(
            texto,
            style: GoogleFonts.nunito(
              fontSize: 12,
              color: AppColors.verdeOscuro,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Observaciones ─────────────────────────────────────────────────────────

class _ObservacionRow extends StatelessWidget {
  final String texto;

  const _ObservacionRow({required this.texto});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.dorado.withAlpha(18),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.dorado.withAlpha(60),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.dorado),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              texto,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.cafeClaro,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado sin pedidos ────────────────────────────────────────────────────

class _SinPedidos extends StatelessWidget {
  const _SinPedidos();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.tiempoOk.withAlpha(18),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              size: 52,
              color: AppColors.tiempoOk,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Todo al día',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sin pedidos pendientes en cocina',
            style: AppTextStyles.cuerpoPequeno,
          ),
        ],
      ),
    );
  }
}
