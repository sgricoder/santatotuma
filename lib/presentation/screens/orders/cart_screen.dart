import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/thousands_formatter.dart';
import '../../../data/models/order_model.dart';
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
  Worker? _nombreWorker;

  @override
  void initState() {
    super.initState();
    _nombreWorker = ever(widget.controller.nombreCliente, (String nombre) {
      if (_nombreCtrl.text != nombre) {
        _nombreCtrl.text = nombre;
        _nombreCtrl.selection =
            TextSelection.collapsed(offset: nombre.length);
      }
    });
  }

  @override
  void dispose() {
    _nombreWorker?.dispose();
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

          // Botones acción
          Obx(
            () {
              final sinNombre = ctrl.nombreCliente.value.trim().isEmpty;
              final ocupado = ctrl.enviando.value || sinNombre;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton.icon(
                    onPressed: ocupado ? null : ctrl.confirmar,
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
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: ocupado
                        ? null
                        : () => _PanelPagoSheet.mostrar(context, ctrl),
                    icon: const Icon(Icons.point_of_sale_rounded, size: 18),
                    label: Text(
                      sinNombre
                          ? 'Ingresa el nombre primero'
                          : 'Cobrar y enviar a cocina',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.verdeProfundo,
                      side: const BorderSide(
                          color: AppColors.verdeProfundo, width: 1.5),
                      minimumSize: const Size.fromHeight(50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ],
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

  void _onMesaTap(BuildContext context, int numero, EstadoMesa estado,
      String nombreCliente) {
    if (estado == EstadoMesa.libre) {
      controller.seleccionarMesa(numero);
      return;
    }
    final esPendiente = estado == EstadoMesa.pendienteCobro;
    final tieneNombre = nombreCliente.isNotEmpty;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          esPendiente ? 'Mesa $numero pendiente de cobro' : 'Mesa $numero ocupada',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.cafeOscuro,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (tieneNombre) ...[
              Row(
                children: [
                  const Icon(Icons.person_outline_rounded,
                      size: 15, color: AppColors.verdeOlivo),
                  const SizedBox(width: 6),
                  Text(
                    nombreCliente,
                    style: GoogleFonts.nunito(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.verdeOlivo,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            Text(
              esPendiente
                  ? 'Esta mesa está esperando cobro. ¿Quieres agregar un pedido nuevo? La mesa volverá a estado ocupada.'
                  : 'Esta mesa ya tiene pedidos activos. ¿Quieres agregar este pedido a la misma mesa?',
              style: GoogleFonts.nunito(fontSize: 14, color: AppColors.cafeMedio),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Cancelar',
                style: GoogleFonts.nunito(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () {
              controller.seleccionarMesa(numero);
              if (tieneNombre) controller.nombreCliente.value = nombreCliente;
              Navigator.of(context).pop();
            },
            child: Text(
              'Agregar pedido',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: AppColors.verdeOlivo,
              ),
            ),
          ),
        ],
      ),
    );
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
                  nombreCliente: mesa?.nombreCliente ?? '',
                  onTap: () => _onMesaTap(context, n, estado, mesa?.nombreCliente ?? ''),
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
  final String nombreCliente;
  final VoidCallback onTap;

  const _MesaChip({
    required this.label,
    required this.activo,
    required this.estado,
    required this.onTap,
    this.nombreCliente = '',
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
    final tieneCliente = nombreCliente.isNotEmpty &&
        (estado == EstadoMesa.ocupada || estado == EstadoMesa.pendienteCobro);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: tieneCliente ? null : (esTextoLargo ? null : 44),
        height: tieneCliente ? null : 44,
        padding: tieneCliente
            ? const EdgeInsets.symmetric(horizontal: 10, vertical: 6)
            : esTextoLargo
                ? const EdgeInsets.symmetric(horizontal: 14)
                : EdgeInsets.zero,
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _borderColor, width: 1.5),
        ),
        alignment: Alignment.center,
        child: tieneCliente
            ? Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (esPendiente)
                    Stack(
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
                          top: -8,
                          child: Icon(Icons.lock_outline,
                              size: 10, color: AppColors.mesaPendiente),
                        ),
                      ],
                    )
                  else
                    Text(
                      label,
                      style: AppTextStyles.etiqueta.copyWith(
                        color: _textColor,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 2),
                  Text(
                    nombreCliente,
                    style: GoogleFonts.nunito(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: activo
                          ? Colors.white.withAlpha(210)
                          : _textColor.withAlpha(200),
                    ),
                  ),
                ],
              )
            : esPendiente
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

// ── Panel de pago al pedir ─────────────────────────────────────────────────

class _PanelPagoSheet extends StatefulWidget {
  final CartController ctrl;
  const _PanelPagoSheet({required this.ctrl});

  static void mostrar(BuildContext context, CartController ctrl) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _PanelPagoSheet(ctrl: ctrl),
    );
  }

  @override
  State<_PanelPagoSheet> createState() => _PanelPagoSheetState();
}

class _PanelPagoSheetState extends State<_PanelPagoSheet> {
  MetodoPago _metodo = MetodoPago.efectivo;
  final _montoCtrl = TextEditingController();
  double _montoRecibido = 0;

  @override
  void dispose() {
    _montoCtrl.dispose();
    super.dispose();
  }

  double get _vuelto => _montoRecibido - widget.ctrl.total;

  void _confirmar() {
    Get.back(); // cierra sheet
    widget.ctrl.confirmarConPago(_metodo);
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.ctrl.total;
    final montos = [
      (total / 1000).ceil() * 1000,
      (total / 1000).ceil() * 1000 + 5000,
      (total / 1000).ceil() * 1000 + 10000,
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle
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

          // Título
          Text(
            'Cobrar y enviar a cocina',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Total: ${CurrencyFormatter.format(total)}',
            style: GoogleFonts.nunito(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.verdeProfundo,
            ),
          ),
          const SizedBox(height: 18),

          // Método de pago
          Row(
            children: MetodoPago.values.map((m) {
              final sel = _metodo == m;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _metodo = m;
                    _montoCtrl.clear();
                    _montoRecibido = 0;
                  }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: EdgeInsets.only(
                        right: m != MetodoPago.values.last ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: sel
                          ? AppColors.verdeProfundo
                          : AppColors.superficie,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: sel
                            ? AppColors.verdeProfundo
                            : AppColors.cafeClaro,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      m.etiqueta,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: sel ? Colors.white : AppColors.cafeMedio,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          // Panel efectivo
          if (_metodo == MetodoPago.efectivo) ...[
            const SizedBox(height: 16),
            // Chips de montos rápidos
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: montos.map((m) {
                  return GestureDetector(
                    onTap: () => setState(() {
                      _montoRecibido = m.toDouble();
                      _montoCtrl.text =
                          ThousandsFormatter.format(m.toDouble());
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.verdeClaro,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: AppColors.verdeProfundo.withAlpha(80)),
                      ),
                      child: Text(
                        CurrencyFormatter.format(m.toDouble()),
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.verdeProfundo,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            // Input monto
            TextField(
              controller: _montoCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [ThousandsFormatter()],
              decoration: InputDecoration(
                hintText: 'Monto recibido...',
                prefixIcon: const Icon(Icons.payments_outlined),
                filled: true,
                fillColor: AppColors.verdeClaro,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.verdeProfundo.withAlpha(80)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      BorderSide(color: AppColors.verdeProfundo.withAlpha(80)),
                ),
              ),
              onChanged: (v) {
                final raw = v.replaceAll('.', '').replaceAll(',', '');
                setState(
                    () => _montoRecibido = double.tryParse(raw) ?? 0);
              },
            ),
            // Vuelto
            if (_montoRecibido > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _vuelto >= 0
                      ? AppColors.verdeClaro
                      : AppColors.error.withAlpha(15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _vuelto >= 0
                        ? AppColors.verdeProfundo.withAlpha(80)
                        : AppColors.error.withAlpha(80),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _vuelto >= 0 ? 'Vuelto' : 'Faltan',
                      style: GoogleFonts.nunito(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _vuelto >= 0
                            ? AppColors.cafeMedio
                            : AppColors.error,
                      ),
                    ),
                    Text(
                      CurrencyFormatter.format(_vuelto.abs()),
                      style: GoogleFonts.nunito(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: _vuelto >= 0
                            ? AppColors.verdeProfundo
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],

          const SizedBox(height: 20),

          // Botón confirmar
          ElevatedButton.icon(
            onPressed: _metodo == MetodoPago.efectivo &&
                    _montoRecibido < total
                ? null
                : _confirmar,
            icon: const Icon(Icons.check_circle_outline_rounded),
            label: const Text('Confirmar y enviar a cocina'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.verdeProfundo,
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
