import 'package:get/get.dart';

import '../../data/repositories/cash_register_repository.dart';
import '../../data/repositories/inventory_repository.dart';
import '../../data/repositories/order_repository.dart';
import '../../data/repositories/payment_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/table_repository.dart';
import '../../presentation/controllers/cart_controller.dart';
import '../../presentation/controllers/home_controller.dart';
import '../../presentation/controllers/kitchen_controller.dart';
import '../../presentation/controllers/orders_controller.dart';
import '../../presentation/controllers/cash_controller.dart';
import '../../presentation/controllers/inventory_controller.dart';
import '../../data/repositories/tesoreria_repository.dart';
import '../../presentation/controllers/admin_controller.dart';
import '../../presentation/controllers/sales_controller.dart';
import '../../presentation/controllers/tables_controller.dart';
import '../../presentation/controllers/tesoreria_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Repositorios (acceso a Firestore)
    Get.lazyPut(() => ProductRepository(), fenix: true);
    Get.lazyPut(() => OrderRepository(), fenix: true);
    Get.lazyPut(() => TableRepository(), fenix: true);
    Get.lazyPut(() => InventoryRepository(), fenix: true);
    Get.lazyPut(() => CashRegisterRepository(), fenix: true);
    Get.lazyPut(() => PaymentRepository(), fenix: true);
    Get.lazyPut(() => TesoreriaRepository(), fenix: true);

    // Controladores permanentes (estado que debe persistir siempre)
    Get.put(HomeController(), permanent: true);
    Get.put(CartController(), permanent: true);
    Get.put(AdminController(), permanent: true);

    // Controladores de módulo (se inicializan al primer uso)
    Get.lazyPut(() => OrdersController(), fenix: true);
    Get.lazyPut(() => KitchenController(), fenix: true);
    Get.lazyPut(() => TablesController(), fenix: true);
    Get.lazyPut(() => SalesController(), fenix: true);
    Get.lazyPut(() => InventoryController(), fenix: true);
    Get.lazyPut(() => CashController(), fenix: true);
    Get.lazyPut(() => TesoreriaController(), fenix: true);
  }
}
