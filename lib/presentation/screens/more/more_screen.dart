import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../controllers/configuracion_controller.dart';
import '../../widgets/pin_sheet.dart';
import '../../widgets/premium_app_bar.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  ConfiguracionController get _cfg => Get.find<ConfiguracionController>();

  Future<void> _abrirConPin(BuildContext context, String ruta) async {
    final ok = await PinSheet.mostrar(context);
    if (ok != true) return;
    await Get.toNamed(ruta);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: PremiumAppBar(
        titulo: 'Más opciones',
        subtitulo: 'Herramientas de gestión',
        icono: Icons.tune_rounded,
      ),
      body: Obx(() {
        final dev = _cfg.mostrarDevModulos.value;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          children: [
            _MoreOptionCard(
              icon: Icons.inventory_2_outlined,
              titulo: 'Inventario',
              subtitulo: 'Control de insumos y stock mínimo',
              onTap: () => Get.toNamed(AppRoutes.inventario),
            ),
            if (dev) ...[
              const SizedBox(height: 16),
              _MoreOptionCard(
                icon: Icons.point_of_sale_outlined,
                titulo: 'Caja',
                subtitulo: 'Apertura, cierre y registro de gastos',
                onTap: () => _abrirConPin(context, AppRoutes.caja),
              ),
              const SizedBox(height: 16),
              _MoreOptionCard(
                icon: Icons.account_balance_outlined,
                titulo: 'Tesorería',
                subtitulo: 'Capital del negocio y gastos administrativos',
                onTap: () => _abrirConPin(context, AppRoutes.tesoreria),
              ),
            ],
            const SizedBox(height: 32),
            _DividerLabel(label: 'Sistema'),
            const SizedBox(height: 10),
            _MoreOptionCard(
              icon: Icons.settings_outlined,
              titulo: 'Configuración',
              subtitulo: 'Preferencias de la aplicación',
              onTap: () => Get.toNamed(AppRoutes.configuracion),
              colorIcono: AppColors.cafeMedio,
            ),
          ],
        );
      }),
    );
  }
}

class _DividerLabel extends StatelessWidget {
  final String label;
  const _DividerLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
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

class _MoreOptionCard extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;
  final Color? colorIcono;

  const _MoreOptionCard({
    required this.icon,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
    this.colorIcono,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = colorIcono;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.cafeOscuro.withAlpha(20),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: iconColor == null
                        ? LinearGradient(
                            colors: [AppColors.verdeOlivo, AppColors.verdeOscuro],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: iconColor?.withAlpha(20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor ?? Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        titulo,
                        style: GoogleFonts.cormorantGaramond(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cafeOscuro,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: GoogleFonts.nunito(
                          fontSize: 13,
                          color: AppColors.cafeMedio,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (iconColor ?? AppColors.verdeOlivo).withAlpha(15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: iconColor ?? AppColors.verdeOlivo,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
