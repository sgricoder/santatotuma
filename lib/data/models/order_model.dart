import 'package:cloud_firestore/cloud_firestore.dart';

enum EstadoPedido {
  cocina,
  despachado,
  pagado,
  cancelado;

  static EstadoPedido fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => EstadoPedido.cocina,
      );
}

enum MetodoPago {
  efectivo,
  bancolombia;

  String get etiqueta => switch (this) {
        MetodoPago.efectivo => 'Efectivo',
        MetodoPago.bancolombia => 'Bancolombia',
      };

  static MetodoPago fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => MetodoPago.efectivo,
      );
}

class OrderItemModel {
  final String productoId;
  final String nombre;
  final int cantidad;
  final double precioUnitario;
  final double subtotal;
  final List<String> ingredientes;
  final List<String> salsas;
  final String? categoria;

  const OrderItemModel({
    required this.productoId,
    required this.nombre,
    required this.cantidad,
    required this.precioUnitario,
    required this.subtotal,
    this.ingredientes = const [],
    this.salsas = const [],
    this.categoria,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> m) => OrderItemModel(
        productoId: m['productoId'] as String,
        nombre: m['nombre'] as String,
        cantidad: (m['cantidad'] as num).toInt(),
        precioUnitario: (m['precioUnitario'] as num).toDouble(),
        subtotal: (m['subtotal'] as num).toDouble(),
        ingredientes: List<String>.from(m['ingredientes'] as List? ?? []),
        salsas: List<String>.from(m['salsas'] as List? ?? []),
        categoria: m['categoria'] as String?,
      );

  Map<String, dynamic> toMap() => {
        'productoId': productoId,
        'nombre': nombre,
        'cantidad': cantidad,
        'precioUnitario': precioUnitario,
        'subtotal': subtotal,
        'ingredientes': ingredientes,
        'salsas': salsas,
        if (categoria != null) 'categoria': categoria,
      };

  OrderItemModel copyWith({int? cantidad, List<String>? salsas}) {
    final nuevaCantidad = cantidad ?? this.cantidad;
    return OrderItemModel(
      productoId: productoId,
      nombre: nombre,
      cantidad: nuevaCantidad,
      precioUnitario: precioUnitario,
      subtotal: precioUnitario * nuevaCantidad,
      ingredientes: ingredientes,
      salsas: salsas ?? this.salsas,
      categoria: categoria,
    );
  }
}

class OrderModel {
  final String id;
  final int numeroOrden;
  final List<OrderItemModel> items;
  final double total;
  final EstadoPedido estado;
  final int? mesa;
  final String observaciones;
  final String nombreCliente;
  final DateTime fechaCreacion;
  final DateTime fechaActualizacion;
  final MetodoPago? metodoPago;

  const OrderModel({
    required this.id,
    required this.numeroOrden,
    required this.items,
    required this.total,
    required this.estado,
    required this.fechaCreacion,
    required this.fechaActualizacion,
    this.mesa,
    this.observaciones = '',
    this.nombreCliente = '',
    this.metodoPago,
  });

  factory OrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return OrderModel(
      id: doc.id,
      numeroOrden: (d['numeroOrden'] as num).toInt(),
      items: (d['items'] as List)
          .map((e) => OrderItemModel.fromMap(e as Map<String, dynamic>))
          .toList(),
      total: (d['total'] as num).toDouble(),
      estado: EstadoPedido.fromString(d['estado'] as String),
      mesa: d['mesa'] != null ? (d['mesa'] as num).toInt() : null,
      observaciones: d['observaciones'] as String? ?? '',
      nombreCliente: d['nombreCliente'] as String? ?? '',
      fechaCreacion:
          (d['fechaCreacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fechaActualizacion:
          (d['fechaActualizacion'] as Timestamp?)?.toDate() ?? DateTime.now(),
      metodoPago: d['metodoPago'] != null
          ? MetodoPago.fromString(d['metodoPago'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'numeroOrden': numeroOrden,
        'items': items.map((e) => e.toMap()).toList(),
        'total': total,
        'estado': estado.name,
        'mesa': mesa,
        'observaciones': observaciones,
        'nombreCliente': nombreCliente,
        'fechaCreacion': Timestamp.fromDate(fechaCreacion),
        'fechaActualizacion': Timestamp.fromDate(fechaActualizacion),
        'metodoPago': metodoPago?.name,
      };

  OrderModel copyWith({
    EstadoPedido? estado,
    MetodoPago? metodoPago,
    DateTime? fechaActualizacion,
  }) =>
      OrderModel(
        id: id,
        numeroOrden: numeroOrden,
        items: items,
        total: total,
        estado: estado ?? this.estado,
        mesa: mesa,
        observaciones: observaciones,
        nombreCliente: nombreCliente,
        fechaCreacion: fechaCreacion,
        fechaActualizacion: fechaActualizacion ?? this.fechaActualizacion,
        metodoPago: metodoPago ?? this.metodoPago,
      );
}
