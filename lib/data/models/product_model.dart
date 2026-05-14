import 'package:cloud_firestore/cloud_firestore.dart';

enum CategoriaProducto {
  totumas,
  entradas,
  bebidas;

  String get etiqueta => switch (this) {
        CategoriaProducto.totumas => 'Totumas',
        CategoriaProducto.entradas => 'Entradas',
        CategoriaProducto.bebidas => 'Bebidas',
      };

  static CategoriaProducto fromString(String s) => values.firstWhere(
        (e) => e.name == s,
        orElse: () => CategoriaProducto.totumas,
      );
}

class ProductModel {
  final String id;
  final String nombre;
  final String descripcion;
  final double precio;
  final CategoriaProducto categoria;
  final String urlImagen;
  final List<String> ingredientes;
  final bool activo;
  final int orden;

  const ProductModel({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.precio,
    required this.categoria,
    this.urlImagen = '',
    this.ingredientes = const [],
    this.activo = true,
    this.orden = 0,
  });

  factory ProductModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data()!;
    return ProductModel(
      id: doc.id,
      nombre: d['nombre'] as String,
      descripcion: d['descripcion'] as String? ?? '',
      precio: (d['precio'] as num).toDouble(),
      categoria: CategoriaProducto.fromString(d['categoria'] as String),
      urlImagen: d['urlImagen'] as String? ?? '',
      ingredientes: List<String>.from(d['ingredientes'] as List? ?? []),
      activo: d['activo'] as bool? ?? true,
      orden: d['orden'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'nombre': nombre,
        'descripcion': descripcion,
        'precio': precio,
        'categoria': categoria.name,
        'urlImagen': urlImagen,
        'ingredientes': ingredientes,
        'activo': activo,
        'orden': orden,
      };

  ProductModel copyWith({
    String? nombre,
    String? descripcion,
    double? precio,
    CategoriaProducto? categoria,
    String? urlImagen,
    List<String>? ingredientes,
    bool? activo,
    int? orden,
  }) =>
      ProductModel(
        id: id,
        nombre: nombre ?? this.nombre,
        descripcion: descripcion ?? this.descripcion,
        precio: precio ?? this.precio,
        categoria: categoria ?? this.categoria,
        urlImagen: urlImagen ?? this.urlImagen,
        ingredientes: ingredientes ?? this.ingredientes,
        activo: activo ?? this.activo,
        orden: orden ?? this.orden,
      );
}
