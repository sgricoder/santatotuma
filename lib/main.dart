import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/bindings/app_bindings.dart';
import 'core/constants/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'data/seeds/inventory_seed.dart';
import 'data/seeds/products_seed.dart';
import 'firebase_options.dart';
import 'presentation/screens/cash/cash_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/inventory/inventory_screen.dart';
import 'presentation/screens/orders/cart_screen.dart';
import 'presentation/screens/tesoreria/tesoreria_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_CO');
  await _initFirebase();
  runApp(const SantaTotomaApp());
}

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase inicializado');
  } catch (e) {
    debugPrint('❌ Firebase init falló: $e');
    return;
  }

  // Persistence en su propio bloque — si falla (ej. Firestore ya activo),
  // el app sigue funcionando con la configuración por defecto.
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
    debugPrint('✅ Firestore persistence habilitada');
  } catch (e) {
    debugPrint('⚠️  Firestore settings falló (probablemente ya configurado): $e');
  }

  // Sesión anónima — requerida por las reglas de Firestore.
  // Firebase la reutiliza entre sesiones; no crea usuario nuevo cada vez.
  // Si falla offline, el app sigue — Firebase usa las credenciales cacheadas.
  try {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
      debugPrint('✅ Sesión anónima creada');
    } else {
      debugPrint(
        '✅ Sesión anónima reutilizada (uid: ${auth.currentUser!.uid})',
      );
    }
  } catch (e) {
    debugPrint('⚠️  Auth anónima falló (modo offline): $e');
    // No retornamos — el app funciona offline con credenciales cacheadas
  }

  try {
    await Future.wait([ProductsSeed.sembrar(), InventorySeed.sembrar()]);
    await InventorySeed.actualizarNombresSalsas();
    debugPrint('✅ Seeds completados');
  } catch (e) {
    debugPrint('⚠️  Seeds fallaron: $e');
  }
}

class SantaTotomaApp extends StatelessWidget {
  const SantaTotomaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Santa Totuma',
      theme: AppTheme.tema,
      debugShowCheckedModeBanner: false,
      defaultTransition: Transition.cupertino,
      transitionDuration: const Duration(milliseconds: 280),
      initialBinding: AppBindings(),
      home: const HomeScreen(),
      // Pantallas completas (sin bottom nav)
      getPages: [
        GetPage(name: AppRoutes.comanda, page: () => const CartScreen()),
        GetPage(
          name: AppRoutes.inventario,
          page: () => const InventoryScreen(),
        ),
        GetPage(name: AppRoutes.caja, page: () => const CashScreen()),
        GetPage(
          name: AppRoutes.tesoreria,
          page: () => const TesoreriaScreen(),
        ),
      ],
    );
  }
}
