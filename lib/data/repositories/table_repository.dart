import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/table_model.dart';

class TableRepository {
  final _col = FirebaseFirestore.instance.collection('tables');

  bool get _disponible => Firebase.apps.isNotEmpty;

  // Todas las mesas en tiempo real
  Stream<List<TableModel>> watchMesas() {
    if (!_disponible) return const Stream.empty();
    return _col.orderBy('numero').snapshots().map(
          (snap) => snap.docs
              .map(
                (d) => TableModel.fromFirestore(
                  d,
                ),
              )
              .toList(),
        );
  }

  Future<TableModel?> getMesa(int numero) async {
    if (!_disponible) return null;
    final doc = await _col.doc(numero.toString()).get();
    if (!doc.exists) return null;
    return TableModel.fromFirestore(
      doc,
    );
  }

  // Asocia un pedido a la mesa y actualiza total.
  // Usa FieldValue para que funcione offline — la escritura se encola
  // y se sincroniza automáticamente cuando regresa la conexión.
  Future<void> agregarPedido(
    int mesa,
    String ordenId,
    double montoOrden,
  ) async {
    await _col
        .doc(mesa.toString())
        .set(
          {
            'numero': mesa,
            'estado': EstadoMesa.ocupada.valor,
            'ordenesActivas': FieldValue.arrayUnion([ordenId]),
            'totalAcumulado': FieldValue.increment(montoOrden),
            'fechaApertura': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        )
        .timeout(const Duration(milliseconds: 800), onTimeout: () {});
  }

  Future<void> quitarPedido(
    int mesa,
    String ordenId,
    double montoOrden,
  ) async {
    final ref = _col.doc(mesa.toString());
    await ref
        .update({
          'ordenesActivas': FieldValue.arrayRemove([ordenId]),
          'totalAcumulado': FieldValue.increment(-montoOrden),
        })
        .timeout(const Duration(milliseconds: 800), onTimeout: () {});
    // Si ya no quedan órdenes activas, liberar la mesa
    final snap = await ref.get();
    final ordenes = snap.data()?['ordenesActivas'] as List? ?? [];
    if (ordenes.isEmpty) await cerrar(mesa);
  }

  Future<void> marcarPendienteCobro(int mesa) async {
    await _col
        .doc(mesa.toString())
        .update({'estado': EstadoMesa.pendienteCobro.valor})
        .timeout(const Duration(milliseconds: 800), onTimeout: () {});
  }

  Future<void> marcarPagada(int mesa) async {
    await _col
        .doc(mesa.toString())
        .update({'estado': EstadoMesa.pagada.valor})
        .timeout(const Duration(milliseconds: 800), onTimeout: () {});
  }

  Future<void> cerrar(int mesa) async {
    await _col
        .doc(mesa.toString())
        .set({
          'numero': mesa,
          'estado': EstadoMesa.libre.valor,
          'ordenesActivas': [],
          'totalAcumulado': 0,
          'fechaApertura': null,
        })
        .timeout(const Duration(milliseconds: 800), onTimeout: () {});
  }

  // Inicializa las 15 mesas si no existen
  Future<void> inicializarMesas() async {
    if (!_disponible) return;
    final batch = FirebaseFirestore.instance.batch();
    for (int i = 1; i <= 15; i++) {
      final ref = _col.doc(i.toString());
      final snap = await ref.get();
      if (!snap.exists) {
        batch.set(ref, {
          'numero': i,
          'estado': EstadoMesa.libre.valor,
          'ordenesActivas': [],
          'totalAcumulado': 0,
          'fechaApertura': null,
        });
      }
    }
    await batch.commit();
  }
}
