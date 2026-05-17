import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../controllers/configuracion_controller.dart';
import '../../widgets/premium_app_bar.dart';

class ConfiguracionScreen extends GetView<ConfiguracionController> {
  const ConfiguracionScreen({super.key});

  void _mostrarDialogoAgregar(BuildContext context) {
    final textCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Nueva salsa',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.cafeOscuro,
          ),
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Nombre de la salsa...',
            prefixIcon: Icon(Icons.local_fire_department_rounded),
          ),
          onSubmitted: (_) {
            controller.agregarSalsa(textCtrl.text);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Cancelar',
                style: GoogleFonts.nunito(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () {
              controller.agregarSalsa(textCtrl.text);
              Navigator.of(context).pop();
            },
            child: Text(
              'Agregar',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: AppColors.verdeOlivo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoEditar(BuildContext context, String nombre) {
    final textCtrl = TextEditingController(text: nombre);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Editar salsa',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.cafeOscuro,
          ),
        ),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'Nombre de la salsa...',
            prefixIcon: Icon(Icons.local_fire_department_rounded),
          ),
          onSubmitted: (_) {
            controller.editarSalsa(nombre, textCtrl.text);
            Navigator.of(context).pop();
          },
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Cancelar',
                style: GoogleFonts.nunito(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () {
              controller.editarSalsa(nombre, textCtrl.text);
              Navigator.of(context).pop();
            },
            child: Text(
              'Guardar',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: AppColors.verdeOlivo,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmarEliminar(BuildContext context, String nombre) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Eliminar salsa',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.cafeOscuro,
          ),
        ),
        content: Text(
          '¿Eliminar "$nombre" de las opciones?',
          style: GoogleFonts.nunito(fontSize: 14, color: AppColors.cafeMedio),
        ),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text('Cancelar',
                style: GoogleFonts.nunito(color: AppColors.cafeMedio)),
          ),
          TextButton(
            onPressed: () {
              controller.eliminarSalsa(nombre);
              Navigator.of(context).pop();
            },
            child: Text(
              'Eliminar',
              style: GoogleFonts.nunito(
                fontWeight: FontWeight.w700,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: PremiumAppBar(
        titulo: 'Configuración',
        subtitulo: 'Preferencias de la aplicación',
        icono: Icons.settings_outlined,
        mostrarBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SeccionTitulo(label: 'Menú'),
          const SizedBox(height: 10),
          _SalsasCard(
            ctrl: controller,
            onAgregar: () => _mostrarDialogoAgregar(context),
            onEditar: (nombre) => _mostrarDialogoEditar(context, nombre),
            onEliminar: (nombre) => _confirmarEliminar(context, nombre),
          ),
          const SizedBox(height: 20),
          _SeccionTitulo(label: 'Desarrollo'),
          const SizedBox(height: 10),
          _ToggleCard(
            icono: Icons.code_outlined,
            titulo: 'Módulos en desarrollo',
            subtitulo: 'Muestra funciones que aún están en prueba',
            colorIcono: AppColors.dorado,
            onChanged: controller.setDevModulos,
            valorObs: controller.mostrarDevModulos,
          ),
        ],
      ),
    );
  }
}

class _SalsasCard extends StatelessWidget {
  final ConfiguracionController ctrl;
  final VoidCallback onAgregar;
  final void Function(String) onEditar;
  final void Function(String) onEliminar;

  const _SalsasCard({
    required this.ctrl,
    required this.onAgregar,
    required this.onEditar,
    required this.onEliminar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Encabezado
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.verdeOlivo.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.verdeOlivo,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Salsas disponibles',
                        style: GoogleFonts.nunito(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                      Obx(() => Text(
                            '${ctrl.salsas.length} opciones',
                            style: GoogleFonts.nunito(
                              fontSize: 12,
                              color: AppColors.cafeMedio,
                            ),
                          )),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: onAgregar,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  color: AppColors.verdeOlivo,
                  tooltip: 'Agregar salsa',
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1),
          // Lista de salsas
          Obx(() {
            if (ctrl.salsas.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Sin salsas configuradas',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    color: AppColors.cafeMedio,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            }
            return Column(
              children: ctrl.salsas.asMap().entries.map((e) {
                final ultimo = e.key == ctrl.salsas.length - 1;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.drag_indicator_outlined,
                            size: 18,
                            color: AppColors.cremaOscura,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              e.value,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: AppColors.cafeOscuro,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => onEditar(e.value),
                            icon: const Icon(Icons.edit_outlined),
                            color: AppColors.cafeMedio,
                            iconSize: 20,
                            splashRadius: 20,
                            tooltip: 'Editar',
                          ),
                          IconButton(
                            onPressed: () => onEliminar(e.value),
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: AppColors.error,
                            iconSize: 20,
                            splashRadius: 20,
                            tooltip: 'Eliminar',
                          ),
                        ],
                      ),
                    ),
                    if (!ultimo)
                      const Divider(
                          height: 1, thickness: 0.6, indent: 44, endIndent: 16),
                  ],
                );
              }).toList(),
            );
          }),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  final String label;
  const _SeccionTitulo({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.nunito(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: AppColors.cafeMedio,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _ToggleCard extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Color colorIcono;
  final RxBool valorObs;
  final Future<void> Function(bool) onChanged;

  const _ToggleCard({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.colorIcono,
    required this.valorObs,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(18),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Obx(() => SwitchListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            secondary: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: colorIcono.withAlpha(20),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icono, color: colorIcono, size: 22),
            ),
            title: Text(
              titulo,
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.cafeOscuro,
              ),
            ),
            subtitle: Text(
              subtitulo,
              style: GoogleFonts.nunito(
                fontSize: 12,
                color: AppColors.cafeMedio,
              ),
            ),
            value: valorObs.value,
            activeColor: AppColors.verdeOlivo,
            onChanged: onChanged,
          )),
    );
  }
}
