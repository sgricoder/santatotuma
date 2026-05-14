import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../../data/models/tesoreria_model.dart';
import '../../data/repositories/cash_register_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/tesoreria_repository.dart';

class TesoreriaController extends GetxController {
  TesoreriaRepository get _repo => Get.find<TesoreriaRepository>();
  CashRegisterRepository get _cajaRepo => Get.find<CashRegisterRepository>();
  OrderRepository get _orderRepo => Get.find<OrderRepository>();

  final tesoreria = Rx<TesoreriaModel?>(null);
  final movimientos = <MovimientoTes>[].obs;
  final procesando = false.obs;

  StreamSubscription? _subEstado;
  StreamSubscription? _subMovs;

  double get totalIngresos => movimientos
      .where((m) => m.tipo != TipoMovimiento.gasto)
      .fold(0.0, (s, m) => s + m.monto);

  double get totalGastos => movimientos
      .where((m) => m.tipo == TipoMovimiento.gasto)
      .fold(0.0, (s, m) => s + m.monto);

  @override
  void onInit() {
    super.onInit();
    _subEstado = _repo.watchTesoreria().listen(
      (t) => tesoreria.value = t,
      onError: (e, st) => debugPrint('❌ TesoreriaController estado: $e\n$st'),
    );
    _subMovs = _repo.watchMovimientos().listen(
      (list) => movimientos.value = list,
      onError: (e, st) => debugPrint('❌ TesoreriaController movs: $e\n$st'),
    );
  }

  @override
  void onClose() {
    _subEstado?.cancel();
    _subMovs?.cancel();
    super.onClose();
  }

  void abrirDialogoInicio(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _InicioSheet(ctrl: this),
    );
  }

  void abrirDialogoTransferencia(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _TransferenciaSheet(ctrl: this),
    );
  }

  void abrirDialogoGasto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GastoTesSheet(ctrl: this),
    );
  }

  Future<void> inicializar(double saldoInicial) async {
    procesando.value = true;
    try {
      await _repo.inicializar(saldoInicial);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo configurar la tesorería',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      procesando.value = false;
    }
  }

  Future<void> transferirDeCaja(double monto) async {
    procesando.value = true;
    try {
      final hoy = DateTime.now();
      final fecha = DateFormat('yyyy-MM-dd').format(hoy);
      final mov = MovimientoTes(
        id: '',
        tipo: TipoMovimiento.ingresoCaja,
        concepto: 'Transferencia caja $fecha',
        monto: monto,
        hora: DateTime.now(),
      );
      await _repo.registrarMovimiento(mov);
      Get.snackbar(
        'Transferencia registrada',
        '${CurrencyFormatter.format(monto)} ingresados a tesorería',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudo registrar la transferencia',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      procesando.value = false;
    }
  }

  Future<void> registrarGasto({
    required String concepto,
    required double monto,
    required CategoriaGastoTes categoria,
  }) async {
    procesando.value = true;
    try {
      final mov = MovimientoTes(
        id: '',
        tipo: TipoMovimiento.gasto,
        concepto: concepto,
        monto: monto,
        hora: DateTime.now(),
        categoria: categoria,
      );
      await _repo.registrarMovimiento(mov);
    } catch (e) {
      Get.snackbar('Error', 'No se pudo registrar el gasto',
          snackPosition: SnackPosition.BOTTOM);
    } finally {
      procesando.value = false;
    }
  }

  // Returns the full expected cash balance (opening + cash sales - expenses).
  // Returns null if there is no open register today.
  Future<double?> getSaldoCajaHoy() async {
    try {
      final caja = await _cajaRepo.getCajaFecha(DateTime.now());
      if (caja == null) return null;
      final hoy = DateTime.now();
      final pedidos = await _orderRepo.getPorFecha(
        DateTime(hoy.year, hoy.month, hoy.day),
        DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59),
      );
      final ventasEfectivo = pedidos
          .where((p) => p.metodoPago == MetodoPago.efectivo)
          .fold(0.0, (s, p) => s + p.total);
      return caja.aperturaMonto + ventasEfectivo - caja.totalSalidas;
    } catch (_) {
      return null;
    }
  }
}

// ── Sheet: configurar tesorería por primera vez ───────────────────────────

class _InicioSheet extends StatefulWidget {
  final TesoreriaController ctrl;
  const _InicioSheet({required this.ctrl});

  @override
  State<_InicioSheet> createState() => _InicioSheetState();
}

class _InicioSheetState extends State<_InicioSheet> {
  final _monto = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final val = double.tryParse(_monto.text.replaceAll(',', '.'));
    if (val == null || val < 0) {
      setState(() => _error = 'Ingresa un monto válido');
      return;
    }
    Get.back();
    await widget.ctrl.inicializar(val);
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      titulo: 'Configurar tesorería',
      subtitulo: 'Ingresa el capital actual del negocio',
      icono: Icons.account_balance_outlined,
      colorIcono: AppColors.dorado,
      children: [
        TextField(
          controller: _monto,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'Saldo inicial',
            prefixText: r'$ ',
            errorText: _error,
            prefixIcon: const Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 24),
        _BotonConfirmar(
          label: 'Guardar',
          color: AppColors.dorado,
          onTap: _confirmar,
        ),
      ],
    );
  }
}

// ── Sheet: transferencia desde caja ──────────────────────────────────────

class _TransferenciaSheet extends StatefulWidget {
  final TesoreriaController ctrl;
  const _TransferenciaSheet({required this.ctrl});

  @override
  State<_TransferenciaSheet> createState() => _TransferenciaSheetState();
}

class _TransferenciaSheetState extends State<_TransferenciaSheet> {
  final _monto = TextEditingController();
  String? _error;
  double? _saldoCaja;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarSaldo();
  }

  Future<void> _cargarSaldo() async {
    final saldo = await widget.ctrl.getSaldoCajaHoy();
    if (mounted) setState(() { _saldoCaja = saldo; _cargando = false; });
  }

  @override
  void dispose() {
    _monto.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final val = double.tryParse(_monto.text.replaceAll(',', '.'));
    if (val == null || val <= 0) {
      setState(() => _error = 'Ingresa un monto válido');
      return;
    }
    if (_saldoCaja != null && val > _saldoCaja!) {
      setState(() => _error =
          'Máximo disponible: ${CurrencyFormatter.format(_saldoCaja!)}');
      return;
    }
    Get.back();
    await widget.ctrl.transferirDeCaja(val);
  }

  @override
  Widget build(BuildContext context) {
    return _BaseSheet(
      titulo: 'Transferir a tesorería',
      subtitulo: 'Mueve efectivo de caja al capital del negocio',
      icono: Icons.swap_horiz_rounded,
      colorIcono: AppColors.verdeOlivo,
      children: [
        if (_cargando)
          const Center(child: CircularProgressIndicator())
        else if (_saldoCaja != null) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cremaOscura,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Disponible en caja',
                  style: TextStyle(fontSize: 13, color: AppColors.cafeMedio),
                ),
                Text(
                  CurrencyFormatter.format(_saldoCaja!),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.cafeOscuro,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.tiempoCritico.withAlpha(15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.tiempoCritico.withAlpha(60)),
            ),
            child: const Text(
              'No hay caja abierta hoy. Abre la caja primero.',
              style: TextStyle(fontSize: 13, color: AppColors.tiempoCritico),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (!_cargando && _saldoCaja != null) ...[
          TextField(
            controller: _monto,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '¿Cuánto transferir?',
              prefixText: r'$ ',
              errorText: _error,
              prefixIcon: const Icon(Icons.move_up_rounded),
            ),
          ),
          const SizedBox(height: 24),
          _BotonConfirmar(
            label: 'Transferir',
            color: AppColors.verdeOlivo,
            onTap: _confirmar,
          ),
        ],
      ],
    );
  }
}

// ── Sheet: registrar gasto ────────────────────────────────────────────────

class _GastoTesSheet extends StatefulWidget {
  final TesoreriaController ctrl;
  const _GastoTesSheet({required this.ctrl});

  @override
  State<_GastoTesSheet> createState() => _GastoTesSheetState();
}

class _GastoTesSheetState extends State<_GastoTesSheet> {
  final _concepto = TextEditingController();
  final _monto = TextEditingController();
  CategoriaGastoTes _categoria = CategoriaGastoTes.otro;
  String? _errorConcepto;
  String? _errorMonto;

  @override
  void dispose() {
    _concepto.dispose();
    _monto.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final montoVal = double.tryParse(_monto.text.replaceAll(',', '.'));
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
      subtitulo: 'Egreso del capital del negocio',
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
          decoration: InputDecoration(
            labelText: 'Monto',
            prefixText: r'$ ',
            errorText: _errorMonto,
            prefixIcon: const Icon(Icons.attach_money),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: CategoriaGastoTes.values.map((cat) {
            final sel = _categoria == cat;
            return GestureDetector(
              onTap: () => setState(() => _categoria = cat),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color:
                      sel ? AppColors.cafeOscuro : AppColors.cremaOscura,
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
