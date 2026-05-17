import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/tesoreria_model.dart';
import '../../controllers/tesoreria_controller.dart';
import '../../widgets/premium_app_bar.dart';

class TesoreriaScreen extends GetView<TesoreriaController> {
  const TesoreriaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: PremiumAppBar(
        titulo: 'Tesorería',
        subtitulo: 'Capital del negocio',
        icono: Icons.account_balance_outlined,
        mostrarBack: true,
      ),
      body: Obx(() {
        final tes = controller.tesoreria.value;
        if (tes == null) return _SinTesoreria(ctrl: controller);
        return _TesoreriaActiva(tes: tes, ctrl: controller);
      }),
    );
  }
}

// ── Estado: sin configurar ────────────────────────────────────────────────

class _SinTesoreria extends StatelessWidget {
  final TesoreriaController ctrl;
  const _SinTesoreria({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.dorado.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.account_balance_outlined,
                size: 48,
                color: AppColors.dorado,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sin configurar',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.cafeOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra el capital actual\npara comenzar a llevar el control',
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: AppColors.cafeMedio,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => ctrl.abrirDialogoInicio(context),
                icon: const Icon(Icons.settings_outlined),
                label: const Text('Configurar tesorería'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(54),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Estado: tesorería activa ──────────────────────────────────────────────

class _TesoreriaActiva extends StatelessWidget {
  final TesoreriaModel tes;
  final TesoreriaController ctrl;

  const _TesoreriaActiva({required this.tes, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderSaldo(saldo: tes.saldo),
        const SizedBox(height: 16),

        // Stats — reactivos a la subcollección
        Obx(() => Row(
              children: [
                Expanded(
                  child: _StatCard(
                    label: 'Total ingresos',
                    valor: ctrl.totalIngresos,
                    color: AppColors.verdeOlivo,
                    icono: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Total gastos',
                    valor: ctrl.totalGastos,
                    color: AppColors.tiempoCritico,
                    icono: Icons.trending_down_rounded,
                  ),
                ),
              ],
            )),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _BotonAccion(
                label: 'Transferir\nde Caja',
                icono: Icons.swap_horiz_rounded,
                color: AppColors.verdeOlivo,
                onTap: () => ctrl.abrirDialogoTransferencia(context),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _BotonAccion(
                label: 'Bancolombia',
                icono: Icons.account_balance_wallet_outlined,
                color: AppColors.azulTransferencia,
                onTap: () => ctrl.abrirDialogoConsignacion(context),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BotonAccion(
          label: 'Registrar Gasto',
          icono: Icons.remove_circle_outline,
          color: AppColors.tiempoCritico,
          onTap: () => ctrl.abrirDialogoGasto(context),
        ),
        const SizedBox(height: 20),

        // Lista de movimientos desde subcollección
        Obx(() {
          final movs = ctrl.movimientos;
          if (movs.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitle(
                label: 'Movimientos (${movs.length})',
                icono: Icons.history_rounded,
              ),
              const SizedBox(height: 10),
              ...movs.map((m) => _MovimientoTile(mov: m)),
            ],
          );
        }),
      ],
    );
  }
}

// ── Header con saldo ──────────────────────────────────────────────────────

class _HeaderSaldo extends StatelessWidget {
  final double saldo;
  const _HeaderSaldo({required this.saldo});

  @override
  Widget build(BuildContext context) {
    final positivo = saldo >= 0;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.verdeProfundo, AppColors.verdeMuyOscuro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.verdeProfundo.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.dorado.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.account_balance_outlined,
                  color: AppColors.crema,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capital total',
                    style: GoogleFonts.nunito(
                      fontSize: 12,
                      color: AppColors.crema.withAlpha(160),
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    positivo ? 'Saldo disponible' : 'Saldo negativo',
                    style: GoogleFonts.nunito(
                      fontSize: 11,
                      color: AppColors.crema.withAlpha(120),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '${positivo ? '' : '−'}${CurrencyFormatter.format(saldo.abs())}',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              color: AppColors.crema,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stats ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final double valor;
  final Color color;
  final IconData icono;

  const _StatCard({
    required this.label,
    required this.valor,
    required this.color,
    required this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(16),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, size: 15, color: color),
              const SizedBox(width: 5),
              Text(
                label.toUpperCase(),
                style: GoogleFonts.nunito(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cafeOscuro,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            CurrencyFormatter.format(valor),
            style: GoogleFonts.nunito(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Botones de acción ─────────────────────────────────────────────────────

class _BotonAccion extends StatelessWidget {
  final String label;
  final IconData icono;
  final Color color;
  final VoidCallback onTap;

  const _BotonAccion({
    required this.label,
    required this.icono,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(18),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Row(
            children: [
              Icon(icono, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tile de movimiento ────────────────────────────────────────────────────

class _MovimientoTile extends StatelessWidget {
  final MovimientoTes mov;
  const _MovimientoTile({required this.mov});

  Color get _color => switch (mov.tipo) {
        TipoMovimiento.ingresoCaja => AppColors.verdeOlivo,
        TipoMovimiento.consignacionBancolombia => AppColors.azulTransferencia,
        TipoMovimiento.gasto => AppColors.tiempoCritico,
        TipoMovimiento.ajuste => AppColors.dorado,
      };

  IconData get _icono => switch (mov.tipo) {
        TipoMovimiento.ingresoCaja => Icons.move_up_rounded,
        TipoMovimiento.consignacionBancolombia =>
          Icons.account_balance_wallet_outlined,
        TipoMovimiento.gasto => Icons.remove_circle_outline,
        TipoMovimiento.ajuste => Icons.tune_rounded,
      };

  bool get _esEgreso => mov.tipo == TipoMovimiento.gasto;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.cafeOscuro.withAlpha(14),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: _color.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(_icono, size: 18, color: _color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mov.concepto,
                    style: GoogleFonts.nunito(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.cafeOscuro,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        DateFormat('d MMM, h:mm a', 'es_CO').format(mov.hora),
                        style: GoogleFonts.nunito(
                          fontSize: 11,
                          color: AppColors.cafeMedio,
                        ),
                      ),
                      if (mov.categoria != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.cremaOscura,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            mov.categoria!.etiqueta,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: AppColors.cafeOscuro,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '${_esEgreso ? '−' : '+'}${CurrencyFormatter.format(mov.monto)}',
              style: GoogleFonts.nunito(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: _color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Section title ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  final IconData icono;

  const _SectionTitle({required this.label, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, size: 15, color: AppColors.dorado),
        const SizedBox(width: 6),
        Text(
          label.toUpperCase(),
          style: GoogleFonts.nunito(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.cafeOscuro,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
