import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../widgets/premium_app_bar.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/cash_register_model.dart';
import '../../controllers/cash_controller.dart';

class CashScreen extends GetView<CashController> {
  const CashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: PremiumAppBar(
        titulo: 'Caja',
        subtitulo: DateFormat(
          'EEEE d \'de\' MMMM',
          'es_CO',
        ).format(DateTime.now()),
        icono: Icons.point_of_sale_outlined,
        mostrarBack: true,
      ),
      body: Obx(() {
        final caja = controller.cajaHoy.value;

        if (caja == null) return _SinCaja(ctrl: controller);

        if (caja.estado == EstadoCaja.abierta) {
          return _CajaAbierta(caja: caja, ctrl: controller);
        }

        return _CajaCerrada(caja: caja, ctrl: controller);
      }),
    );
  }
}

// ── Estado: sin caja abierta hoy ─────────────────────────────────────────

class _SinCaja extends StatelessWidget {
  final CashController ctrl;
  const _SinCaja({required this.ctrl});

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
                color: AppColors.verdeOlivo.withAlpha(15),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_open_outlined,
                size: 48,
                color: AppColors.verdeOlivo,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Caja sin abrir',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: AppColors.cafeOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Registra el dinero inicial\npara comenzar el día',
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
                onPressed: () => ctrl.abrirDialogoApertura(context),
                icon: const Icon(Icons.lock_open_outlined),
                label: const Text('Abrir caja'),
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

// ── Estado: caja abierta ──────────────────────────────────────────────────

class _CajaAbierta extends StatelessWidget {
  final CashRegisterModel caja;
  final CashController ctrl;

  const _CajaAbierta({required this.caja, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
          children: [
            // Resumen del día
            _SeccionVentas(ctrl: ctrl, caja: caja),
            const SizedBox(height: 16),

            // Gastos
            _SeccionGastos(caja: caja, ctrl: ctrl),
            const SizedBox(height: 16),

            // Saldo esperado
            _TarjetaSaldo(
              label: 'Saldo esperado en caja',
              valor: ctrl.saldoEsperado,
              color: AppColors.dorado,
              icono: Icons.account_balance_wallet_outlined,
            ),
          ],
        ),

        // Botón cerrar caja (flotante abajo)
        Positioned(
          bottom: 24,
          left: 16,
          right: 16,
          child: Obx(
            () => ElevatedButton.icon(
              onPressed: ctrl.procesando.value
                  ? null
                  : () => ctrl.abrirDialogoCierre(context),
              icon: ctrl.procesando.value
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.lock_outline),
              label: Text(
                ctrl.procesando.value ? 'Procesando...' : 'Cerrar caja',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.cafeOscuro,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SeccionVentas extends StatelessWidget {
  final CashController ctrl;
  final CashRegisterModel caja;

  const _SeccionVentas({required this.ctrl, required this.caja});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(label: 'Resumen del día', icono: Icons.today_outlined),
          const SizedBox(height: 14),
          _FilaResumen(
            label: 'Apertura',
            valor: CurrencyFormatter.format(caja.aperturaMonto),
            color: AppColors.cafeOscuro,
          ),
          const Divider(height: 16),
          Obx(
            () => Column(
              children: [
                _FilaResumen(
                  label: 'Ventas efectivo',
                  valor: CurrencyFormatter.format(ctrl.ventasEfectivo.value),
                  color: AppColors.dorado,
                ),
                const SizedBox(height: 6),
                _FilaResumen(
                  label: 'Ventas Bancolombia',
                  valor: CurrencyFormatter.format(ctrl.ventasBancolombia.value),
                  color: const Color(0xFFB8860B),
                ),
              ],
            ),
          ),
          const Divider(height: 16),
          _FilaResumen(
            label: 'Gastos',
            valor: '− ${CurrencyFormatter.format(caja.totalSalidas)}',
            color: AppColors.tiempoCritico,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => ctrl.abrirDialogoGasto(context),
                child: Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline,
                      size: 16,
                      color: AppColors.mesaPendiente,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Agregar gasto',
                      style: GoogleFonts.nunito(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.mesaPendiente,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SeccionGastos extends StatelessWidget {
  final CashRegisterModel caja;
  final CashController ctrl;

  const _SeccionGastos({required this.caja, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    if (caja.salidas.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDeco(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            label: 'Gastos (${caja.salidas.length})',
            icono: Icons.remove_circle_outline,
          ),
          const SizedBox(height: 10),
          ...caja.salidas.map((s) => _GastoTile(salida: s)),
        ],
      ),
    );
  }
}

class _GastoTile extends StatelessWidget {
  final CashOutModel salida;
  const _GastoTile({required this.salida});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.cremaOscura,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              salida.categoria.etiqueta,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.cafeOscuro,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              salida.concepto,
              style: GoogleFonts.nunito(
                fontSize: 13,
                color: AppColors.cafeOscuro,
              ),
            ),
          ),
          Text(
            CurrencyFormatter.format(salida.monto),
            style: GoogleFonts.nunito(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.tiempoCritico,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Estado: caja cerrada ──────────────────────────────────────────────────

class _CajaCerrada extends StatelessWidget {
  final CashRegisterModel caja;
  final CashController ctrl;
  const _CajaCerrada({required this.caja, required this.ctrl});

  @override
  Widget build(BuildContext context) {
    final diferencia = caja.diferencia;
    final positivo = diferencia >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC4661F), Color(0xFF783D19)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFC4661F).withAlpha(80),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(20),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.dorado.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.lock_outline,
                  color: AppColors.doradoClaro,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Caja cerrada',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.crema,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      DateFormat(
                        'EEEE d \'de\' MMMM',
                        'es_CO',
                      ).format(caja.fecha),
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.crema.withAlpha(160),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Detalle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardDeco(),
          child: Column(
            children: [
              _FilaResumen(
                label: 'Apertura',
                valor: CurrencyFormatter.format(caja.aperturaMonto),
                color: AppColors.cafeOscuro,
              ),
              const Divider(height: 16),
              _FilaResumen(
                label: 'Gastos',
                valor: '− ${CurrencyFormatter.format(caja.totalSalidas)}',
                color: AppColors.tiempoCritico,
              ),
              const Divider(height: 16),
              _FilaResumen(
                label: 'Cierre real',
                valor: CurrencyFormatter.format(caja.cierreMonto ?? 0),
                color: AppColors.cafeOscuro,
                bold: true,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Diferencia
        _TarjetaSaldo(
          label: positivo ? 'Sobrante de caja' : 'Faltante de caja',
          valor: diferencia.abs(),
          color: positivo ? AppColors.dorado : AppColors.tiempoCritico,
          icono: positivo ? Icons.trending_up : Icons.trending_down,
          prefijo: positivo ? '+' : '−',
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () =>
              ctrl.abrirDialogoApertura(context, esReapertura: true),
          icon: const Icon(Icons.lock_open_outlined),
          label: const Text('Reabrir caja'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Widgets compartidos ───────────────────────────────────────────────────

class _TarjetaSaldo extends StatelessWidget {
  final String label;
  final double valor;
  final Color color;
  final IconData icono;
  final String prefijo;

  const _TarjetaSaldo({
    required this.label,
    required this.valor,
    required this.color,
    required this.icono,
    this.prefijo = '',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 15,
                color: AppColors.cafeOscuro,
              ),
            ),
          ),
          Text(
            '$prefijo${CurrencyFormatter.format(valor)}',
            style: GoogleFonts.nunito(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilaResumen extends StatelessWidget {
  final String label;
  final String valor;
  final Color color;
  final bool bold;

  const _FilaResumen({
    required this.label,
    required this.valor,
    required this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 14,
            color: AppColors.cafeOscuro,
            fontWeight: FontWeight.w400,
          ),
        ),
        Text(
          valor,
          style: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

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

BoxDecoration _cardDeco() => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(16),
  boxShadow: [
    BoxShadow(
      color: AppColors.cafeOscuro.withAlpha(18),
      blurRadius: 8,
      offset: const Offset(0, 3),
    ),
  ],
);
