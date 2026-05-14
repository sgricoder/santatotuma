import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

import '../models/cash_register_model.dart';

class CashRegisterRepository {
  final _col = FirebaseFirestore.instance.collection('cash_register');
  static final _fmt = DateFormat('yyyy-MM-dd');

  bool get _disponible => Firebase.apps.isNotEmpty;

  String get _hoyId => _fmt.format(DateTime.now());

  // Caja del día actual en tiempo real
  Stream<CashRegisterModel?> watchCajaHoy() {
    if (!_disponible) return const Stream.empty();
    return _col.doc(_hoyId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return CashRegisterModel.fromFirestore(
        snap,
      );
    });
  }

  Future<CashRegisterModel?> getCajaFecha(DateTime fecha) async {
    if (!_disponible) return null;
    final id = _fmt.format(fecha);
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return CashRegisterModel.fromFirestore(
      doc,
    );
  }

  Future<CashRegisterModel> abrirCaja(double montoInicial) async {
    final id = _hoyId;
    final caja = CashRegisterModel(
      id: id,
      fecha: DateTime.now(),
      aperturaMonto: montoInicial,
      salidas: [],
      estado: EstadoCaja.abierta,
    );
    await _col.doc(id).set(caja.toFirestore());
    return caja;
  }

  Future<void> registrarSalida(CashOutModel salida) async {
    await _col.doc(_hoyId).update({
      'salidas': FieldValue.arrayUnion([salida.toMap()]),
    });
  }

  Future<void> cerrarCaja(double montoFinal) async {
    await _col.doc(_hoyId).update({
      'cierreMonto': montoFinal,
      'estado': EstadoCaja.cerrada.name,
    });
  }

  Future<void> reabrirCaja(double montoInicial) async {
    await _col.doc(_hoyId).update({
      'estado': EstadoCaja.abierta.name,
      'aperturaMonto': montoInicial,
      'cierreMonto': null,
    });
  }

  // Últimos N cierres — filtra estado en cliente para evitar índice compuesto.
  Future<List<CashRegisterModel>> getHistorial({int limite = 30}) async {
    if (!_disponible) return [];
    final snap = await _col
        .orderBy(FieldPath.documentId, descending: true)
        .limit(limite)
        .get();
    return snap.docs
        .map((d) => CashRegisterModel.fromFirestore(d))
        .where((c) => c.estado == EstadoCaja.cerrada)
        .toList();
  }
}
