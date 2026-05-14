import 'package:cloud_firestore/cloud_firestore.dart';

import 'order_model.dart';

class PaymentModel {
  final String id;
  final String ordenId;
  final int mesa;
  final double monto;
  final MetodoPago metodo;
  final DateTime fecha;

  const PaymentModel({
    required this.id,
    required this.ordenId,
    required this.mesa,
    required this.monto,
    required this.metodo,
    required this.fecha,
  });

  factory PaymentModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return PaymentModel(
      id: doc.id,
      ordenId: d['ordenId'] as String,
      mesa: (d['mesa'] as num).toInt(),
      monto: (d['monto'] as num).toDouble(),
      metodo: MetodoPago.fromString(d['metodo'] as String),
      fecha: (d['fecha'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'ordenId': ordenId,
        'mesa': mesa,
        'monto': monto,
        'metodo': metodo.name,
        'fecha': Timestamp.fromDate(fecha),
      };
}
