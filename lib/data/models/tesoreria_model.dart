import 'package:cloud_firestore/cloud_firestore.dart';

enum TipoMovimiento {
  ingresoCaja,
  consignacionBancolombia,
  gasto,
  ajuste;

  String get etiqueta => switch (this) {
        TipoMovimiento.ingresoCaja => 'Transferencia caja',
        TipoMovimiento.consignacionBancolombia => 'Bancolombia',
        TipoMovimiento.gasto => 'Gasto',
        TipoMovimiento.ajuste => 'Ajuste',
      };

  static TipoMovimiento fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => TipoMovimiento.ajuste,
      );
}

enum CategoriaGastoTes {
  nomina,
  proveedor,
  arriendo,
  servicios,
  inversion,
  otro;

  String get etiqueta => switch (this) {
        CategoriaGastoTes.nomina => 'Nómina',
        CategoriaGastoTes.proveedor => 'Proveedor',
        CategoriaGastoTes.arriendo => 'Arriendo',
        CategoriaGastoTes.servicios => 'Servicios',
        CategoriaGastoTes.inversion => 'Inversión',
        CategoriaGastoTes.otro => 'Otro',
      };

  static CategoriaGastoTes fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => CategoriaGastoTes.otro,
      );
}

// Cada movimiento vive en tesoreria/estado/movimientos/{id}
class MovimientoTes {
  final String id;
  final TipoMovimiento tipo;
  final String concepto;
  final double monto;
  final DateTime hora;
  final CategoriaGastoTes? categoria;

  const MovimientoTes({
    required this.id,
    required this.tipo,
    required this.concepto,
    required this.monto,
    required this.hora,
    this.categoria,
  });

  factory MovimientoTes.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return MovimientoTes(
      id: doc.id,
      tipo: TipoMovimiento.fromString(d['tipo'] as String),
      concepto: d['concepto'] as String,
      monto: (d['monto'] as num).toDouble(),
      hora: (d['hora'] as Timestamp).toDate(),
      categoria: d['categoria'] != null
          ? CategoriaGastoTes.fromString(d['categoria'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'tipo': tipo.name,
        'concepto': concepto,
        'monto': monto,
        'hora': Timestamp.fromDate(hora),
        if (categoria != null) 'categoria': categoria!.name,
      };
}

// Solo almacena el saldo agregado — los movimientos van en subcollección
class TesoreriaModel {
  final double saldo;
  final DateTime? updatedAt;

  const TesoreriaModel({required this.saldo, this.updatedAt});

  factory TesoreriaModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return TesoreriaModel(
      saldo: (d['saldo'] as num).toDouble(),
      updatedAt: d['updatedAt'] != null
          ? (d['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'saldo': saldo,
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      };
}
