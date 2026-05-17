import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/constants/app_salsas.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/currency_formatter.dart';
import '../../data/models/product_model.dart';
import '../controllers/cart_controller.dart';
import '../controllers/configuracion_controller.dart';

class ProductCard extends StatefulWidget {
  final ProductModel producto;
  const ProductCard({super.key, required this.producto});

  @override
  State<ProductCard> createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _escala;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _escala = Tween<double>(
      begin: 1.0,
      end: 0.92,
    ).animate(CurvedAnimation(parent: _anim, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _anim.forward();
    await _anim.reverse();
    if (!mounted) return;

    final cart = Get.find<CartController>();

    if (widget.producto.categoria == CategoriaProducto.totumas) {
      final salsas = await showModalBottomSheet<List<String>>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _SelectorSalsas(producto: widget.producto),
      );
      if (!mounted) return;
      if (salsas != null) {
        HapticFeedback.lightImpact();
        cart.agregar(widget.producto, salsas: salsas);
      }
    } else {
      HapticFeedback.lightImpact();
      cart.agregar(widget.producto);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Get.find<CartController>();

    return AnimatedBuilder(
      animation: _escala,
      builder: (_, child) =>
          Transform.scale(scale: _escala.value, child: child),
      child: GestureDetector(
        onTap: _onTap,
        child: Obx(() {
          final count = cart.items
              .where((e) => e.productoId == widget.producto.id)
              .fold(0, (sum, e) => sum + e.cantidad);

          return AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: count > 0
                      ? AppColors.dorado.withAlpha(100)
                      : AppColors.cafeOscuro.withAlpha(40),
                  blurRadius: count > 0 ? 24 : 14,
                  offset: const Offset(0, 7),
                  spreadRadius: count > 0 ? 1 : 0,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ── Imagen full-bleed ───────────────────────────────
                  _Imagen(producto: widget.producto),

                  // ── Gradiente inferior ──────────────────────────────
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.28, 0.58, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withAlpha(165),
                            Colors.black.withAlpha(230),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Badge cantidad (arriba derecha) ─────────────────
                  if (count > 0)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        constraints: const BoxConstraints(minWidth: 30),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.dorado,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.dorado.withAlpha(140),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '$count',
                          style: GoogleFonts.nunito(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),

                  // ── Nombre + precio + botón ─────────────────────────
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(13, 0, 13, 13),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.producto.nombre,
                                  style: GoogleFonts.nunito(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                    height: 1.2,
                                    shadows: const [
                                      Shadow(
                                        color: AppColors.overlayClaro,
                                        blurRadius: 6,
                                      ),
                                    ],
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  CurrencyFormatter.format(
                                    widget.producto.precio,
                                  ),
                                  style: GoogleFonts.nunito(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.cremaOscura,
                                    shadows: const [
                                      Shadow(
                                        color: AppColors.overlayMedio,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          _BotonAdd(count: count),
                        ],
                      ),
                    ),
                  ),

                  // ── Borde dorado cuando tiene items ─────────────────
                  if (count > 0)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: AppColors.dorado,
                              width: 2.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Botón añadir ───────────────────────────────────────────────────────────

class _BotonAdd extends StatelessWidget {
  final int count;
  const _BotonAdd({required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: count > 0
            ? AppColors.dorado.withAlpha(40)
            : Colors.white.withAlpha(235),
        borderRadius: BorderRadius.circular(13),
        border: count > 0
            ? Border.all(color: AppColors.dorado, width: 1.5)
            : null,
      ),
      child: Icon(
        Icons.add_rounded,
        size: 22,
        color: count > 0 ? AppColors.dorado : AppColors.cafeOscuro,
      ),
    );
  }
}

// ── Imagen ─────────────────────────────────────────────────────────────────

class _Imagen extends StatelessWidget {
  final ProductModel producto;
  const _Imagen({required this.producto});

  static const Map<String, String> _assets = {
    'candilejas': 'assets/totuma.jpg',
    'castanuelas': 'assets/totuma.jpg',
    'makondo': 'assets/totuma.jpg',
    'palitos_queso_x5': 'assets/palitos.jpg',
    'palo_queso': 'assets/palitos.jpg',
    'chips_platano': 'assets/chps.jpg',
    'aborrajado': 'assets/platano.jpg',
    'coca_cola_1500': 'assets/cocacola1.png',
    'coca_cola_400': 'assets/cocacola4.png',
    'postobon_1500': 'assets/posto1.png',
    'postobon_400': 'assets/postobon4.png',
    'agua_cristal': 'assets/aguaCristal.png',
  };

  @override
  Widget build(BuildContext context) {
    final assetPath = _assets[producto.id];

    if (assetPath != null) {
      return Image.asset(
        assetPath,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            _Placeholder(categoria: producto.categoria),
      );
    }

    if (producto.urlImagen.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: producto.urlImagen,
        fit: BoxFit.cover,
        placeholder: (_, __) => _Placeholder(categoria: producto.categoria),
        errorWidget: (_, __, ___) =>
            _Placeholder(categoria: producto.categoria),
      );
    }

    return _Placeholder(categoria: producto.categoria);
  }
}

class _Placeholder extends StatelessWidget {
  final CategoriaProducto categoria;
  const _Placeholder({required this.categoria});

  static IconData _icono(CategoriaProducto cat) => switch (cat) {
    CategoriaProducto.totumas => Icons.lunch_dining,
    CategoriaProducto.entradas => Icons.tapas,
    CategoriaProducto.bebidas => Icons.local_drink,
  };

  static List<Color> _gradiente(CategoriaProducto cat) => switch (cat) {
    CategoriaProducto.totumas => [AppColors.verdeOlivo, AppColors.verdeOscuro],
    CategoriaProducto.entradas => [AppColors.cafeClaro, AppColors.cafeOscuro],
    CategoriaProducto.bebidas => [AppColors.azulBebida, AppColors.azulBebidaOscuro],
  };

  @override
  Widget build(BuildContext context) {
    final grad = _gradiente(categoria);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: grad,
        ),
      ),
      child: Center(
        child: Icon(
          _icono(categoria),
          size: 56,
          color: Colors.white.withAlpha(180),
        ),
      ),
    );
  }
}

// ── Selector salsas ────────────────────────────────────────────────────────

class _SelectorSalsas extends StatefulWidget {
  final ProductModel producto;
  const _SelectorSalsas({required this.producto});

  @override
  State<_SelectorSalsas> createState() => _SelectorSalsasState();
}

class _SelectorSalsasState extends State<_SelectorSalsas> {
  final Set<String> _seleccionadas = {};

  void _toggle(String salsa) {
    setState(() {
      if (_seleccionadas.contains(salsa)) {
        _seleccionadas.remove(salsa);
      } else if (_seleccionadas.length < AppSalsas.maxPorTotuma) {
        _seleccionadas.add(salsa);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final salsasDisponibles =
        Get.find<ConfiguracionController>().salsas.toList();
    final lleno = _seleccionadas.length >= AppSalsas.maxPorTotuma;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.cremaOscura,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Elige las salsas',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.cafeOscuro,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                widget.producto.nombre,
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  color: AppColors.cafeMedio,
                ),
              ),
              const Spacer(),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: lleno
                      ? AppColors.dorado.withAlpha(20)
                      : AppColors.verdeOlivo.withAlpha(20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_seleccionadas.length}/${AppSalsas.maxPorTotuma}',
                  style: GoogleFonts.nunito(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: lleno ? AppColors.dorado : AppColors.verdeOlivo,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...salsasDisponibles.map((salsa) {
            final seleccionada = _seleccionadas.contains(salsa);
            final desactivada = lleno && !seleccionada;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                decoration: BoxDecoration(
                  color: seleccionada
                      ? AppColors.verdeOlivo.withAlpha(18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: seleccionada
                        ? AppColors.verdeOlivo
                        : AppColors.cremaOscura,
                    width: seleccionada ? 1.5 : 1,
                  ),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: desactivada ? null : () => _toggle(salsa),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 160),
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: seleccionada
                                  ? AppColors.verdeOlivo
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: seleccionada
                                    ? AppColors.verdeOlivo
                                    : desactivada
                                        ? AppColors.cremaOscura
                                        : AppColors.cafeMedio,
                                width: 1.5,
                              ),
                            ),
                            child: seleccionada
                                ? const Icon(Icons.check,
                                    size: 14, color: Colors.white)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              salsa,
                              style: GoogleFonts.nunito(
                                fontSize: 14,
                                fontWeight: seleccionada
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: desactivada
                                    ? AppColors.cafeMedio.withAlpha(100)
                                    : AppColors.cafeOscuro,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Get.back(result: _seleccionadas.toList()),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              _seleccionadas.isEmpty
                  ? 'Agregar sin salsas'
                  : 'Agregar con ${_seleccionadas.length} salsa${_seleccionadas.length > 1 ? 's' : ''}',
              style: GoogleFonts.nunito(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

