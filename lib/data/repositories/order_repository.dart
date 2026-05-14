import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/order_model.dart';

class OrderRepository {
  final _col = FirebaseFirestore.instance.collection('orders');
  final _counters = FirebaseFirestore.instance.collection('counters');

  bool get _disponible => Firebase.apps.isNotEmpty;

  // Pedidos activos en cocina (en tiempo real)
  Stream<List<OrderModel>> watchCocina() {
    if (!_disponible) return const Stream.empty();
    return _col
        .where('estado', isEqualTo: EstadoPedido.cocina.name)
        .orderBy('fechaCreacion')
        .snapshots()
        .map(_mapDocs);
  }

  // Todos los pedidos de una mesa
  Stream<List<OrderModel>> watchPedidosMesa(int mesa) {
    if (!_disponible) return const Stream.empty();
    return _col
        .where('mesa', isEqualTo: mesa)
        .where('estado', whereNotIn: [
          EstadoPedido.pagado.name,
          EstadoPedido.cancelado.name,
        ])
        .orderBy('estado')
        .orderBy('fechaCreacion')
        .snapshots()
        .map(_mapDocs);
  }

  // Pedidos por rango de fechas (para reportes).
  // El filtro de estado se aplica en cliente para evitar índice compuesto.
  Future<List<OrderModel>> getPorFecha(DateTime desde, DateTime hasta) async {
    if (!_disponible) return [];
    final snap = await _col
        .where('fechaCreacion',
            isGreaterThanOrEqualTo: Timestamp.fromDate(desde))
        .where('fechaCreacion', isLessThanOrEqualTo: Timestamp.fromDate(hasta))
        .get();
    return _mapDocs(snap)
        .where((o) => o.estado == EstadoPedido.pagado)
        .toList();
  }

  Future<OrderModel> crear(OrderModel pedido) async {
    final numero = await _getNextNumero();
    final ahora = DateTime.now();
    final nuevo = OrderModel(
      id: pedido.id,
      numeroOrden: numero,
      items: pedido.items,
      total: pedido.total,
      estado: EstadoPedido.cocina,
      mesa: pedido.mesa,
      observaciones: pedido.observaciones,
      fechaCreacion: ahora,
      fechaActualizacion: ahora,
    );
    final data = nuevo.toFirestore()
      ..['fechaCreacion'] = FieldValue.serverTimestamp()
      ..['fechaActualizacion'] = FieldValue.serverTimestamp();
    await _col
        .doc(nuevo.id)
        .set(data)
        .timeout(const Duration(milliseconds: 800), onTimeout: () {});
    return nuevo;
  }

  Future<void> cambiarEstado(
    String id,
    EstadoPedido estado, {
    MetodoPago? metodoPago,
  }) async {
    final data = {
      'estado': estado.name,
      'fechaActualizacion': FieldValue.serverTimestamp(),
      if (metodoPago != null) 'metodoPago': metodoPago.name,
    };
    await _col
        .doc(id)
        .update(data)
        .timeout(const Duration(milliseconds: 800), onTimeout: () {});
  }

  Future<void> marcarDespachado(String id) =>
      cambiarEstado(id, EstadoPedido.despachado);

  Future<void> marcarPagado(String id, MetodoPago metodo) =>
      cambiarEstado(id, EstadoPedido.pagado, metodoPago: metodo);

  // Contador en memoria para cuando SharedPreferences no está disponible
  // (e.g. primer run tras agregar el plugin sin rebuild completo).
  static int _fallbackContador = 0;

  // Contador local diario — funciona sin internet.
  // Firestore se sincroniza en segundo plano cuando hay conexión.
  Future<int> _getNextNumero() async {
    final hoy = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final key = 'order_counter_$hoy';

    try {
      final prefs = await SharedPreferences.getInstance();
      final siguiente = (prefs.getInt(key) ?? 0) + 1;
      await prefs.setInt(key, siguiente);
      // Sync en background — se encola si no hay internet
      _counters
          .doc('ordenes_$hoy')
          .set({'ultimo': siguiente, 'fecha': hoy})
          .catchError((_) {});
      return siguiente;
    } catch (_) {
      // Plugin no disponible aún (requiere rebuild completo)
      // Fallback: contador en memoria válido para la sesión actual
      _fallbackContador++;
      return _fallbackContador;
    }
  }

  List<OrderModel> _mapDocs(QuerySnapshot<Map<String, dynamic>> snap) =>
      snap.docs
      .map(
        (d) => OrderModel.fromFirestore(
          d,
        ),
      )
      .toList();
}
