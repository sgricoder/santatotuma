import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/order_repository.dart';

class KitchenController extends GetxController {
  OrderRepository get _repo => Get.find<OrderRepository>();

  final pedidos = <OrderModel>[].obs;
  final cargando = true.obs;
  final errorMsg = ''.obs;
  final despachando = RxSet<String>({});
  // increments every minute so Obx widgets re-read elapsed time
  final ticker = 0.obs;

  StreamSubscription? _sub;
  Timer? _colorTimer;

  @override
  void onInit() {
    super.onInit();
    _suscribir();
    _colorTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      ticker.value++;
    });
  }

  @override
  void onClose() {
    _sub?.cancel();
    _colorTimer?.cancel();
    super.onClose();
  }

  void _suscribir() {
    _sub?.cancel();
    cargando.value = true;
    errorMsg.value = '';
    _sub = _repo.watchCocina().listen(
      (lista) {
        pedidos.value = lista;
        cargando.value = false;
      },
      onError: (e, st) {
        debugPrint('❌ KitchenController error: $e\n$st');
        errorMsg.value = 'No se pudieron cargar los pedidos';
        cargando.value = false;
      },
    );
  }

  void recargar() => _suscribir();

  int minutosEspera(DateTime fecha) =>
      DateTime.now().difference(fecha).inMinutes;

  Color colorTiempo(DateTime fecha) {
    final mins = minutosEspera(fecha);
    if (mins < 5) return AppColors.tiempoOk;
    if (mins < 10) return AppColors.tiempoAlerta;
    return AppColors.tiempoCritico;
  }

  String etiquetaTiempo(DateTime fecha) {
    final mins = minutosEspera(fecha);
    return mins < 1 ? 'Ahora' : '$mins min';
  }

  Future<void> marcarDespachado(String id) async {
    if (despachando.contains(id)) return;
    despachando.add(id);
    try {
      await _repo.marcarDespachado(id);
      HapticFeedback.heavyImpact();
    } catch (_) {
      Get.snackbar(
        'Error',
        'No se pudo actualizar el pedido',
        snackPosition: SnackPosition.BOTTOM,
      );
      despachando.remove(id);
    }
  }

  void mostrarCobroSinMesa(BuildContext context, OrderModel pedido) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CobroSinMesaSheet(pedido: pedido, ctrl: this),
    );
  }

  Future<void> cobrarSinMesa(String id, MetodoPago metodo) async {
    if (despachando.contains(id)) return;
    despachando.add(id);
    try {
      await _repo.marcarPagado(id, metodo);
      HapticFeedback.heavyImpact();
      Get.back(); // cierra el sheet
    } catch (_) {
      Get.snackbar(
        'Error',
        'No se pudo registrar el cobro',
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      despachando.remove(id);
    }
  }
}

// ── Sheet de cobro para pedidos sin mesa ─────────────────────────────────────

class _CobroSinMesaSheet extends StatefulWidget {
  final OrderModel pedido;
  final KitchenController ctrl;

  const _CobroSinMesaSheet({required this.pedido, required this.ctrl});

  @override
  State<_CobroSinMesaSheet> createState() => _CobroSinMesaSheetState();
}

class _CobroSinMesaSheetState extends State<_CobroSinMesaSheet> {
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

  double get _total => widget.pedido.total;
  double get _vuelto => _recibido - _total;
  bool get _suficiente => _recibido >= _total;

  List<double> _sugeridos() {
    final result = <double>{_total};
    final next5k = ((_total / 5000).ceil() * 5000).toDouble();
    if (next5k > _total) result.add(next5k);
    for (final bill in [20000.0, 50000.0, 100000.0, 200000.0]) {
      if (bill >= _total) result.add(bill);
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
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(24, 16, 24, bottom + 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              const Icon(Icons.receipt_outlined,
                  color: AppColors.dorado, size: 22),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cobrar pedido',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cafeOscuro,
                    ),
                  ),
                  Text(
                    'Orden #${widget.pedido.numeroOrden.toString().padLeft(3, '0')}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.cafeMedio),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Total
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFF9EBC7),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: GoogleFonts.nunito(
                      fontSize: 15, color: AppColors.cafeMedio),
                ),
                Text(
                  CurrencyFormatter.format(_total),
                  style: GoogleFonts.nunito(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF783D19),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Selector ↔ Panel efectivo
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
                ? _KPanelEfectivo(
                    key: const ValueKey('efectivo'),
                    total: _total,
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
                    onCobrar: () =>
                        widget.ctrl.cobrarSinMesa(widget.pedido.id, MetodoPago.efectivo),
                    procesando:
                        widget.ctrl.despachando.contains(widget.pedido.id),
                  )
                : _KSelectorMetodo(
                    key: const ValueKey('selector'),
                    procesando:
                        widget.ctrl.despachando.contains(widget.pedido.id),
                    onEfectivo: () => setState(() => _modoEfectivo = true),
                    onBancolombia: () => widget.ctrl
                        .cobrarSinMesa(widget.pedido.id, MetodoPago.bancolombia),
                  ),
          ),
        ],
      ),
    );
  }
}

// ── Selector de método ────────────────────────────────────────────────────

class _KSelectorMetodo extends StatelessWidget {
  final bool procesando;
  final VoidCallback onEfectivo;
  final VoidCallback onBancolombia;

  const _KSelectorMetodo({
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
        Text(
          'Método de pago',
          style: GoogleFonts.nunito(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.cafeMedio,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _BotonMetodo(
                label: 'Efectivo',
                icon: Icons.payments_outlined,
                color: AppColors.verdeOlivo,
                procesando: procesando,
                onTap: onEfectivo,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BotonMetodo(
                label: 'Bancolombia',
                icon: Icons.phone_android_outlined,
                color: const Color(0xFFB8860B),
                procesando: procesando,
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

class _KPanelEfectivo extends StatelessWidget {
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

  const _KPanelEfectivo({
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
        // Back button
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

        // Input monto recibido
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
              borderSide:
                  const BorderSide(color: Color(0xFFA9B388), width: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 14),

        _KVueltoDisplay(
          recibido: recibido,
          vuelto: vuelto,
          suficiente: suficiente,
          total: total,
        ),
        const SizedBox(height: 18),

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
              style:
                  GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  suficiente ? const Color(0xFFC4661F) : Colors.grey.shade300,
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

class _KVueltoDisplay extends StatelessWidget {
  final double recibido;
  final double vuelto;
  final bool suficiente;
  final double total;

  const _KVueltoDisplay({
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
      valor = CurrencyFormatter.format(-vuelto);
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
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botón de método de pago ───────────────────────────────────────────────

class _BotonMetodo extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool procesando;
  final VoidCallback onTap;

  const _BotonMetodo({
    required this.label,
    required this.icon,
    required this.color,
    required this.procesando,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: procesando ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 58,
        decoration: BoxDecoration(
          color: procesando ? color.withAlpha(120) : color,
          borderRadius: BorderRadius.circular(14),
        ),
        child: procesando
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
