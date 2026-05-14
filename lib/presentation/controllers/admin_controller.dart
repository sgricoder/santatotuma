import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminController extends GetxController {
  static const _pinFallback = '1478';
  static const _prefKey = 'admin_pin';

  // PIN activo: empieza con el fallback, se reemplaza al cargar
  String _pinActivo = _pinFallback;

  final estaDesbloqueado = false.obs;
  final intentosFallidos = 0.obs;
  final bloqueadoHasta = Rx<DateTime?>(null);
  final verificando = false.obs;

  bool get estaBloqueado {
    final hasta = bloqueadoHasta.value;
    return hasta != null && DateTime.now().isBefore(hasta);
  }

  int get segundosRestantes {
    final hasta = bloqueadoHasta.value;
    if (hasta == null) return 0;
    return hasta.difference(DateTime.now()).inSeconds.clamp(0, 999);
  }

  @override
  void onInit() {
    super.onInit();
    _cargarPin();
  }

  Future<void> _cargarPin() async {
    // Cargar PIN cacheado localmente (disponible offline)
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString(_prefKey);
      if (cached != null && cached.isNotEmpty) _pinActivo = cached;
    } catch (_) {}

    await _fetchPinFirestore();
  }

  Future<void> _fetchPinFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance.doc('config/admin').get();
      final raw = doc.data()?['pin'];
      final pin = raw?.toString();
      if (pin != null && pin.length >= 4) {
        _pinActivo = pin;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_prefKey, pin);
      }
    } catch (_) {}
  }

  Future<bool> verificarPin(String pin) async {
    if (estaBloqueado || verificando.value) return false;

    verificando.value = true;

    // Refrescar PIN desde Firestore en cada intento.
    // Con offline persistence el caché local resuelve en <50ms.
    await _fetchPinFirestore();

    await Future.delayed(const Duration(milliseconds: 300));

    if (pin == _pinActivo) {
      estaDesbloqueado.value = true;
      intentosFallidos.value = 0;
      bloqueadoHasta.value = null;
      verificando.value = false;
      return true;
    }

    intentosFallidos.value++;
    if (intentosFallidos.value >= 3) {
      bloqueadoHasta.value = DateTime.now().add(const Duration(seconds: 30));
      intentosFallidos.value = 0;
    }
    verificando.value = false;
    return false;
  }

  void bloquear() => estaDesbloqueado.value = false;
}
