import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../models/product_model.dart';

class ProductRepository {
  final _col = FirebaseFirestore.instance.collection('products');

  bool get _disponible => Firebase.apps.isNotEmpty;

  Stream<List<ProductModel>> watchProductos({bool soloActivos = true}) {
    if (!_disponible) {
      debugPrint('⚠️  ProductRepository: Firebase no disponible');
      return const Stream.empty();
    }

    // Filtramos activo en cliente para evitar índice compuesto en Firestore.
    return _col.orderBy('orden').snapshots().map((snap) {
      final lista = snap.docs.map((d) => ProductModel.fromFirestore(d)).toList();
      debugPrint('📦 ProductRepository: ${lista.length} productos recibidos de Firestore');
      return soloActivos ? lista.where((p) => p.activo).toList() : lista;
    });
  }

  Stream<List<ProductModel>> watchPorCategoria(CategoriaProducto categoria) {
    if (!_disponible) return const Stream.empty();

    return _col
        .where('categoria', isEqualTo: categoria.name)
        .where('activo', isEqualTo: true)
        .orderBy('orden')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProductModel.fromFirestore(
                    d,
                  ))
              .toList(),
        );
  }

  Future<ProductModel?> getProducto(String id) async {
    if (!_disponible) return null;
    final doc = await _col.doc(id).get();
    if (!doc.exists) return null;
    return ProductModel.fromFirestore(
      doc,
    );
  }

  Future<void> crear(ProductModel producto) async {
    await _col.doc(producto.id).set(producto.toFirestore());
  }

  Future<void> actualizar(ProductModel producto) async {
    await _col.doc(producto.id).update(producto.toFirestore());
  }

  Future<void> toggleActivo(String id, bool activo) async {
    await _col.doc(id).update({'activo': activo});
  }
}
