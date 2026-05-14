import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../controllers/admin_controller.dart';

class PinSheet extends StatefulWidget {
  const PinSheet({super.key});

  static Future<bool?> mostrar(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const PinSheet(),
    );
  }

  @override
  State<PinSheet> createState() => _PinSheetState();
}

class _PinSheetState extends State<PinSheet>
    with SingleTickerProviderStateMixin {
  final AdminController _admin = Get.find<AdminController>();
  final List<String> _digitos = [];
  bool _error = false;

  late final AnimationController _shakeCtrl;
  late final Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    super.dispose();
  }

  void _presionar(String digito) {
    if (_digitos.length >= 4 || _admin.estaBloqueado) return;
    HapticFeedback.selectionClick();
    setState(() {
      _error = false;
      _digitos.add(digito);
    });
    if (_digitos.length == 4) _verificar();
  }

  void _borrar() {
    if (_digitos.isEmpty) return;
    HapticFeedback.lightImpact();
    setState(() => _digitos.removeLast());
  }

  Future<void> _verificar() async {
    final pin = _digitos.join();
    final ok = await _admin.verificarPin(pin);

    if (!mounted) return;

    if (ok) {
      HapticFeedback.mediumImpact();
      Get.back(result: true);
    } else {
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _error = true;
        _digitos.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFC4661F), Color(0xFF783D19)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        top: 12,
        left: 24,
        right: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(50),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),

          // Ícono
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(15),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.dorado.withAlpha(100),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: AppColors.doradoClaro,
              size: 26,
            ),
          ),
          const SizedBox(height: 16),

          // Título
          Text(
            'Acceso restringido',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: AppColors.crema,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ingresa tu PIN de administrador',
            style: GoogleFonts.nunito(
              fontSize: 13,
              color: AppColors.crema.withAlpha(160),
            ),
          ),
          const SizedBox(height: 28),

          // Indicadores de dígitos con shake
          Obx(() {
            if (_admin.estaBloqueado) {
              return _BloqueadoBanner(admin: _admin);
            }

            return AnimatedBuilder(
              animation: _shakeAnim,
              builder: (_, child) {
                final offset =
                    _error ? (8 * (0.5 - (_shakeAnim.value % 1)).abs()) : 0.0;
                return Transform.translate(
                  offset: Offset(offset * 6 - 3, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final lleno = i < _digitos.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: lleno ? 18 : 16,
                    height: lleno ? 18 : 16,
                    decoration: BoxDecoration(
                      color: _error
                          ? AppColors.tiempoCritico
                          : lleno
                              ? AppColors.doradoClaro
                              : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _error
                            ? AppColors.tiempoCritico
                            : lleno
                                ? AppColors.doradoClaro
                                : Colors.white.withAlpha(80),
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
            );
          }),
          const SizedBox(height: 32),

          // Teclado numérico
          Obx(() {
            final bloqueado = _admin.estaBloqueado || _admin.verificando.value;
            return _Teclado(
              onDigito: bloqueado ? null : _presionar,
              onBorrar: bloqueado ? null : _borrar,
            );
          }),
        ],
      ),
    );
  }
}

// ── Banner de bloqueo temporal ─────────────────────────────────────────────

class _BloqueadoBanner extends StatefulWidget {
  final AdminController admin;
  const _BloqueadoBanner({required this.admin});

  @override
  State<_BloqueadoBanner> createState() => _BloqueadoBannerState();
}

class _BloqueadoBannerState extends State<_BloqueadoBanner> {
  late final Stream<int> _ticks;

  @override
  void initState() {
    super.initState();
    _ticks = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _ticks,
      builder: (_, __) {
        final seg = widget.admin.segundosRestantes;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.tiempoCritico.withAlpha(30),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.tiempoCritico.withAlpha(80), width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.timer_outlined,
                  color: AppColors.tiempoCritico, size: 16),
              const SizedBox(width: 8),
              Text(
                'Bloqueado — espera ${seg}s',
                style: GoogleFonts.nunito(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.tiempoCritico,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Teclado numérico ───────────────────────────────────────────────────────

class _Teclado extends StatelessWidget {
  final void Function(String)? onDigito;
  final VoidCallback? onBorrar;

  const _Teclado({this.onDigito, this.onBorrar});

  @override
  Widget build(BuildContext context) {
    const numeros = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
    ];

    return Column(
      children: [
        for (final fila in numeros) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: fila
                .map((n) => _Tecla(
                      label: n,
                      onTap: onDigito != null ? () => onDigito!(n) : null,
                    ))
                .toList(),
          ),
          const SizedBox(height: 12),
        ],
        // Fila final: vacío, 0, borrar
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 80, height: 64),
            _Tecla(
              label: '0',
              onTap: onDigito != null ? () => onDigito!('0') : null,
            ),
            _TeclaBorrar(onTap: onBorrar),
          ],
        ),
      ],
    );
  }
}

class _Tecla extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _Tecla({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(onTap != null ? 18 : 8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withAlpha(onTap != null ? 35 : 15),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.nunito(
            fontSize: 28,
            fontWeight: FontWeight.w600,
            color: onTap != null
                ? Colors.white
                : Colors.white.withAlpha(80),
          ),
        ),
      ),
    );
  }
}

class _TeclaBorrar extends StatelessWidget {
  final VoidCallback? onTap;
  const _TeclaBorrar({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 64,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(onTap != null ? 18 : 8),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: Colors.white.withAlpha(onTap != null ? 35 : 15),
            width: 1,
          ),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.backspace_outlined,
          color: onTap != null
              ? AppColors.crema
              : AppColors.crema.withAlpha(80),
          size: 24,
        ),
      ),
    );
  }
}
