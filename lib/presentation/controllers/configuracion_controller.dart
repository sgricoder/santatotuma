import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_salsas.dart';
import 'home_controller.dart';

class ConfiguracionController extends GetxController {
  static const _kDevKey = 'dev_modules';
  static const _kSalsasKey = 'salsas_list';

  final mostrarDevModulos = false.obs;
  final salsas = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    _cargar();
  }

  Future<void> _cargar() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      mostrarDevModulos.value = prefs.getBool(_kDevKey) ?? false;
      final guardadas = prefs.getStringList(_kSalsasKey);
      salsas.value =
          guardadas ?? List<String>.from(AppSalsas.disponibles);
    } catch (_) {
      salsas.value = List<String>.from(AppSalsas.disponibles);
    }
  }

  Future<void> setDevModulos(bool value) async {
    mostrarDevModulos.value = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kDevKey, value);
    } catch (_) {}
    if (!value) {
      final home = Get.find<HomeController>();
      if (home.currentIndex.value == 3) home.changeTo(0);
    }
  }

  Future<void> agregarSalsa(String nombre) async {
    final n = nombre.trim();
    if (n.isEmpty || salsas.contains(n)) return;
    salsas.add(n);
    await _guardarSalsas();
  }

  Future<void> editarSalsa(String antigua, String nueva) async {
    final n = nueva.trim();
    if (n.isEmpty || n == antigua) return;
    final idx = salsas.indexOf(antigua);
    if (idx < 0) return;
    salsas[idx] = n;
    await _guardarSalsas();
  }

  Future<void> eliminarSalsa(String nombre) async {
    salsas.remove(nombre);
    await _guardarSalsas();
  }

  Future<void> _guardarSalsas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_kSalsasKey, salsas.toList());
    } catch (_) {}
  }
}
