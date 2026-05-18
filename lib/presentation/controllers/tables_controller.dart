import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../data/models/order_model.dart';
import '../../data/models/table_model.dart';
import '../../data/models/tesoreria_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/table_repository.dart';
import '../../data/repositories/tesoreria_repository.dart';

class TablesController extends GetxController {
  TableRepository get _tableRepo => Get.find<TableRepository>();
  OrderRepository get _orderRepo => Get.find<OrderRepository>();

  final mesas = <TableModel>[].obs;
  final cargando = true.obs;
  final procesando = RxSet<int>({});
  final ordenesPorMesa = <int, List<OrderModel>>{}.obs;

  StreamSubscription? _sub;
  StreamSubscription? _subOrdenes;

  @override
  void onInit() {
    super.onInit();
    _tableRepo.inicializarMesas();
    _sub = _tableRepo.watchMesas().listen(
      (lista) {
        mesas.value = lista;
        cargando.value = false;
      },
      onError: (e, st) {
        debugPrint('❌ TablesController: $e\n$st');
        cargando.value = false;
      },
    );
    _subOrdenes = _orderRepo.watchActivas().listen((orders) {
      final mapa = <int, List<OrderModel>>{};
      for (final o in orders) {
        if (o.mesa != null) {
          mapa.putIfAbsent(o.mesa!, () => []).add(o);
        }
      }
      ordenesPorMesa.value = mapa;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    _subOrdenes?.cancel();
    super.onClose();
  }

  double totalActivoMesa(int numeroMesa) {
    final orders = ordenesPorMesa[numeroMesa] ?? [];
    return orders.fold(0.0, (sum, o) => sum + o.total);
  }

  String resumenItemsMesa(int numeroMesa) {
    final orders = ordenesPorMesa[numeroMesa] ?? [];
    if (orders.isEmpty) return '';
    final conteo = <String, int>{};
    for (final o in orders) {
      for (final item in o.items) {
        conteo[item.nombre] = (conteo[item.nombre] ?? 0) + item.cantidad;
      }
    }
    if (conteo.isEmpty) return '';
    final entries = conteo.entries.toList();
    final partes = entries.take(2).map((e) => '${e.value}× ${e.key}').toList();
    if (entries.length > 2) partes.add('+${entries.length - 2}');
    return partes.join(' · ');
  }

  Color colorEstado(EstadoMesa estado) => switch (estado) {
        EstadoMesa.libre => AppColors.mesaLibre,
        EstadoMesa.ocupada => AppColors.mesaOcupada,
        EstadoMesa.pendienteCobro => AppColors.mesaPendiente,
        EstadoMesa.pagada => AppColors.mesaPagada,
      };

  void abrirDetalle(BuildContext context, TableModel mesa) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MesaDetalleSheet(mesa: mesa, ctrl: this),
    );
  }

  Future<void> marcarPendienteCobro(int numeroMesa) async {
    try {
      await _tableRepo.marcarPendienteCobro(numeroMesa);
      HapticFeedback.mediumImpact();
      Get.back();
      Get.snackbar(
        'Mesa $numeroMesa — Cobra después',
        'El cliente regresará a pagar',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudo actualizar el estado',
          snackPosition: SnackPosition.TOP);
    }
  }

  Future<void> cobrar(int numeroMesa, MetodoPago metodo) async {
    if (procesando.contains(numeroMesa)) return;
    procesando.add(numeroMesa);
    try {
      final mesa = mesas.firstWhereOrNull((m) => m.numero == numeroMesa);
      if (mesa == null) return;

      await Future.wait([
        ...mesa.ordenesActivas.map((id) => _orderRepo.marcarPagado(id, metodo)),
        _tableRepo.cerrar(numeroMesa),
      ]);

      final tipo = metodo == MetodoPago.efectivo
          ? TipoMovimiento.ingresoCaja
          : TipoMovimiento.consignacionBancolombia;
      final concepto = mesa.nombreCliente.isNotEmpty
          ? 'Mesa $numeroMesa · ${mesa.nombreCliente}'
          : 'Mesa $numeroMesa';
      final montoReal = totalActivoMesa(numeroMesa);
      await Get.find<TesoreriaRepository>().registrarMovimiento(MovimientoTes(
        id: '',
        tipo: tipo,
        concepto: concepto,
        monto: montoReal,
        hora: DateTime.now(),
      ));

      HapticFeedback.mediumImpact();

      Get.back();
      Get.snackbar(
        'Mesa $numeroMesa cobrada',
        '${metodo.etiqueta} · ${CurrencyFormatter.format(montoReal)}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      debugPrint('❌ cobrar() error: $e');
      Get.snackbar(
        'Error',
        'No se pudo procesar el pago',
        snackPosition: SnackPosition.TOP,
      );
    } finally {
      procesando.remove(numeroMesa);
    }
  }
}

// ── Bottom sheet de detalle ───────────────────────────────────────────────

class _MesaDetalleSheet extends StatefulWidget {
  final TableModel mesa;
  final TablesController ctrl;

  const _MesaDetalleSheet({required this.mesa, required this.ctrl});

  @override
  State<_MesaDetalleSheet> createState() => _MesaDetalleSheetState();
}

class _MesaDetalleSheetState extends State<_MesaDetalleSheet> {
  bool _modoEfectivo = false;
  double _recibido = 0;
  final _inputCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  double get _totalActivo => widget.ctrl.totalActivoMesa(widget.mesa.numero);
  double get _vuelto => _recibido - _totalActivo;
  bool get _suficiente => _recibido >= _totalActivo;

  List<double> _sugeridos() {
    final total = _totalActivo;
    final result = <double>{total};
    final next5k = ((total / 5000).ceil() * 5000).toDouble();
    if (next5k > total) result.add(next5k);
    for (final bill in [20000.0, 50000.0, 100000.0, 200000.0]) {
      if (bill >= total) result.add(bill);
    }
    return (result.toList()..sort()).take(5).toList();
  }

  void _seleccionar(double v) {
    HapticFeedback.selectionClick();
    setState(() {
      _recibido = v;
      _inputCtrl.text = ThousandsFormatter.format(v);
    });
    _focusNode.unfocus();
  }

  void _onTextoChanged(String text) {
    setState(() => _recibido = ThousandsFormatter.parse(text) ?? 0);
  }

  void _mostrarDetallePedido(BuildContext context) {
    final orders =
        widget.ctrl.ordenesPorMesa[widget.mesa.numero] ?? [];
    if (orders.isEmpty) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DetallesPedidoSheet(
        mesa: widget.mesa,
        orders: orders,
        totalActivo: _totalActivo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.ctrl.colorEstado(widget.mesa.estado);
    final esPagable = widget.mesa.estado == EstadoMesa.ocupada ||
        widget.mesa.estado == EstadoMesa.pendienteCobro;
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.mesa.numero}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mesa ${widget.mesa.numero}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cafeOscuro,
                      ),
                    ),
                    if (widget.mesa.nombreCliente.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.person_outline_rounded,
                              size: 13, color: AppColors.cafeMedio),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.mesa.nombreCliente,
                              style: GoogleFonts.nunito(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.cafeMedio,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    _EstadoBadge(estado: widget.mesa.estado, color: color),
                  ],
                ),
              ),
            ],
          ),

          Obx(() {
            final total = _totalActivo;
            if (total <= 0) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.verdeClaro,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total pendiente',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.cafeMedio),
                      ),
                      Text(
                        CurrencyFormatter.format(total),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }),

          // Botón "Ver pedido completo"
          Obx(() {
            final orders =
                widget.ctrl.ordenesPorMesa[widget.mesa.numero] ?? [];
            if (orders.isEmpty) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _mostrarDetallePedido(context),
                  icon: const Icon(Icons.receipt_long_outlined, size: 16),
                  label: const Text('Ver pedido completo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cafeMedio,
                    side:
                        const BorderSide(color: AppColors.cremaOscura, width: 1),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    textStyle: GoogleFonts.nunito(
                        fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            );
          }),

          if (esPagable) ...[
            const SizedBox(height: 20),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position:
                      Tween(begin: const Offset(0, 0.08), end: Offset.zero)
                          .animate(anim),
                  child: child,
                ),
              ),
              child: _modoEfectivo
                  ? _PanelEfectivo(
                      key: const ValueKey('efectivo'),
                      total: _totalActivo,
                      recibido: _recibido,
                      vuelto: _vuelto,
                      suficiente: _suficiente,
                      sugeridos: _sugeridos(),
                      inputCtrl: _inputCtrl,
                      focusNode: _focusNode,
                      onSugerido: _seleccionar,
                      onTexto: _onTextoChanged,
                      onCancelar: () => setState(() {
                        _modoEfectivo = false;
                        _recibido = 0;
                        _inputCtrl.clear();
                      }),
                      onCobrar: () => widget.ctrl
                          .cobrar(widget.mesa.numero, MetodoPago.efectivo),
                      procesando: widget.ctrl.procesando
                          .contains(widget.mesa.numero),
                    )
                  : _SelectorMetodo(
                      key: const ValueKey('selector'),
                      procesando:
                          widget.ctrl.procesando.contains(widget.mesa.numero),
                      onEfectivo: () =>
                          setState(() => _modoEfectivo = true),
                      onBancolombia: () => widget.ctrl
                          .cobrar(widget.mesa.numero, MetodoPago.bancolombia),
                    ),
            ),
          ],

          // Botón "Cobrar después" — solo cuando está ocupada
          if (widget.mesa.estado == EstadoMesa.ocupada) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () =>
                    widget.ctrl.marcarPendienteCobro(widget.mesa.numero),
                icon: const Icon(Icons.schedule_rounded, size: 18),
                label: const Text('El cliente paga después'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.cafeMedio,
                  side: const BorderSide(color: AppColors.cafeMedio, width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.nunito(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          if (widget.mesa.estado == EstadoMesa.libre) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: AppColors.cafeMedio, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Mesa disponible',
                  style: TextStyle(
                      fontSize: 15, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Selector de método de pago ────────────────────────────────────────────

class _SelectorMetodo extends StatelessWidget {
  final bool procesando;
  final VoidCallback onEfectivo;
  final VoidCallback onBancolombia;

  const _SelectorMetodo({
    super.key,
    required this.procesando,
    required this.onEfectivo,
    required this.onBancolombia,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'MÉTODO DE PAGO',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.cafeMedio,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BotonPago(
                label: 'Efectivo',
                icon: Icons.payments_outlined,
                color: AppColors.verdeProfundo,
                cargando: procesando,
                onTap: onEfectivo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BotonPago(
                label: 'Bancolombia',
                icon: Icons.phone_android_outlined,
                color: AppColors.bancolombia,
                cargando: procesando,
                onTap: onBancolombia,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Panel calculadora de vuelto ───────────────────────────────────────────

class _PanelEfectivo extends StatelessWidget {
  final double total;
  final double recibido;
  final double vuelto;
  final bool suficiente;
  final List<double> sugeridos;
  final TextEditingController inputCtrl;
  final FocusNode focusNode;
  final void Function(double) onSugerido;
  final void Function(String) onTexto;
  final VoidCallback onCancelar;
  final VoidCallback onCobrar;
  final bool procesando;

  const _PanelEfectivo({
    super.key,
    required this.total,
    required this.recibido,
    required this.vuelto,
    required this.suficiente,
    required this.sugeridos,
    required this.inputCtrl,
    required this.focusNode,
    required this.onSugerido,
    required this.onTexto,
    required this.onCancelar,
    required this.onCobrar,
    required this.procesando,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header con back
        Row(
          children: [
            GestureDetector(
              onTap: onCancelar,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.verdeClaro,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: AppColors.verdeProfundo),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Pago en efectivo',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.cafeOscuro,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Chips de montos rápidos
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: sugeridos.map((v) {
              final esExacto = v == total;
              final seleccionado = recibido == v;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => onSugerido(v),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: seleccionado
                          ? AppColors.verdeProfundo
                          : AppColors.superficie,
                      borderRadius: BorderRadius.circular(20),
                      border: seleccionado
                          ? null
                          : Border.all(
                              color: AppColors.cafeMedio, width: 1),
                    ),
                    child: Text(
                      esExacto
                          ? '${CurrencyFormatter.format(v)} ✓'
                          : CurrencyFormatter.format(v),
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: seleccionado
                            ? Colors.white
                            : AppColors.cafeOscuro,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // Campo de monto recibido
        TextField(
          controller: inputCtrl,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsFormatter()],
          onChanged: onTexto,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.cafeOscuro,
          ),
          decoration: InputDecoration(
            prefixText: r'$ ',
            prefixStyle: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.cafeMedio,
            ),
            hintText: 'Monto recibido...',
            hintStyle: GoogleFonts.nunito(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.cafeMedio,
            ),
            filled: true,
            fillColor: AppColors.superficie,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: AppColors.verdeProfundo, width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Vuelto display
        _VueltoDisplay(
          recibido: recibido,
          vuelto: vuelto,
          suficiente: suficiente,
          total: total,
        ),
        const SizedBox(height: 18),

        // Botón cobrar
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton.icon(
            onPressed: (!suficiente || procesando) ? null : onCobrar,
            icon: procesando
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.check_rounded),
            label: Text(
              procesando
                  ? 'Procesando...'
                  : suficiente
                      ? 'Confirmar cobro · ${CurrencyFormatter.format(total)}'
                      : 'Monto insuficiente',
              style: GoogleFonts.nunito(
                  fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: suficiente
                  ? AppColors.verdeProfundo
                  : Colors.grey.shade300,
              foregroundColor:
                  suficiente ? Colors.white : Colors.grey.shade500,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              elevation: suficiente ? 2 : 0,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Display animado del vuelto ────────────────────────────────────────────

class _VueltoDisplay extends StatelessWidget {
  final double recibido;
  final double vuelto;
  final bool suficiente;
  final double total;

  const _VueltoDisplay({
    required this.recibido,
    required this.vuelto,
    required this.suficiente,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final esExacto = recibido == total && recibido > 0;
    final sinIngresar = recibido == 0;
    final insuficiente = recibido > 0 && !suficiente;

    Color bgColor;
    Color textColor;
    String label;
    String valor;
    IconData icono;

    if (sinIngresar) {
      bgColor = AppColors.verdeClaro;
      textColor = AppColors.cafeMedio;
      label = 'Vuelto';
      valor = '—';
      icono = Icons.swap_horiz_rounded;
    } else if (insuficiente) {
      bgColor = AppColors.tiempoCritico.withAlpha(18);
      textColor = AppColors.tiempoCritico;
      label = 'Falta';
      valor = CurrencyFormatter.format((-vuelto));
      icono = Icons.arrow_downward_rounded;
    } else if (esExacto) {
      bgColor = AppColors.tiempoOk.withAlpha(20);
      textColor = AppColors.tiempoOk;
      label = 'Pago exacto';
      valor = '¡Exacto!';
      icono = Icons.check_circle_outline_rounded;
    } else {
      bgColor = AppColors.tiempoOk.withAlpha(20);
      textColor = AppColors.tiempoOk;
      label = 'Vuelto';
      valor = CurrencyFormatter.format(vuelto);
      icono = Icons.arrow_upward_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icono, color: textColor, size: 22),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const Spacer(),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              valor,
              key: ValueKey(valor),
              style: GoogleFonts.nunito(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  final EstadoMesa estado;
  final Color color;

  const _EstadoBadge({required this.estado, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(
        estado.etiqueta,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BotonPago extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool cargando;
  final VoidCallback onTap;

  const _BotonPago({
    required this.label,
    required this.icon,
    required this.color,
    required this.cargando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: cargando ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          color: cargando ? color.withAlpha(120) : color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: cargando
            ? const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── Sheet de detalles del pedido ──────────────────────────────────────────

class _DetallesPedidoSheet extends StatelessWidget {
  final TableModel mesa;
  final List<OrderModel> orders;
  final double totalActivo;

  const _DetallesPedidoSheet({
    required this.mesa,
    required this.orders,
    required this.totalActivo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.verdeClaro,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long_rounded,
                      color: AppColors.verdeProfundo, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pedido · Mesa ${mesa.numero}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                      if (mesa.nombreCliente.isNotEmpty)
                        Text(
                          mesa.nombreCliente,
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.cafeMedio),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Lista de ítems (scrollable)
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (orders.length == 1)
                    _OrdenItems(order: orders.first)
                  else
                    ...orders.asMap().entries.map((e) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (e.key > 0) const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.cremaOscura,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Orden #${e.value.numeroOrden}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.cafeOscuro,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            _OrdenItems(order: e.value),
                          ],
                        )),
                  const SizedBox(height: 8),
                  const Divider(color: AppColors.cremaOscura),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total pendiente',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                      Text(
                        CurrencyFormatter.format(totalActivo),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrdenItems extends StatelessWidget {
  final OrderModel order;
  const _OrdenItems({required this.order});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: order.items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: AppColors.cremaOscura,
                      borderRadius: BorderRadius.circular(7),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${item.cantidad}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cafeOscuro,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.nombre,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.cafeOscuro),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.format(item.subtotal),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.cafeMedio,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}
