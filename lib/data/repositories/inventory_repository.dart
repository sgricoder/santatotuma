import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/inventory_model.dart';

class InventoryRepository {
  final _items = FirebaseFirestore.instance.collection('inventory');
  final _movs = FirebaseFirestore.instance.collection('inventory_movements');

  bool get _disponible => Firebase.apps.isNotEmpty;

  Stream<List<InventoryItemModel>> watchInsumos() {
    if (!_disponible) return const Stream.empty();
    // Un solo orderBy para evitar índice compuesto; ordenamos por categoría en cliente.
    return _items.orderBy('nombre').snapshots().map((snap) {
      final lista =
          snap.docs.map((d) => InventoryItemModel.fromFirestore(d)).toList();
      lista.sort((a, b) {
        final c = a.categoria.name.compareTo(b.categoria.name);
        return c != 0 ? c : a.nombre.compareTo(b.nombre);
      });
      return lista;
    });
  }

  Stream<List<InventoryItemModel>> watchBajoStock() {
    if (!_disponible) return const Stream.empty();
    // Filtra en cliente (Firestore no soporta comparar dos campos)
    return watchInsumos().map(
      (lista) => lista.where((e) => e.esBajoStock).toList(),
    );
  }

  Future<void> registrarEntrada({
    required String insumoId,
    required double cantidad,
    required double costoTotal,
    String proveedor = '',
    String notas = '',
  }) async {
    final ahora = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();

    // Actualiza cantidad actual
    batch.update(_items.doc(insumoId), {
      'cantidadActual': FieldValue.increment(cantidad),
      'costoUnitario': cantidad > 0 ? costoTotal / cantidad : 0,
      'ultimaActualizacion': Timestamp.fromDate(ahora),
    });

    // Registra el movimiento
    final movRef = _movs.doc();
    batch.set(movRef, {
      'insumoId': insumoId,
      'tipo': TipoMovimiento.entrada.name,
      'cantidad': cantidad,
      'costoTotal': costoTotal,
      'proveedor': proveedor,
      'fecha': Timestamp.fromDate(ahora),
      'notas': notas,
    });

    await batch.commit();
  }

  Future<void> registrarSalida({
    required String insumoId,
    required double cantidad,
    String notas = '',
  }) async {
    final ahora = DateTime.now();
    final batch = FirebaseFirestore.instance.batch();

    batch.update(_items.doc(insumoId), {
      'cantidadActual': FieldValue.increment(-cantidad),
      'ultimaActualizacion': Timestamp.fromDate(ahora),
    });

    final movRef = _movs.doc();
    batch.set(movRef, {
      'insumoId': insumoId,
      'tipo': TipoMovimiento.salida.name,
      'cantidad': cantidad,
      'costoTotal': 0,
      'proveedor': '',
      'fecha': Timestamp.fromDate(ahora),
      'notas': notas,
    });

    await batch.commit();
  }

  Future<void> ajustarStock(String insumoId, double nuevaCantidad) async {
    await _items.doc(insumoId).update({
      'cantidadActual': nuevaCantidad,
      'ultimaActualizacion': Timestamp.fromDate(DateTime.now()),
    });
  }

  Future<List<InventoryMovementModel>> getMovimientos(
    String insumoId, {
    int limite = 20,
  }) async {
    if (!_disponible) return [];
    final snap = await _movs
        .where('insumoId', isEqualTo: insumoId)
        .orderBy('fecha', descending: true)
        .limit(limite)
        .get();
    return snap.docs
        .map(
          (d) => InventoryMovementModel.fromFirestore(
            d,
          ),
        )
        .toList();
  }

  Future<void> crear(InventoryItemModel insumo) async {
    await _items.doc(insumo.id).set(insumo.toFirestore());
  }
}
