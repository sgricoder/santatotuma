import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../widgets/pin_sheet.dart';
import '../kitchen/kitchen_screen.dart';
import '../more/more_screen.dart';
import '../orders/orders_screen.dart';
import '../sales/sales_screen.dart';
import '../tables/tables_screen.dart';

class HomeScreen extends GetView<HomeController> {
  const HomeScreen({super.key});

  Future<void> _onTabSelected(BuildContext context, int index) async {
    if (index == 3 && controller.currentIndex.value != 3) {
      final ok = await PinSheet.mostrar(context);
      if (ok != true) return;
    }
    controller.changeTo(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => IndexedStack(
          index: controller.currentIndex.value,
          children: const [
            OrdersScreen(),
            KitchenScreen(),
            TablesScreen(),
            SalesScreen(),
            MoreScreen(),
          ],
        ),
      ),
      bottomNavigationBar: Obx(
        () => NavigationBar(
          selectedIndex: controller.currentIndex.value,
          onDestinationSelected: (i) => _onTabSelected(context, i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.restaurant_menu_outlined),
              selectedIcon: Icon(Icons.restaurant_menu),
              label: 'Pedido',
            ),
            NavigationDestination(
              icon: Icon(Icons.soup_kitchen_outlined),
              selectedIcon: Icon(Icons.soup_kitchen),
              label: 'Cocina',
            ),
            NavigationDestination(
              icon: Icon(Icons.table_restaurant_outlined),
              selectedIcon: Icon(Icons.table_restaurant),
              label: 'Mesas',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reportes',
            ),
            NavigationDestination(
              icon: Icon(Icons.more_horiz_outlined),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'Más',
            ),
          ],
        ),
      ),
    );
  }
}
