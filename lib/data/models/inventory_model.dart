import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoriaInsumo {
  carnes,
  vegetales,
  lacteos,
  salsas,
  empaque,
  otros;

  String get etiqueta => switch (this) {
        CategoriaInsumo.carnes => 'Carnes',
        CategoriaInsumo.vegetales => 'Vegetales',
        CategoriaInsumo.lacteos => 'Lácteos',
        CategoriaInsumo.salsas => 'Salsas',
        CategoriaInsumo.empaque => 'Empaque',
        CategoriaInsumo.otros => 'Otros',
      };

  static CategoriaInsumo fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => CategoriaInsumo.otros,
      );
}

enum TipoMovimiento {
  entrada,
  salida,
  ajuste;

  static TipoMovimiento fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => TipoMovimiento.entrada,
      );
}

class InventoryItemModel {
  final String id;
  final String nombre;
  final CategoriaInsumo categoria;
  final String unidad;
  final double cantidadActual;
  final double stockMinimo;
  final double costoUnitario;
  final DateTime ultimaActualizacion;

  const InventoryItemModel({
    required this.id,
    required this.nombre,
    required this.categoria,
    required this.unidad,
    required this.cantidadActual,
    required this.stockMinimo,
    required this.costoUnitario,
    required this.ultimaActualizacion,
  });

  bool get esBajoStock => cantidadActual <= stockMinimo;

  factory InventoryItemModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return InventoryItemModel(
      id: doc.id,
      nombre: d['nombre'] as String,
      categoria: CategoriaInsumo.fromString(d['categoria'] as String),
      unidad: d['unidad'] as String,
      cantidadActual: (d['cantidadActual'] as num).toDouble(),
      stockMinimo: (d['stockMinimo'] as num).toDouble(),
      costoUnitario: (d['costoUnitario'] as num).toDouble(),
      ultimaActualizacion:
          (d['ultimaActualizacion'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nombre': nombre,
        'categoria': categoria.name,
        'unidad': unidad,
        'cantidadActual': cantidadActual,
        'stockMinimo': stockMinimo,
        'costoUnitario': costoUnitario,
        'ultimaActualizacion': Timestamp.fromDate(ultimaActualizacion),
      };

  InventoryItemModel copyWith({
    double? cantidadActual,
    double? costoUnitario,
    DateTime? ultimaActualizacion,
  }) =>
      InventoryItemModel(
        id: id,
        nombre: nombre,
        categoria: categoria,
        unidad: unidad,
        cantidadActual: cantidadActual ?? this.cantidadActual,
        stockMinimo: stockMinimo,
        costoUnitario: costoUnitario ?? this.costoUnitario,
        ultimaActualizacion: ultimaActualizacion ?? this.ultimaActualizacion,
      );
}

class InventoryMovementModel {
  final String id;
  final String insumoId;
  final TipoMovimiento tipo;
  final double cantidad;
  final double costoTotal;
  final String proveedor;
  final DateTime fecha;
  final String notas;

  const InventoryMovementModel({
    required this.id,
    required this.insumoId,
    required this.tipo,
    required this.cantidad,
    required this.costoTotal,
    required this.fecha,
    this.proveedor = '',
    this.notas = '',
  });

  factory InventoryMovementModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return InventoryMovementModel(
      id: doc.id,
      insumoId: d['insumoId'] as String,
      tipo: TipoMovimiento.fromString(d['tipo'] as String),
      cantidad: (d['cantidad'] as num).toDouble(),
      costoTotal: (d['costoTotal'] as num).toDouble(),
      proveedor: d['proveedor'] as String? ?? '',
      fecha: (d['fecha'] as Timestamp).toDate(),
      notas: d['notas'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
        'insumoId': insumoId,
        'tipo': tipo.name,
        'cantidad': cantidad,
        'costoTotal': costoTotal,
        'proveedor': proveedor,
        'fecha': Timestamp.fromDate(fecha),
        'notas': notas,
      };
}
