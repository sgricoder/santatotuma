import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoCaja {
  abierta,
  cerrada;

  static EstadoCaja fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => EstadoCaja.abierta,
      );
}

enum CategoriaGasto {
  proveedor,
  personal,
  mercado,
  otro;

  String get etiqueta => switch (this) {
        CategoriaGasto.proveedor => 'Proveedor',
        CategoriaGasto.personal => 'Personal',
        CategoriaGasto.mercado => 'Mercado',
        CategoriaGasto.otro => 'Otro',
      };

  static CategoriaGasto fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => CategoriaGasto.otro,
      );
}

class CashOutModel {
  final String concepto;
  final double monto;
  final CategoriaGasto categoria;
  final DateTime hora;

  const CashOutModel({
    required this.concepto,
    required this.monto,
    required this.categoria,
    required this.hora,
  });

  factory CashOutModel.fromMap(Map<String, dynamic> m) => CashOutModel(
        concepto: m['concepto'] as String,
        monto: (m['monto'] as num).toDouble(),
        categoria: CategoriaGasto.fromString(m['categoria'] as String),
        hora: (m['hora'] as Timestamp).toDate(),
      );

  Map<String, dynamic> toMap() => {
        'concepto': concepto,
        'monto': monto,
        'categoria': categoria.name,
        'hora': Timestamp.fromDate(hora),
      };
}

class CashRegisterModel {
  // El ID del documento es la fecha: "2024-01-15"
  final String id;
  final DateTime fecha;
  final double aperturaMonto;
  final double? cierreMonto;
  final List<CashOutModel> salidas;
  final EstadoCaja estado;

  const CashRegisterModel({
    required this.id,
    required this.fecha,
    required this.aperturaMonto,
    required this.salidas,
    required this.estado,
    this.cierreMonto,
  });

  double get totalSalidas => salidas.fold(0, (s, e) => s + e.monto);

  double get diferencia {
    if (cierreMonto == null) return 0;
    return cierreMonto! - aperturaMonto - totalSalidas;
  }

  factory CashRegisterModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return CashRegisterModel(
      id: doc.id,
      fecha: (d['fecha'] as Timestamp).toDate(),
      aperturaMonto: (d['aperturaMonto'] as num).toDouble(),
      cierreMonto: d['cierreMonto'] != null
          ? (d['cierreMonto'] as num).toDouble()
          : null,
      salidas: (d['salidas'] as List? ?? [])
          .map((e) => CashOutModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      estado: EstadoCaja.fromString(d['estado'] as String),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'fecha': Timestamp.fromDate(fecha),
        'aperturaMonto': aperturaMonto,
        'cierreMonto': cierreMonto,
        'salidas': salidas.map((e) => e.toMap()).toList(),
        'estado': estado.name,
      };

  CashRegisterModel copyWith({
    double? cierreMonto,
    List<CashOutModel>? salidas,
    EstadoCaja? estado,
  }) =>
      CashRegisterModel(
        id: id,
        fecha: fecha,
        aperturaMonto: aperturaMonto,
        cierreMonto: cierreMonto ?? this.cierreMonto,
        salidas: salidas ?? this.salidas,
        estado: estado ?? this.estado,
      );
}
