import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/order_model.dart';
import '../controllers/cart_controller.dart';

class CartItemWidget extends StatelessWidget {
  final OrderItemModel item;
  const CartItemWidget({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();
    final subtotal = item.precioUnitario * item.cantidad;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.cafeOscuro.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: AppColors.verdeOlivo.withAlpha(120)),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 14, 16, 14),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Nombre + precio unitario
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.nombre,
                              style: GoogleFonts.nunito(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.cafeOscuro,
                                height: 1.3,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${CurrencyFormatter.format(item.precioUnitario)} c/u',
                              style: GoogleFonts.nunito(
                                fontSize: 12,
                                color: AppColors.cafeMedio,
                              ),
                            ),
                            if (item.salsas.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 4,
                                runSpacing: 4,
                                children: item.salsas
                                    .map(
                                      (s) => Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.verdeOlivo
                                              .withAlpha(18),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                          border: Border.all(
                                            color: AppColors.verdeOlivo
                                                .withAlpha(60),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          s,
                                          style: GoogleFonts.nunito(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.verdeOscuro,
                                          ),
                                        ),
                                      ),
                                    )
                                    .toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Subtotal + controles
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            CurrencyFormatter.format(subtotal),
                            style: GoogleFonts.nunito(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.dorado,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _CantidadControl(
                                cantidad: item.cantidad,
                                onMenos: () =>
                                    cart.decrementar(item.productoId),
                                onMas: () => cart.incrementar(item.productoId),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () => cart.eliminar(item.productoId),
                                child: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withAlpha(18),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.error,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
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

class _CantidadControl extends StatelessWidget {
  final int cantidad;
  final VoidCallback onMenos;
  final VoidCallback onMas;

  const _CantidadControl({
    required this.cantidad,
    required this.onMenos,
    required this.onMas,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _Btn(icono: Icons.remove, onTap: onMenos),
        SizedBox(
          width: 32,
          child: Center(
            child: Text(
              '$cantidad',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.cafeOscuro,
              ),
            ),
          ),
        ),
        _Btn(icono: Icons.add, onTap: onMas),
      ],
    );
  }
}

class _Btn extends StatelessWidget {
  final IconData icono;
  final VoidCallback onTap;
  const _Btn({required this.icono, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.verdeOlivo,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icono, size: 18, color: Colors.white),
      ),
    );
  }
}
