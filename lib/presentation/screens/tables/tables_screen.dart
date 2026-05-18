import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/table_model.dart';
import '../../controllers/tables_controller.dart';
import '../../widgets/premium_app_bar.dart';

class TablesScreen extends GetView<TablesController> {
  const TablesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: PremiumAppBar(
        titulo: 'Mesas',
        subtitulo: 'Estado del salón',
        trailing: Obx(() {
          final ocupadas = controller.mesas
              .where((m) => m.estado != EstadoMesa.libre)
              .length;
          if (ocupadas == 0) return const SizedBox(width: 36, height: 36);
          return HeaderBadge(texto: '$ocupadas ocupadas');
        }),
      ),
      body: Obx(() {
        if (controller.cargando.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.mesas.isEmpty) {
          return const _Inicializando();
        }
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.75,
          ),
          itemCount: controller.mesas.length,
          itemBuilder: (_, i) => _MesaCard(
            mesa: controller.mesas[i],
            ctrl: controller,
          ),
        );
      }),
    );
  }
}

// ── Tarjeta de mesa ───────────────────────────────────────────────────────

class _MesaCard extends StatelessWidget {
  final TableModel mesa;
  final TablesController ctrl;

  const _MesaCard({required this.mesa, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final color = ctrl.colorEstado(mesa.estado);
    final esLibre = mesa.estado == EstadoMesa.libre;
    final esPendiente = mesa.estado == EstadoMesa.pendienteCobro;

    return GestureDetector(
      onTap: () => ctrl.abrirDetalle(context, mesa),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: esLibre ? AppColors.verdeClaro : color,
          borderRadius: BorderRadius.circular(18),
          border: esLibre
              ? Border.all(color: AppColors.verde.withAlpha(80), width: 1.5)
              : null,
          boxShadow: [
            BoxShadow(
              color: esLibre
                  ? AppColors.verde.withAlpha(20)
                  : color.withAlpha(70),
              blurRadius: esLibre ? 6 : 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Alerta parpadeo para pendiente cobro
            if (esPendiente)
              Positioned.fill(
                child: _PulseIndicator(color: color),
              ),
            // Contenido
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Número
                  Text(
                    '${mesa.numero}',
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: esLibre ? AppColors.verdeProfundo : Colors.white,
                      height: 1,
                    ),
                  ),
                  // Nombre cliente
                  if (!esLibre && mesa.nombreCliente.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        mesa.nombreCliente,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.2,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                  const SizedBox(height: 2),
                  // Estado
                  Text(
                    mesa.estado.etiqueta,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: esLibre
                          ? AppColors.verdeOscuro
                          : Colors.white.withAlpha(200),
                      letterSpacing: 0.3,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  // Resumen de lo pedido
                  if (!esLibre)
                    Obx(() {
                      final resumen = ctrl.resumenItemsMesa(mesa.numero);
                      if (resumen.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 3),
                        child: Text(
                          resumen,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withAlpha(210),
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }),
                  // Total (calculado desde órdenes activas, siempre fresco)
                  Obx(() {
                    final total = ctrl.totalActivoMesa(mesa.numero);
                    if (total <= 0) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          CurrencyFormatter.format(total),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Indicador de pulso para mesas pendientes de cobro ────────────────────

class _PulseIndicator extends StatefulWidget {
  final Color color;
  const _PulseIndicator({required this.color});

  @override
  State<_PulseIndicator> createState() => _PulseIndicatorState();
}

class _PulseIndicatorState extends State<_PulseIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.0, end: 0.15).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

// ── Estado mientras inicializa ────────────────────────────────────────────

class _Inicializando extends StatelessWidget {
  const _Inicializando();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Inicializando mesas...'),
        ],
      ),
    );
  }
}
