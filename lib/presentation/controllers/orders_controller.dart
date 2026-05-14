import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../data/models/product_model.dart';
import '../../data/repositories/product_repository.dart';

class OrdersController extends GetxController {
  ProductRepository get _repo => Get.find<ProductRepository>();

  final _todos = <ProductModel>[].obs;
  final filtrados = <ProductModel>[].obs;
  final categoriaActiva = Rx<CategoriaProducto?>(null);
  final cargando = true.obs;
  final errorMsg = ''.obs;

  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _suscribir();
    ever(categoriaActiva, (_) => _filtrar());
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _suscribir() {
    _sub?.cancel();
    cargando.value = true;
    errorMsg.value = '';
    _sub = _repo.watchProductos().listen(
      (lista) {
        _todos.value = lista;
        _filtrar();
        cargando.value = false;
      },
      onError: (e, st) {
        debugPrint('❌ OrdersController error: $e\n$st');
        errorMsg.value = 'No se pudieron cargar los productos';
        cargando.value = false;
      },
    );
  }

  void recargar() => _suscribir();

  void seleccionarCategoria(CategoriaProducto? cat) {
    categoriaActiva.value = cat;
  }

  void _filtrar() {
    final cat = categoriaActiva.value;
    filtrados.value = cat == null
        ? List<ProductModel>.from(_todos)
        : _todos.where((p) => p.categoria == cat).toList();
  }
}
