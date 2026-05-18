import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/thousands_formatter.dart';
import '../../data/models/inventory_model.dart';
import '../../data/repositories/inventory_repository.dart';

class InventoryController extends GetxController {
  InventoryRepository get _repo => Get.find<InventoryRepository>();

  final _todos = <InventoryItemModel>[].obs;
  final cargando = true.obs;
  final errorMsg = ''.obs;
  final categoriaActiva = Rx<CategoriaInsumo?>(null);
  final busqueda = ''.obs;

  StreamSubscription? _sub;

  List<InventoryItemModel> get filtrados {
    var lista = _todos.toList();
    if (categoriaActiva.value != null) {
      lista = lista.where((i) => i.categoria == categoriaActiva.value).toList();
    }
    final q = busqueda.value.trim().toLowerCase();
    if (q.isNotEmpty) {
      lista = lista.where((i) => i.nombre.toLowerCase().contains(q)).toList();
    }
    return lista;
  }

  int get totalBajoStock => _todos.where((i) => i.esBajoStock).length;
  List<InventoryItemModel> get itemsBajoStock =>
      _todos.where((i) => i.esBajoStock).toList();

  @override
  void onInit() {
    super.onInit();
    _suscribir();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _suscribir() {
    _sub?.cancel();
    cargando.value = true;
    errorMsg.value = '';
    _sub = _repo.watchInsumos().listen(
      (lista) {
        _todos.value = lista;
        cargando.value = false;
      },
      onError: (e, st) {
        debugPrint('❌ InventoryController: $e\n$st');
        errorMsg.value = 'No se pudo cargar el inventario';
        cargando.value = false;
      },
    );
  }

  void recargar() => _suscribir();

  void seleccionarCategoria(CategoriaInsumo? cat) =>
      categoriaActiva.value = cat;

  void buscar(String query) => busqueda.value = query;

  void mostrarBajoStock(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BajoStockSheet(items: itemsBajoStock, ctrl: this),
    );
  }

  void abrirMovimiento(BuildContext context, InventoryItemModel insumo) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MovimientoSheet(insumo: insumo, ctrl: this),
    );
  }

  Future<void> registrarEntrada({
    required String insumoId,
    required double cantidad,
    required double costoTotal,
    String proveedor = '',
    String notas = '',
  }) =>
      _repo.registrarEntrada(
        insumoId: insumoId,
        cantidad: cantidad,
        costoTotal: costoTotal,
        proveedor: proveedor,
        notas: notas,
      );

  Future<void> registrarSalida({
    required String insumoId,
    required double cantidad,
    String notas = '',
  }) =>
      _repo.registrarSalida(
        insumoId: insumoId,
        cantidad: cantidad,
        notas: notas,
      );
}

// ── Sheet de bajo stock ───────────────────────────────────────────────────

class _BajoStockSheet extends StatelessWidget {
  final List<InventoryItemModel> items;
  final InventoryController ctrl;

  const _BajoStockSheet({required this.items, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: AppColors.naranja, size: 22),
              const SizedBox(width: 10),
              Text(
                '${items.length} insumo${items.length == 1 ? '' : 's'} bajo stock',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cafeNegro,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.5,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final item = items[i];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 4, vertical: 4),
                  title: Text(
                    item.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.cafeNegro,
                    ),
                  ),
                  subtitle: Text(
                    'Stock mín: ${item.stockMinimo} ${item.unidad}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.cafeClaro),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${item.cantidadActual % 1 == 0 ? item.cantidadActual.toInt() : item.cantidadActual} ${item.unidad}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.naranja,
                        ),
                      ),
                      const SizedBox(width: 10),
                      GestureDetector(
                        onTap: () {
                          Get.back();
                          ctrl.abrirMovimiento(context, item);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.verdeProfundo,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'Reponer',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bottom sheet de movimiento ────────────────────────────────────────────

class _MovimientoSheet extends StatefulWidget {
  final InventoryItemModel insumo;
  final InventoryController ctrl;

  const _MovimientoSheet({required this.insumo, required this.ctrl});

  @override
  State<_MovimientoSheet> createState() => _MovimientoSheetState();
}

class _MovimientoSheetState extends State<_MovimientoSheet>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;
  final _cantidad = TextEditingController();
  final _costo = TextEditingController();
  final _proveedor = TextEditingController();
  final _notas = TextEditingController();
  bool _enviando = false;
  String? _errorCantidad;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    _cantidad.dispose();
    _costo.dispose();
    _proveedor.dispose();
    _notas.dispose();
    super.dispose();
  }

  Future<void> _confirmar() async {
    final cantidadVal = double.tryParse(_cantidad.text.replaceAll(',', '.'));
    if (cantidadVal == null || cantidadVal <= 0) {
      setState(() => _errorCantidad = 'Ingresa una cantidad válida');
      return;
    }
    setState(() {
      _enviando = true;
      _errorCantidad = null;
    });
    try {
      if (_tab.index == 0) {
        final costoVal = ThousandsFormatter.parse(_costo.text) ?? 0.0;
        await widget.ctrl.registrarEntrada(
          insumoId: widget.insumo.id,
          cantidad: cantidadVal,
          costoTotal: costoVal,
          proveedor: _proveedor.text.trim(),
          notas: _notas.text.trim(),
        );
      } else {
        await widget.ctrl.registrarSalida(
          insumoId: widget.insumo.id,
          cantidad: cantidadVal,
          notas: _notas.text.trim(),
        );
      }
      if (mounted) Get.back();
      Get.snackbar(
        _tab.index == 0 ? 'Entrada registrada' : 'Salida registrada',
        '${widget.insumo.nombre}: ${_tab.index == 0 ? '+' : '-'}$cantidadVal ${widget.insumo.unidad}',
        snackPosition: SnackPosition.TOP,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      Get.snackbar('Error', 'No se pudo registrar el movimiento',
          snackPosition: SnackPosition.TOP);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insumo = widget.insumo;
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
            const SizedBox(height: 16),

            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        insumo.nombre,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                      Text(
                        'Stock actual: ${insumo.cantidadActual} ${insumo.unidad}',
                        style: TextStyle(
                          fontSize: 13,
                          color: insumo.esBajoStock
                              ? AppColors.naranja
                              : AppColors.cafeMedio,
                          fontWeight: insumo.esBajoStock
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                if (insumo.esBajoStock)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.cremaAlerta,
                      borderRadius: BorderRadius.circular(8),
                      border:
                          Border.all(color: AppColors.naranja, width: 1),
                    ),
                    child: const Text(
                      'Stock bajo',
                      style: TextStyle(
                        color: AppColors.naranja,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Tabs
            Container(
              decoration: BoxDecoration(
                color: AppColors.verdeClaro,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tab,
                indicator: BoxDecoration(
                  color: AppColors.verdeProfundo,
                  borderRadius: BorderRadius.circular(10),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerHeight: 0,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.cafeMedio,
                labelStyle: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 14),
                tabs: const [
                  Tab(text: 'Entrada'),
                  Tab(text: 'Salida'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Campos
            TextField(
              controller: _cantidad,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Cantidad (${insumo.unidad})',
                errorText: _errorCantidad,
                prefixIcon: const Icon(Icons.scale_outlined),
              ),
            ),
            const SizedBox(height: 12),

            StatefulBuilder(
              builder: (_, setTab) {
                _tab.addListener(() => setTab(() {}));
                return _tab.index == 0
                    ? Column(
                        children: [
                          TextField(
                            controller: _costo,
                            keyboardType: TextInputType.number,
                            inputFormatters: [ThousandsFormatter()],
                            decoration: const InputDecoration(
                              labelText: 'Costo total (opcional)',
                              prefixIcon: Icon(Icons.attach_money),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _proveedor,
                            decoration: const InputDecoration(
                              labelText: 'Proveedor (opcional)',
                              prefixIcon: Icon(Icons.storefront_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                      )
                    : const SizedBox.shrink();
              },
            ),

            TextField(
              controller: _notas,
              decoration: const InputDecoration(
                labelText: 'Notas (opcional)',
                prefixIcon: Icon(Icons.notes_outlined),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _enviando ? null : _confirmar,
                icon: _enviando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(_enviando ? 'Guardando...' : 'Confirmar'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
