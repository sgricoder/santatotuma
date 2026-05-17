import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../data/models/product_model.dart';
import '../../controllers/cart_controller.dart';
import '../../controllers/orders_controller.dart';
import '../../widgets/product_card.dart';

class OrdersScreen extends GetView<OrdersController> {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();

    return Scaffold(
      backgroundColor: AppColors.fondo,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(66),
        child: const _PremiumHeader(),
      ),
      body: Column(
        children: [
          _CategoriaFiltros(controller: controller),
          Expanded(
            child: Obx(() {
              if (controller.cargando.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.filtrados.isEmpty) {
                return const _EstadoVacio();
              }
              return GridView.builder(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 0.74,
                ),
                itemCount: controller.filtrados.length,
                itemBuilder: (_, i) =>
                    ProductCard(producto: controller.filtrados[i]),
              );
            }),
          ),
          Obx(() {
            if (cart.estaVacio) return const SizedBox.shrink();
            return _BarraCarrito(cart: cart);
          }),
        ],
      ),
    );
  }
}

// ── Header premium ─────────────────────────────────────────────────────────

class _PremiumHeader extends StatelessWidget {
  const _PremiumHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.verdeProfundo, AppColors.verdeMuyOscuro],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'Santa Totuma',
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: AppColors.crema,
                        letterSpacing: 0.4,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '¿Qué lleva hoy?',
                      style: GoogleFonts.nunito(
                        fontSize: 12,
                        color: AppColors.crema.withAlpha(155),
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.dorado.withAlpha(80),
                    width: 1,
                  ),
                ),
                child: Icon(
                  Icons.lunch_dining_outlined,
                  size: 20,
                  color: AppColors.doradoClaro.withAlpha(200),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Filtros de categoría ───────────────────────────────────────────────────

class _CategoriaFiltros extends StatelessWidget {
  final OrdersController controller;
  const _CategoriaFiltros({required this.controller});

  static IconData _iconoCategoria(CategoriaProducto cat) => switch (cat) {
        CategoriaProducto.totumas => Icons.lunch_dining_outlined,
        CategoriaProducto.entradas => Icons.tapas_outlined,
        CategoriaProducto.bebidas => Icons.local_drink_outlined,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(12),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Obx(
          () => Row(
            children: [
              _Chip(
                label: 'Todos',
                icono: Icons.grid_view_rounded,
                activo: controller.categoriaActiva.value == null,
                onTap: () => controller.seleccionarCategoria(null),
              ),
              ...CategoriaProducto.values.map(
                (cat) => Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: _Chip(
                    label: cat.etiqueta,
                    icono: _iconoCategoria(cat),
                    activo: controller.categoriaActiva.value == cat,
                    onTap: () => controller.seleccionarCategoria(cat),
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

class _Chip extends StatelessWidget {
  final String label;
  final bool activo;
  final VoidCallback onTap;
  final IconData? icono;
  const _Chip({
    required this.label,
    required this.activo,
    required this.onTap,
    this.icono,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: activo ? AppColors.verdeOlivo : AppColors.fondo,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: activo ? AppColors.verdeOlivo : AppColors.cremaOscura,
            width: activo ? 0 : 1.5,
          ),
          boxShadow: activo
              ? [
                  BoxShadow(
                    color: AppColors.verdeOlivo.withAlpha(70),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icono != null) ...[
              Icon(
                icono,
                size: 15,
                color: activo ? AppColors.crema : AppColors.cafeMedio,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.nunito(
                fontSize: 13,
                fontWeight: activo ? FontWeight.w700 : FontWeight.w500,
                color: activo ? AppColors.crema : AppColors.cafeOscuro,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barra del carrito ──────────────────────────────────────────────────────

class _BarraCarrito extends StatelessWidget {
  final CartController cart;
  const _BarraCarrito({required this.cart});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.verdeProfundo, AppColors.verdeMuyOscuro],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withAlpha(22),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.verdeProfundo.withAlpha(110),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => Get.toNamed(AppRoutes.comanda),
            borderRadius: BorderRadius.circular(18),
            splashColor: Colors.white.withAlpha(28),
            highlightColor: Colors.white.withAlpha(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(22),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.shopping_bag_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Ver comanda',
                          style: GoogleFonts.nunito(
                            fontSize: 11,
                            color: Colors.white.withAlpha(165),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Obx(() => Text(
                              '${cart.cantidadTotal} ${cart.cantidadTotal == 1 ? 'item' : 'items'}',
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            )),
                      ],
                    ),
                  ),
                  Obx(() => Text(
                        CurrencyFormatter.format(cart.total),
                        style: GoogleFonts.nunito(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.doradoClaro,
                        ),
                      )),
                  const SizedBox(width: 10),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Estado vacío ───────────────────────────────────────────────────────────

class _EstadoVacio extends StatelessWidget {
  const _EstadoVacio();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.search_off_rounded,
            size: 64,
            color: AppColors.cremaOscura,
          ),
          const SizedBox(height: 12),
          Text(
            'Sin productos',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.cafeMedio,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'No hay productos en esta categoría',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.cafeMedio,
            ),
          ),
        ],
      ),
    );
  }
}
