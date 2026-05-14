import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../data/models/cash_register_model.dart';
import '../../data/models/order_model.dart';
import '../../data/repositories/cash_register_repository.dart';
import '../../data/repositories/order_repository.dart';

class CashController extends GetxController {
  CashRegisterRepository get _cajaRepo => Get.find<CashRegisterRepository>();
  OrderRepository get _orderRepo => Get.find<OrderRepository>();

  final cajaHoy = Rx<CashRegisterModel?>(null);
  final ventasEfectivo = 0.0.obs;
  final ventasBancolombia = 0.0.obs;
  final procesando = false.obs;

  StreamSubscription? _sub;

  double get saldoEsperado =>
      (cajaHoy.value?.aperturaMonto ?? 0) +
      ventasEfectivo.value -
      (cajaHoy.value?.totalSalidas ?? 0);

  @override
  void onInit() {
    super.onInit();
    _sub = _cajaRepo.watchCajaHoy().listen(
      (caja) => cajaHoy.value = caja,
      onError: (e, st) => debugPrint('❌ CashController: $e\n$st'),
    );
    _cargarVentasHoy();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  Future<void> _cargarVentasHoy() async {
    try {
      final hoy = DateTime.now();
      final pedidos = await _orderRepo.getPorFecha(
        DateTime(hoy.year, hoy.month, hoy.day),
        DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59),
      );
      ventasEfectivo.value = pedidos
          .where((p) => p.metodoPago == MetodoPago.efectivo)
          .fold(0.0, (s, p) => s + p.total);
      ventasBancolombia.value = pedidos
          .where((p) => p.metodoPago == MetodoPago.bancolombia)
          .fold(0.0, (s, p) => s + p.total);
    } catch (e) {
      debugPrint('❌ CashController._cargarVentasHoy: $e');
    }
  }

  void abrirDialogoApertura(BuildContext context, {bool esReapertura = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AperturaSheet(ctrl: this, esReapertura: esReapertura),
    );
  }

  void abrirDialogoGasto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GastoSheet(ctrl: this),
    );
  }

  void abrirDialogoCierre(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CierreSheet(ctrl: this),
    );
  }

  Future<void> abrirCaja(double monto) async {
    procesando.value = true;
    try {
      await _cajaRepo.abrirCaja(monto);
      await _cargarVentasHoy();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo abrir la caja',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      procesando.value = false;
    }
  }

  Future<void> registrarGasto({
    required String concepto,
    required double monto,
    required CategoriaGasto categoria,
  }) async {
    procesando.value = true;
    try {
      await _cajaRepo.registrarSalida(CashOutModel(
        concepto: concepto,
        monto: monto,
        categoria: categoria,
        hora: DateTime.now(),
      ));
    } catch (e) {
      Get.snackbar('Error', 'No se pudo registrar el gasto',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      procesando.value = false;
    }
  }

  Future<void> reabrirCaja(double monto) async {
    procesando.value = true;
    try {
      await _cajaRepo.reabrirCaja(monto);
      await _cargarVentasHoy();
    } catch (e) {
      Get.snackbar('Error', 'No se pudo reabrir la caja',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      procesando.value = false;
    }
  }

  Future<void> cerrarCaja(double montoFinal) async {
    procesando.value = true;
    try {
      await _cajaRepo.cerrarCaja(montoFinal);
      final diferencia = montoFinal - saldoEsperado;
      final signo = diferencia >= 0 ? '+' : '';
      Get.snackbar(
        'Caja cerrada',
        'Diferencia: $signo${CurrencyFormatter.format(diferencia)}',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudo cerrar la caja',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      procesando.value = false;
    }
  }
}

// ── Sheet de apertura ─────────────────────────────────────────────────────

class _AperturaSheet extends StatefulWidget {
  final CashController ctrl;
  final bool esReapertura;
  const _AperturaSheet({required this.ctrl, this.esReapertura = false});

  @override
  State<_AperturaSheet> createState() => _AperturaSheetState();
}

class _AperturaSheetState extends State<_AperturaSheet> {
  final _monto = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final val = ThousandsFormatter.parse(_monto.text);
    if (val == null || val < 0) {
      setState(() => _error = 'Ingresa un monto válido');
      return;
    }
    Get.back();
    if (widget.esReapertura) {
      await widget.ctrl.reabrirCaja(val);
    } else {
      await widget.ctrl.abrirCaja(val);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      titulo: widget.esReapertura ? 'Reabrir caja' : 'Abrir caja',
      subtitulo: widget.esReapertura
          ? 'Actualiza el dinero en caja'
          : 'Ingresa el dinero con que empiezas el día',
      icono: Icons.lock_open_outlined,
      colorIcono: AppColors.verdeOlivo,
      children: [
        TextField(
          controller: _monto,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsFormatter()],
          decoration: InputDecoration(
            labelText: 'Monto inicial',
            prefixText: '\$ ',
            errorText: _error,
            prefixIcon: const Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 24),
        _BotonConfirmar(
          label: 'Abrir caja',
          color: AppColors.verdeOlivo,
          onTap: _confirmar,
        ),
      ],
    );
  }
}

// ── Sheet de gasto ────────────────────────────────────────────────────────

class _GastoSheet extends StatefulWidget {
  final CashController ctrl;
  const _GastoSheet({required this.ctrl});

  @override
  State<_GastoSheet> createState() => _GastoSheetState();
}

class _GastoSheetState extends State<_GastoSheet> {
  final _concepto = TextEditingController();
  final _monto = TextEditingController();
  CategoriaGasto _categoria = CategoriaGasto.otro;
  String? _errorConcepto;
  String? _errorMonto;

  @override
  void dispose() {
    _concepto.dispose();
    _monto.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final montoVal = ThousandsFormatter.parse(_monto.text);
    setState(() {
      _errorConcepto =
          _concepto.text.trim().isEmpty ? 'Escribe un concepto' : null;
      _errorMonto = (montoVal == null || montoVal <= 0)
          ? 'Ingresa un monto válido'
          : null;
    });
    if (_errorConcepto != null || _errorMonto != null) return;
    Get.back();
    await widget.ctrl.registrarGasto(
      concepto: _concepto.text.trim(),
      monto: montoVal!,
      categoria: _categoria,
    );
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      titulo: 'Registrar gasto',
      subtitulo: 'Salida de efectivo de caja',
      icono: Icons.remove_circle_outline,
      colorIcono: AppColors.tiempoCritico,
      children: [
        TextField(
          controller: _concepto,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'Concepto',
            errorText: _errorConcepto,
            prefixIcon: const Icon(Icons.edit_outlined),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _monto,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsFormatter()],
          decoration: InputDecoration(
            labelText: 'Monto',
            prefixText: '\$ ',
            errorText: _errorMonto,
            prefixIcon: const Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 16),
        // Selector de categoría
        Wrap(
          spacing: 8,
          children: CategoriaGasto.values.map((cat) {
            final sel = _categoria == cat;
            return GestureDetector(
              onTap: () => setState(() => _categoria = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.cafeOscuro
                      : AppColors.cremaOscura,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  cat.etiqueta,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: sel ? Colors.white : AppColors.cafeMedio,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        _BotonConfirmar(
          label: 'Registrar gasto',
          color: AppColors.tiempoCritico,
          onTap: _confirmar,
        ),
      ],
    );
  }
}

// ── Sheet de cierre ───────────────────────────────────────────────────────

class _CierreSheet extends StatefulWidget {
  final CashController ctrl;
  const _CierreSheet({required this.ctrl});

  @override
  State<_CierreSheet> createState() => _CierreSheetState();
}

class _CierreSheetState extends State<_CierreSheet> {
  final _monto = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final val = ThousandsFormatter.parse(_monto.text);
    if (val == null || val < 0) {
      setState(() => _error = 'Ingresa un monto válido');
      return;
    }
    Get.back();
    await widget.ctrl.cerrarCaja(val);
  }

  @override
  Widget build(BuildContext context) {
    final esperado = widget.ctrl.saldoEsperado;
    return _BaseSheet(
      titulo: 'Cerrar caja',
      subtitulo: 'Cuenta el efectivo y registra el total',
      icono: Icons.lock_outline,
      colorIcono: AppColors.dorado,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.crema,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Saldo esperado',
                style: TextStyle(fontSize: 14, color: AppColors.cafeMedio),
              ),
              Text(
                CurrencyFormatter.format(esperado),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.verdeOlivo,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _monto,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [ThousandsFormatter()],
          decoration: InputDecoration(
            labelText: 'Efectivo contado en caja',
            prefixText: '\$ ',
            errorText: _error,
            prefixIcon: const Icon(Icons.point_of_sale_outlined),
          ),
        ),
        const SizedBox(height: 24),
        _BotonConfirmar(
          label: 'Cerrar caja',
          color: AppColors.dorado,
          onTap: _confirmar,
        ),
      ],
    );
  }
}

// ── Widgets compartidos ───────────────────────────────────────────────────

class _BaseSheet extends StatelessWidget {
  final String titulo;
  final String subtitulo;
  final IconData icono;
  final Color colorIcono;
  final List<Widget> children;

  const _BaseSheet({
    required this.titulo,
    required this.subtitulo,
    required this.icono,
    required this.colorIcono,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Row(
              children: [
                Icon(icono, color: colorIcono, size: 22),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.cafeOscuro,
                      ),
                    ),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.cafeMedio,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _BotonConfirmar extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _BotonConfirmar({
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

