import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/table_model.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/tables_controller.dart';
import '../../widgets/cart_item_widget.dart';
import '../../widgets/premium_app_bar.dart';

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  void _confirmarVaciar(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Vaciar comanda',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.cafeOscuro,
          ),
        ),
        content: Text(
          '¿Eliminar todos los productos de esta comanda?',
          style: GoogleFonts.nunito(fontSize: 14, color: AppColors.cafeMedio),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(
              'Cancelar',
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.cafeMedio,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              controller.limpiar();
              Navigator.of(context).pop();
            },
            child: Text(
              'Vaciar todo',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: PremiumAppBar(
        titulo: 'Comanda',
        subtitulo: 'Tu pedido',
        mostrarBack: true,
        trailing: Obx(() => controller.estaVacio
            ? const SizedBox(width: 36, height: 36)
            : _VaciarBtn(onTap: () => _confirmarVaciar(context))),
      ),
      body: Obx(() {
        if (controller.estaVacio) return const _ComandaVacia();
        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: controller.items.length,
                itemBuilder: (_, i) =>
                    CartItemWidget(item: controller.items[i]),
              ),
            ),
            _PanelInferior(controller: controller),
          ],
        );
      }),
    );
  }
}

// ── Botón vaciar (trailing del AppBar) ────────────────────────────────────

class _VaciarBtn extends StatelessWidget {
  final VoidCallback onTap;
  const _VaciarBtn({required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withAlpha(40)),
          ),
          child: const Icon(
            Icons.delete_sweep_outlined,
            color: Colors.white,
            size: 20,
          ),
        ),
      );
}

// ── Panel inferior ─────────────────────────────────────────────────────────

class _PanelInferior extends StatefulWidget {
  final CartController controller;
  const _PanelInferior({required this.controller});

  @override
  State<_PanelInferior> createState() => _PanelInferiorState();
}

class _PanelInferiorState extends State<_PanelInferior> {
  final _nombreCtrl = TextEditingController();
  final _notasCtrl = TextEditingController();

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.controller;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(22),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle visual
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.cremaOscura,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Nombre del cliente
          TextField(
            controller: _nombreCtrl,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              hintText: 'A nombre de...',
              prefixIcon: Icon(Icons.person_outline_rounded),
            ),
            maxLines: 1,
            textInputAction: TextInputAction.next,
            onChanged: (v) => ctrl.nombreCliente.value = v,
          ),
          const SizedBox(height: 14),

          // Mesa
          Row(
            children: [
              const Icon(
                Icons.table_restaurant_outlined,
                size: 15,
                color: AppColors.cafeMedio,
              ),
              const SizedBox(width: 6),
              Text('Mesa (opcional)', style: AppTextStyles.etiqueta),
            ],
          ),
          const SizedBox(height: 8),
          _SelectorMesa(controller: ctrl),
          const SizedBox(height: 14),

          // Notas
          TextField(
            controller: _notasCtrl,
            decoration: const InputDecoration(
              hintText: 'Observaciones (ej: sin cebolla...)',
              prefixIcon: Icon(Icons.edit_note_outlined),
            ),
            maxLines: 1,
            textInputAction: TextInputAction.done,
            onChanged: (v) => ctrl.notas.value = v,
          ),
          const SizedBox(height: 16),

          const Divider(thickness: 1),
          const SizedBox(height: 12),

          // Total
          Obx(
            () => Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.cormorantGaramond(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors.cafeOscuro,
                  ),
                ),
                Text(
                  CurrencyFormatter.format(ctrl.total),
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppColors.verdeOlivo,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Botón enviar a cocina
          Obx(
            () {
              final sinNombre = ctrl.nombreCliente.value.trim().isEmpty;
              return ElevatedButton.icon(
                onPressed: ctrl.enviando.value || sinNombre
                    ? null
                    : ctrl.confirmar,
                icon: ctrl.enviando.value
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.crema,
                        ),
                      )
                    : const Icon(Icons.whatshot_rounded),
                label: Text(
                  ctrl.enviando.value ? 'Enviando...' : 'Enviar a cocina',
                ),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// ── Selector de mesa ───────────────────────────────────────────────────────

class _SelectorMesa extends StatelessWidget {
  final CartController controller;
  const _SelectorMesa({required this.controller});

  void _onMesaTap(BuildContext context, int numero, EstadoMesa estado) {
    if (estado == EstadoMesa.pendienteCobro) {
      Get.snackbar(
        'Mesa $numero bloqueada',
        'Está esperando cobro — ciérrala en la pestaña Mesas primero',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
        backgroundColor: AppColors.mesaPendiente.withAlpha(220),
        colorText: Colors.white,
      );
      return;
    }
    if (estado == EstadoMesa.ocupada) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Mesa $numero ocupada',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.cafeOscuro,
            ),
          ),
          content: Text(
            'Esta mesa ya tiene pedidos activos. ¿Quieres agregar este pedido a la misma mesa?',
            style: GoogleFonts.nunito(
                fontSize: 14, color: AppColors.cafeMedio),
          ),
          actions: [
            TextButton(
              onPressed: Navigator.of(context).pop,
              child: Text('Cancelar',
                  style:
                      GoogleFonts.nunito(color: AppColors.cafeMedio)),
            ),
            TextButton(
              onPressed: () {
                controller.seleccionarMesa(numero);
                Navigator.of(context).pop();
              },
              child: Text(
                'Agregar de todas formas',
                style: GoogleFonts.nunito(
                  fontWeight: FontWeight.w700,
                  color: AppColors.verdeOlivo,
                ),
              ),
            ),
          ],
        ),
      );
      return;
    }
    controller.seleccionarMesa(numero);
  }

  @override
  Widget build(BuildContext context) {
    final tablesCtrl = Get.find<TablesController>();
    return Obx(() {
      final mesas = tablesCtrl.mesas;
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _MesaChip(
              label: 'Sin mesa',
              activo: controller.mesa.value == null,
              estado: null,
              onTap: () => controller.seleccionarMesa(null),
            ),
            const SizedBox(width: 6),
            ...List.generate(15, (i) {
              final n = i + 1;
              final mesa =
                  mesas.firstWhereOrNull((m) => m.numero == n);
              final estado = mesa?.estado ?? EstadoMesa.libre;
              return Padding(
                padding: const EdgeInsets.only(right: 6),
                child: _MesaChip(
                  label: '$n',
                  activo: controller.mesa.value == n,
                  estado: estado,
                  onTap: () => _onMesaTap(context, n, estado),
                ),
              );
            }),
          ],
        ),
      );
    });
  }
}

class _MesaChip extends StatelessWidget {
  final String label;
  final bool activo;
  final EstadoMesa? estado;
  final VoidCallback onTap;

  const _MesaChip({
    required this.label,
    required this.activo,
    required this.estado,
    required this.onTap,
  });

  Color get _bgColor {
    if (activo) return AppColors.verdeOlivo;
    return switch (estado) {
      EstadoMesa.ocupada => AppColors.mesaOcupada.withAlpha(35),
      EstadoMesa.pendienteCobro => AppColors.mesaPendiente.withAlpha(25),
      EstadoMesa.pagada => AppColors.mesaPagada.withAlpha(25),
      _ => Colors.white,
    };
  }

  Color get _borderColor {
    if (activo) return AppColors.verdeOlivo;
    return switch (estado) {
      EstadoMesa.ocupada => AppColors.mesaOcupada,
      EstadoMesa.pendienteCobro => AppColors.mesaPendiente,
      EstadoMesa.pagada => AppColors.mesaPagada,
      _ => AppColors.cafeClaro,
    };
  }

  Color get _textColor {
    if (activo) return AppColors.crema;
    return switch (estado) {
      EstadoMesa.ocupada => AppColors.doradoOscuro,
      EstadoMesa.pendienteCobro => AppColors.mesaPendiente,
      EstadoMesa.pagada => AppColors.mesaPagada,
      _ => AppColors.cafeOscuro,
    };
  }

  @override
  Widget build(BuildContext context) {
    final esPendiente = estado == EstadoMesa.pendienteCobro;
    final esTextoLargo = label.length > 2;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: esTextoLargo ? null : 44,
        height: 44,
        padding: esTextoLargo
            ? const EdgeInsets.symmetric(horizontal: 14)
            : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: esPendiente
            ? Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.etiqueta.copyWith(
                      color: _textColor,
                      fontSize: 13,
                    ),
                  ),
                  Positioned(
                    right: -9,
                    top: -10,
                    child: Icon(
                      Icons.lock_outline,
                      size: 11,
                      color: AppColors.mesaPendiente,
                    ),
                  ),
                ],
              )
            : Text(
                label,
                style: AppTextStyles.etiqueta.copyWith(
                  color: _textColor,
                  fontSize: 13,
                ),
              ),
      ),
    );
  }
}

// ── Comanda vacía ──────────────────────────────────────────────────────────

class _ComandaVacia extends StatelessWidget {
  const _ComandaVacia();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.verdeOlivo.withAlpha(15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 44,
              color: AppColors.verdeOlivo,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Comanda vacía',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Agrega productos desde el menú',
            style: AppTextStyles.cuerpoPequeno,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          OutlinedButton.icon(
            onPressed: Get.back,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Volver al menú'),
          ),
        ],
      ),
    );
  }
}
