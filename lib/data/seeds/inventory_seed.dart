import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/inventory_model.dart';

abstract final class InventorySeed {
  static final _insumos = [
    // ── Carnes ────────────────────────────────────────────────────────────
    _item(
      'costilla-cerdo',
      'Costilla cerdo',
      CategoriaInsumo.carnes,
      'kg',
      5,
      2,
    ),
    _item(
      'solomito-cerdo',
      'Solomito cerdo',
      CategoriaInsumo.carnes,
      'kg',
      5,
      2,
    ),
    _item('pierna-cerdo', 'Pierna cerdo', CategoriaInsumo.carnes, 'kg', 5, 2),
    _item(
      'tocino-carnudo',
      'Tocino carnudo',
      CategoriaInsumo.carnes,
      'kg',
      3,
      1,
    ),
    _item(
      'solomo-extranjero',
      'Solomo extranjero',
      CategoriaInsumo.carnes,
      'kg',
      5,
      2,
    ),
    _item('pollo', 'Pollo', CategoriaInsumo.carnes, 'kg', 10, 3),

    // ── Vegetales ─────────────────────────────────────────────────────────
    _item(
      'platano-verde',
      'Plátano verde',
      CategoriaInsumo.vegetales,
      'unidad',
      50,
      20,
    ),
    _item(
      'platano-maduro',
      'Plátano maduro',
      CategoriaInsumo.vegetales,
      'unidad',
      20,
      10,
    ),
    _item('aguacate', 'Aguacate', CategoriaInsumo.vegetales, 'unidad', 20, 8),
    _item('tomate', 'Tomate', CategoriaInsumo.vegetales, 'kg', 5, 2),
    _item('cebolla', 'Cebolla', CategoriaInsumo.vegetales, 'kg', 5, 2),
    _item('cilantro', 'Cilantro', CategoriaInsumo.vegetales, 'manojo', 5, 2),
    _item(
      'pimenton-dulce',
      'Pimentón dulce',
      CategoriaInsumo.vegetales,
      'unidad',
      1,
      2,
    ),
    _item('champinones', 'Champiñones', CategoriaInsumo.vegetales, 'kg', 3, 1),
    _item('maiz-tierno', 'Maíz tierno', CategoriaInsumo.vegetales, 'kg', 3, 1),

    // ── Lácteos ───────────────────────────────────────────────────────────
    _item(
      'queso-mozzarella',
      'Queso mozzarella',
      CategoriaInsumo.lacteos,
      'kg',
      5,
      2,
    ),
    _item('queso-crema', 'Queso crema', CategoriaInsumo.lacteos, 'kg', 3, 1),
    _item(
      'sour-cream',
      'Sour cream',
      CategoriaInsumo.lacteos,
      'gramos',
      200,
      100,
    ),

    // ── Carnes procesadas ─────────────────────────────────────────────────
    _item('tocineta', 'Tocineta', CategoriaInsumo.carnes, 'kg', 3, 1),

    // ── Salsas ────────────────────────────────────────────────────────────
    _item('salsas-salsana-1', 'BBQ Grill Salsana', CategoriaInsumo.salsas, 'kg', 2, 0.5),
    _item('salsas-salsana-2', 'BBQ Grill Picante', CategoriaInsumo.salsas, 'kg', 2, 0.5),
    _item('salsas-salsana-3', 'BBQ Grill Blanca x 2k', CategoriaInsumo.salsas, 'kg', 2, 0.5),
    _item('salsas-salsana-4', 'Ajo Cremoso', CategoriaInsumo.salsas, 'kg', 2, 0.5),
    _item('salsas-salsana-5', 'Crema de Cilantro', CategoriaInsumo.salsas, 'kg', 2, 0.5),
    _item('salsas-salsana-6', 'Tocineta Salsana', CategoriaInsumo.salsas, 'kg', 2, 0.5),
    _item('salsas-salsana-7', 'Chile Cremoso', CategoriaInsumo.salsas, 'kg', 2, 0.5),
    _item('salsas-salsana-8', 'Ajo Parrillero', CategoriaInsumo.salsas, 'kg', 2, 0.5),
    _item('salsas-salsana-9', 'Piña Ochua Salsana', CategoriaInsumo.salsas, 'kg', 2, 0.5),
    _item('aceite', 'Aceite', CategoriaInsumo.salsas, 'litros', 5, 2),

    // ── Empaque ───────────────────────────────────────────────────────────
    _item(
      'bowls-carton',
      'Bowls cartón 750cc',
      CategoriaInsumo.empaque,
      'unidad',
      100,
      30,
    ),
    _item(
      'bolsas-banana',
      'Bolsas banana',
      CategoriaInsumo.empaque,
      'unidad',
      200,
      50,
    ),
    _item('tenedores', 'Tenedores', CategoriaInsumo.empaque, 'unidad', 200, 50),
    _item(
      'servilletas',
      'Servilletas',
      CategoriaInsumo.empaque,
      'unidad',
      500,
      100,
    ),
    _item(
      'copas-salseras',
      'Copas salseras',
      CategoriaInsumo.empaque,
      'unidad',
      300,
      80,
    ),
    _item(
      'tapas-salseras',
      'Tapas salseras',
      CategoriaInsumo.empaque,
      'unidad',
      300,
      80,
    ),
  ];

  static InventoryItemModel _item(
    String id,
    String nombre,
    CategoriaInsumo categoria,
    String unidad,
    double cantidad,
    double stockMin,
  ) => InventoryItemModel(
    id: id,
    nombre: nombre,
    categoria: categoria,
    unidad: unidad,
    cantidadActual: cantidad,
    stockMinimo: stockMin,
    costoUnitario: 0,
    ultimaActualizacion: DateTime.now(),
  );

  /// Carga el inventario inicial en Firestore (solo si está vacío).
  static Future<void> sembrar() async {
    if (Firebase.apps.isEmpty) return;
    final col = FirebaseFirestore.instance.collection('inventory');
    final snap = await col.limit(1).get();
    if (snap.docs.isNotEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final item in _insumos) {
      batch.set(col.doc(item.id), item.toFirestore());
    }
    await batch.commit();
  }

  /// Actualiza los nombres de las salsas a los nombres reales del catálogo.
  static Future<void> actualizarNombresSalsas() async {
    if (Firebase.apps.isEmpty) return;
    final col = FirebaseFirestore.instance.collection('inventory');
    const nombres = {
      'salsas-salsana-1': 'BBQ Grill Salsana',
      'salsas-salsana-2': 'BBQ Grill Picante',
      'salsas-salsana-3': 'BBQ Grill Blanca x 2k',
      'salsas-salsana-4': 'Ajo Cremoso',
      'salsas-salsana-5': 'Crema de Cilantro',
      'salsas-salsana-6': 'Tocineta Salsana',
      'salsas-salsana-7': 'Chile Cremoso',
      'salsas-salsana-8': 'Ajo Parrillero',
    };
    final batch = FirebaseFirestore.instance.batch();
    for (final entry in nombres.entries) {
      batch.update(col.doc(entry.key), {'nombre': entry.value});
    }
    // Añadir Piña Ochua si no existe
    batch.set(
      col.doc('salsas-salsana-9'),
      _item('salsas-salsana-9', 'Piña Ochua Salsana', CategoriaInsumo.salsas,
              'kg', 2, 0.5)
          .toFirestore(),
      SetOptions(merge: true),
    );
    await batch.commit();
  }
}
