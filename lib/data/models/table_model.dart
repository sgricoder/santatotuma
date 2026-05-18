import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoMesa {
  libre,
  ocupada,
  pendienteCobro,
  pagada;

  static EstadoMesa fromString(String s) => switch (s) {
        'libre' => EstadoMesa.libre,
        'ocupada' => EstadoMesa.ocupada,
        'pendiente_cobro' => EstadoMesa.pendienteCobro,
        'pagada' => EstadoMesa.pagada,
        _ => EstadoMesa.libre,
      };

  String get valor => switch (this) {
        EstadoMesa.libre => 'libre',
        EstadoMesa.ocupada => 'ocupada',
        EstadoMesa.pendienteCobro => 'pendiente_cobro',
        EstadoMesa.pagada => 'pagada',
      };

  String get etiqueta => switch (this) {
        EstadoMesa.libre => 'Libre',
        EstadoMesa.ocupada => 'Ocupada',
        EstadoMesa.pendienteCobro => 'Por cobrar',
        EstadoMesa.pagada => 'Pagada',
      };
}

class TableModel {
  final int numero;
  final EstadoMesa estado;
  final List<String> ordenesActivas;
  final double totalAcumulado;
  final DateTime? fechaApertura;
  final String nombreCliente;

  const TableModel({
    required this.numero,
    this.estado = EstadoMesa.libre,
    this.ordenesActivas = const [],
    this.totalAcumulado = 0,
    this.fechaApertura,
    this.nombreCliente = '',
  });

  factory TableModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return TableModel(
      numero: int.parse(doc.id),
      estado: EstadoMesa.fromString(d['estado'] as String? ?? 'libre'),
      ordenesActivas: List<String>.from(d['ordenesActivas'] as List? ?? []),
      totalAcumulado: (d['totalAcumulado'] as num?)?.toDouble() ?? 0,
      fechaApertura: d['fechaApertura'] != null
          ? (d['fechaApertura'] as Timestamp).toDate()
          : null,
      nombreCliente: d['nombreCliente'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'numero': numero,
        'estado': estado.valor,
        'ordenesActivas': ordenesActivas,
        'totalAcumulado': totalAcumulado,
        'fechaApertura':
            fechaApertura != null ? Timestamp.fromDate(fechaApertura!) : null,
        'nombreCliente': nombreCliente,
      };

  TableModel copyWith({
    EstadoMesa? estado,
    List<String>? ordenesActivas,
    double? totalAcumulado,
    DateTime? fechaApertura,
    String? nombreCliente,
  }) =>
      TableModel(
        numero: numero,
        estado: estado ?? this.estado,
        ordenesActivas: ordenesActivas ?? this.ordenesActivas,
        totalAcumulado: totalAcumulado ?? this.totalAcumulado,
        fechaApertura: fechaApertura ?? this.fechaApertura,
        nombreCliente: nombreCliente ?? this.nombreCliente,
      );

  bool get estaLibre => estado == EstadoMesa.libre;
}
