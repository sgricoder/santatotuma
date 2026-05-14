import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/tesoreria_model.dart';

class TesoreriaRepository {
  final _doc =
      FirebaseFirestore.instance.collection('tesoreria').doc('estado');

  CollectionReference<Map<String, dynamic>> get _movCol =>
      _doc.collection('movimientos');

  bool get _disponible => Firebase.apps.isNotEmpty;

  // ── Estado (saldo) ────────────────────────────────────────────────────────

  Stream<TesoreriaModel?> watchTesoreria() {
    if (!_disponible) return const Stream.empty();
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return null;
      return TesoreriaModel.fromFirestore(snap);
    });
  }

  // ── Movimientos (subcollección) ───────────────────────────────────────────

  Stream<List<MovimientoTes>> watchMovimientos({int limit = 50}) {
    if (!_disponible) return const Stream.empty();
    return _movCol
        .orderBy('hora', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MovimientoTes.fromFirestore(
                  d as DocumentSnapshot<Map<String, dynamic>>,
                ))
            .toList());
  }

  // ── Escrituras ────────────────────────────────────────────────────────────

  Future<void> inicializar(double saldoInicial) async {
    final batch = FirebaseFirestore.instance.batch();
    batch.set(_doc, {
      'saldo': saldoInicial,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    final primer = MovimientoTes(
      id: '',
      tipo: TipoMovimiento.ajuste,
      concepto: 'Saldo inicial',
      monto: saldoInicial,
      hora: DateTime.now(),
    );
    batch.set(_movCol.doc(), primer.toFirestore());
    await batch.commit();
  }

  Future<void> registrarMovimiento(MovimientoTes mov) async {
    if (!_disponible) return;
    final delta = mov.tipo == TipoMovimiento.gasto ? -mov.monto : mov.monto;
    final batch = FirebaseFirestore.instance.batch();
    batch.set(_movCol.doc(), mov.toFirestore());
    batch.update(_doc, {
      'saldo': FieldValue.increment(delta),
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    await batch.commit();
  }
}
