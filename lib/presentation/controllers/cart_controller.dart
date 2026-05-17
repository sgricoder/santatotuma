import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/order_model.dart';
import '../../data/models/product_model.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/table_repository.dart';
import 'home_controller.dart';

class CartController extends GetxController {
  OrderRepository get _orderRepo => Get.find<OrderRepository>();
  TableRepository get _tableRepo => Get.find<TableRepository>();

  final items = <OrderItemModel>[].obs;
  final mesa = Rx<int?>(null);
  final notas = ''.obs;
  final nombreCliente = ''.obs;
  final enviando = false.obs;

  double get total => items.fold(0.0, (s, e) => s + e.subtotal);
  int get cantidadTotal => items.fold(0, (s, e) => s + e.cantidad);
  bool get estaVacio => items.isEmpty;

  void agregar(ProductModel producto, {List<String> salsas = const []}) {
    final idx = items.indexWhere((e) => e.productoId == producto.id);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(
        cantidad: items[idx].cantidad + 1,
        salsas: salsas.isNotEmpty ? salsas : null,
      );
    } else {
      items.add(OrderItemModel(
        productoId: producto.id,
        nombre: producto.nombre,
        cantidad: 1,
        precioUnitario: producto.precio,
        subtotal: producto.precio,
        ingredientes: producto.ingredientes,
        salsas: salsas,
      ));
    }
  }

  void incrementar(String productoId) {
    final idx = items.indexWhere((e) => e.productoId == productoId);
    if (idx < 0) return;
    items[idx] = items[idx].copyWith(cantidad: items[idx].cantidad + 1);
  }

  void decrementar(String productoId) {
    final idx = items.indexWhere((e) => e.productoId == productoId);
    if (idx < 0) return;
    if (items[idx].cantidad <= 1) {
      items.removeAt(idx);
    } else {
      items[idx] = items[idx].copyWith(cantidad: items[idx].cantidad - 1);
    }
  }

  void eliminar(String productoId) =>
      items.removeWhere((e) => e.productoId == productoId);

  void seleccionarMesa(int? numero) => mesa.value = numero;

  void limpiar() {
    items.clear();
    mesa.value = null;
    notas.value = '';
    nombreCliente.value = '';
  }

  Future<void> confirmar() async {
    if (items.isEmpty || enviando.value) return;
    enviando.value = true;
    try {
      final pedido = OrderModel(
        id: const Uuid().v4(),
        numeroOrden: 0, // el repo asigna el número real
        items: List<OrderItemModel>.from(items),
        total: total,
        estado: EstadoPedido.cocina,
        mesa: mesa.value,
        observaciones: notas.value.trim(),
        nombreCliente: nombreCliente.value.trim(),
        fechaCreacion: DateTime.now(),
        fechaActualizacion: DateTime.now(),
      );

      final nuevo = await _orderRepo.crear(pedido);

      if (mesa.value != null) {
        await _tableRepo.agregarPedido(mesa.value!, nuevo.id, nuevo.total);
      }

      limpiar();
      Get.back(); // cierra carrito
      Get.find<HomeController>().changeTo(1); // va a cocina

      Get.snackbar(
        '¡Pedido enviado! 🔥',
        'Orden #${nuevo.numeroOrden.toString().padLeft(3, '0')} en cocina',
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(12),
      );
    } catch (e) {
      debugPrint('❌ confirmar() error: $e');
      Get.snackbar(
        'Error',
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 6),
        margin: const EdgeInsets.all(12),
      );
    } finally {
      enviando.value = false;
    }
  }
}
