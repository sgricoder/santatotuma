import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/payment_model.dart';

class PaymentRepository {
  final _col = FirebaseFirestore.instance.collection('payments');

  bool get _disponible => Firebase.apps.isNotEmpty;

  Future<void> registrar(PaymentModel pago) async {
    await _col.doc(pago.id).set(pago.toFirestore());
  }

  Future<List<PaymentModel>> getPorFecha(
    DateTime desde,
    DateTime hasta,
  ) async {
    if (!_disponible) return [];
    final snap = await _col
        .where('fecha',
            isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .where('fecha', isLessThanOrEqualTo: Timestamp.fromDate(hasta))
        .orderBy('fecha', descending: true)
        .get();
    return snap.docs
        .map(
          (d) => PaymentModel.fromFirestore(
            d,
          ),
        )
        .toList();
  }

  Future<List<PaymentModel>> getPorMesa(int mesa) async {
    if (!_disponible) return [];
    final snap = await _col
        .where('mesa', isEqualTo: mesa)
        .orderBy('fecha', descending: true)
        .limit(50)
        .get();
    return snap.docs
        .map(
          (d) => PaymentModel.fromFirestore(
            d,
          ),
        )
        .toList();
  }
}
