import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/configuracion_controller.dart';
import '../../controllers/home_controller.dart';
import '../../widgets/pin_sheet.dart';
import '../kitchen/kitchen_screen.dart';
import '../more/more_screen.dart';
import '../orders/orders_screen.dart';
import '../sales/sales_screen.dart';
import '../tables/tables_screen.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  ConfiguracionController get _cfg => Get.find<ConfiguracionController>();

  // dev=false → [Pedido→0, Cocina→1, Mesas→2, Más→4]
  // dev=true  → [Pedido→0, Cocina→1, Mesas→2, Reportes→3, Más→4]
  List<int> _indexMap(bool dev) => dev ? [0, 1, 2, 3, 4] : [0, 1, 2, 4];

  int _navToStack(int navIdx, bool dev) => _indexMap(dev)[navIdx];

  int _stackToNav(int stackIdx, bool dev) {
    final idx = _indexMap(dev).indexOf(stackIdx);
    return idx < 0 ? 0 : idx;
  }

  Future<void> _onTabSelected(BuildContext context, int navIdx, bool dev) async {
    final stackIdx = _navToStack(navIdx, dev);
    if (stackIdx == 3 && controller.currentIndex.value != 3) {
      final ok = await PinSheet.mostrar(context);
      if (ok != true) return;
    }
    controller.changeTo(stackIdx);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            OrdersScreen(),   // stack 0
            KitchenScreen(),  // stack 1
            TablesScreen(),   // stack 2
            SalesScreen(),    // stack 3 — Reportes (dev only)
            MoreScreen(),     // stack 4
          ],
        ),
      ),
      bottomNavigationBar: Obx(() {
        final dev = _cfg.mostrarDevModulos.value;
        final stackIdx = controller.currentIndex.value;
        final navIdx = _stackToNav(stackIdx, dev);

        return NavigationBar(
          selectedIndex: navIdx,
          onDestinationSelected: (i) => _onTabSelected(context, i, dev),
          destinations: [
            const NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Pedido',
            ),
            const NavigationDestination(
              icon: Icon(Icons.soup_kitchen_outlined),
              selectedIcon: Icon(Icons.soup_kitchen),
              label: 'Cocina',
            ),
            const NavigationDestination(
              icon: Icon(Icons.table_restaurant_outlined),
              selectedIcon: Icon(Icons.table_restaurant),
              label: 'Mesas',
            ),
            if (dev)
              const NavigationDestination(
                icon: Icon(Icons.bar_chart_outlined),
                selectedIcon: Icon(Icons.bar_chart),
                label: 'Reportes',
              ),
            const NavigationDestination(
              icon: Icon(Icons.more_horiz_outlined),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'Más',
            ),
          ],
        );
      }),
    );
  }
}
