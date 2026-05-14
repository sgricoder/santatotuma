import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../data/models/table_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/table_repository.dart';

class TablesController extends GetxController {
  TableRepository get _tableRepo => Get.find<TableRepository>();
  OrderRepository get _orderRepo => Get.find<OrderRepository>();

  final mesas = <TableModel>[].obs;
  final cargando = true.obs;
  final procesando = RxSet<int>({});

  StreamSubscription? _sub;

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
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
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
      HapticFeedback.mediumImpact();

      Get.back();
      Get.snackbar(
        'Mesa $numeroMesa cobrada',
        '${metodo.etiqueta} · ${CurrencyFormatter.format(mesa.totalAcumulado)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      debugPrint('❌ cobrar() error: $e');
      Get.snackbar(
        'Error',
        'No se pudo procesar el pago',
        snackPosition: SnackPosition.BOTTOM,
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

  double get _vuelto => _recibido - widget.mesa.totalAcumulado;
  bool get _suficiente => _recibido >= widget.mesa.totalAcumulado;

  List<double> _sugeridos() {
    final total = widget.mesa.totalAcumulado;
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
      _inputCtrl.text = v.toInt().toString();
    });
    _focusNode.unfocus();
  }

  void _onTextoChanged(String text) {
    setState(() => _recibido = double.tryParse(text) ?? 0);
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mesa ${widget.mesa.numero}',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF783D19),
                    ),
                  ),
                  const SizedBox(height: 4),
                  _EstadoBadge(estado: widget.mesa.estado, color: color),
                ],
              ),
            ],
          ),

          if (widget.mesa.totalAcumulado > 0) ...[
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFF9EBC7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total acumulado',
                    style: TextStyle(fontSize: 15, color: Color(0xFFB99470)),
                  ),
                  Text(
                    CurrencyFormatter.format(widget.mesa.totalAcumulado),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF783D19),
                    ),
                  ),
                ],
              ),
            ),
          ],

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
                      total: widget.mesa.totalAcumulado,
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

          if (widget.mesa.estado == EstadoMesa.libre) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                const Icon(Icons.check_circle_outline,
                    color: Color(0xFF9E9E9E), size: 20),
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
            color: Color(0xFFB99470),
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
                color: const Color(0xFFC4661F),
                cargando: procesando,
                onTap: onEfectivo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BotonPago(
                label: 'Bancolombia',
                icon: Icons.phone_android_outlined,
                color: const Color(0xFFFFCC00),
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
                  color: const Color(0xFFF9EBC7),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.arrow_back_ios_new_rounded,
                    size: 16, color: Color(0xFFB99470)),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Pago en efectivo',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF783D19),
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
                          ? const Color(0xFFC4661F)
                          : const Color(0xFFF9EBC7),
                      borderRadius: BorderRadius.circular(20),
                      border: seleccionado
                          ? null
                          : Border.all(
                              color: const Color(0xFFD9C8A0), width: 1),
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
                            : const Color(0xFF783D19),
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
          onChanged: onTexto,
          style: GoogleFonts.nunito(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF783D19),
          ),
          decoration: InputDecoration(
            prefixText: r'$ ',
            prefixStyle: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFB99470),
            ),
            hintText: '0',
            hintStyle: GoogleFonts.nunito(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFB99470),
            ),
            filled: true,
            fillColor: const Color(0xFFF9EBC7),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                  color: Color(0xFFA9B388), width: 1.5),
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
                  ? const Color(0xFFC4661F)
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
      bgColor = const Color(0xFFF9EBC7);
      textColor = const Color(0xFFB99470);
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
