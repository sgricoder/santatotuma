import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/product_model.dart';

// Incrementar este número para forzar un re-seed en todos los dispositivos.
const _kProductsVersion = 2;

abstract final class ProductsSeed {
  static final _productos = [
    // ── Totumas ──────────────────────────────────────────────────────────
    ProductModel(
      id: 'candilejas',
      nombre: 'Candilejas',
      descripcion:
          'Pollo en una de nuestras salsas BBQ, chicharrón, solomito, queso, '
          'guacamole, pico de gallo, queso crema y 3 de nuestras salsas caseras.',
      precio: 26000,
      categoria: CategoriaProducto.totumas,
      ingredientes: [
        'Pollo BBQ',
        'Chicharrón',
        'Solomito',
        'Queso mozzarella',
        'Guacamole',
        'Pico de gallo',
        'Queso crema',
        '3 salsas caseras',
      ],
      orden: 1,
    ),
    ProductModel(
      id: 'castanuelas',
      nombre: 'Castañuelas',
      descripcion:
          'Costilla en una de nuestras salsas BBQ, queso, solomo de cerdo, '
          'chicharrón, guacamole, pico de gallo, queso crema y 3 de nuestras salsas caseras.',
      precio: 26000,
      categoria: CategoriaProducto.totumas,
      ingredientes: [
        'Costilla BBQ',
        'Solomito de cerdo',
        'Chicharrón',
        'Queso mozzarella',
        'Guacamole',
        'Pico de gallo',
        'Queso crema',
        '3 salsas caseras',
      ],
      orden: 2,
    ),
    ProductModel(
      id: 'makondo',
      nombre: 'Makondo',
      descripcion:
          'Pollo en salsa de champiñones, maicitos, tocineta dorada, queso, '
          'aguacate, queso crema y 3 de nuestras salsas caseras.',
      precio: 26000,
      categoria: CategoriaProducto.totumas,
      ingredientes: [
        'Pollo',
        'Champiñones al ajillo',
        'Maicitos',
        'Tocineta dorada',
        'Queso mozzarella',
        'Aguacate',
        'Queso crema',
        '3 salsas caseras',
      ],
      orden: 3,
    ),

    // ── Entradas ─────────────────────────────────────────────────────────
    ProductModel(
      id: 'palitos_queso_x5',
      nombre: 'Palitos de Queso x5',
      descripcion:
          '5 palitos de queso mozzarella acompañados de mermelada casera de mora o guayaba.',
      precio: 10000,
      categoria: CategoriaProducto.entradas,
      ingredientes: [
        '5 palitos de queso mozzarella',
        'Mermelada casera de mora o guayaba',
      ],
      orden: 4,
    ),
    ProductModel(
      id: 'palo_queso',
      nombre: 'Palo de Queso',
      descripcion:
          '1 palo de queso mozzarella acompañado de mermelada casera de mora o guayaba.',
      precio: 5000,
      categoria: CategoriaProducto.entradas,
      ingredientes: [
        '1 palo de queso mozzarella',
        'Mermelada casera de mora o guayaba',
      ],
      orden: 5,
    ),
    ProductModel(
      id: 'chips_platano',
      nombre: 'Chips Plátano Verde',
      descripcion: 'Chips de plátano con guacamole y 2 de nuestras salsas caseras.',
      precio: 9000,
      categoria: CategoriaProducto.entradas,
      ingredientes: [
        'Chips de plátano verde',
        'Guacamole',
        '2 salsas caseras',
      ],
      orden: 6,
    ),
    ProductModel(
      id: 'aborrajado',
      nombre: 'Aborrajado de Plátano Maduro',
      descripcion:
          '5 aborrajados rellenos de queso mozzarella fundido, acompañados de '
          'mermelada artesanal de mora o guayaba.',
      precio: 10000,
      categoria: CategoriaProducto.entradas,
      ingredientes: [
        '5 aborrajados de plátano maduro',
        'Queso mozzarella fundido',
        'Mermelada artesanal de mora o guayaba',
      ],
      orden: 7,
    ),

    // ── Bebidas ──────────────────────────────────────────────────────────
    ProductModel(
      id: 'coca_cola_1500',
      nombre: 'Coca-Cola 1.5L',
      descripcion: 'Coca-Cola botella de 1.5 litros.',
      precio: 8000,
      categoria: CategoriaProducto.bebidas,
      ingredientes: [],
      orden: 8,
    ),
    ProductModel(
      id: 'coca_cola_400',
      nombre: 'Coca-Cola 400ml',
      descripcion: 'Coca-Cola personal 400ml.',
      precio: 4000,
      categoria: CategoriaProducto.bebidas,
      ingredientes: [],
      orden: 9,
    ),
    ProductModel(
      id: 'postobon_1500',
      nombre: 'Postobón 1.5L',
      descripcion: 'Postobón botella de 1.5 litros.',
      precio: 7000,
      categoria: CategoriaProducto.bebidas,
      ingredientes: [],
      orden: 10,
    ),
    ProductModel(
      id: 'postobon_400',
      nombre: 'Postobón 400ml',
      descripcion: 'Postobón personal 400ml.',
      precio: 3500,
      categoria: CategoriaProducto.bebidas,
      ingredientes: [],
      orden: 11,
    ),
    ProductModel(
      id: 'agua_cristal',
      nombre: 'Agua Cristal',
      descripcion: 'Agua Cristal.',
      precio: 3000,
      categoria: CategoriaProducto.bebidas,
      ingredientes: [],
      orden: 12,
    ),
  ];

  /// Siembra los productos reales. Usa un número de versión para re-sembrar
  /// automáticamente cuando los datos cambien sin borrar el historial de órdenes.
  static Future<void> sembrar() async {
    if (Firebase.apps.isEmpty) return;

    final fs = FirebaseFirestore.instance;
    final versionRef = fs.collection('config').doc('seed_versions');
    final snap = await versionRef.get();
    final versionActual = snap.data()?['productos'] as int? ?? 0;

    if (versionActual >= _kProductsVersion) return; // ya está al día

    // Borrar productos existentes (IDs del seed anterior)
    final productosCol = fs.collection('products');
    final existentes = await productosCol.get();
    final batchBorrar = fs.batch();
    for (final doc in existentes.docs) {
      batchBorrar.delete(doc.reference);
    }
    await batchBorrar.commit();

    // Insertar los 12 productos reales
    final batchInsertar = fs.batch();
    for (final p in _productos) {
      batchInsertar.set(productosCol.doc(p.id), p.toFirestore());
    }
    await batchInsertar.commit();

    // Guardar versión para no re-sembrar en el próximo inicio
    await versionRef.set({'productos': _kProductsVersion}, SetOptions(merge: true));
  }
}
