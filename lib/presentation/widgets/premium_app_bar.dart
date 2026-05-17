import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String titulo;
  final String? subtitulo;
  final IconData? icono;
  final Widget? trailing;
  final bool mostrarBack;

  const PremiumAppBar({
    super.key,
    required this.titulo,
    this.subtitulo,
    this.icono,
    this.trailing,
    this.mostrarBack = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(66);

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
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (mostrarBack) ...[
                GestureDetector(
                  onTap: Get.back,
                  child: Container(
                    width: 36,
                    height: 36,
                    margin: const EdgeInsets.only(right: 10, bottom: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withAlpha(40),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      titulo,
                      style: GoogleFonts.cormorantGaramond(
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: AppColors.crema,
                        letterSpacing: 0.4,
                        height: 1,
                      ),
                    ),
                    if (subtitulo != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitulo!,
                        style: GoogleFonts.nunito(
                          fontSize: 12,
                          color: AppColors.crema.withAlpha(155),
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (icono != null)
                _IconoDecorativo(icono: icono!)
              else
                const _LogoDecorativo(),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconoDecorativo extends StatelessWidget {
  final IconData icono;
  const _IconoDecorativo({required this.icono});

  @override
  Widget build(BuildContext context) {
    return Container(
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
        icono,
        size: 20,
        color: AppColors.doradoClaro.withAlpha(200),
      ),
    );
  }
}

class _LogoDecorativo extends StatelessWidget {
  const _LogoDecorativo();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.dorado.withAlpha(100), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset('assets/logoredondo.png', fit: BoxFit.cover),
      ),
    );
  }
}

/// Pill badge dorado para mostrar en el trailing del header.
class HeaderBadge extends StatelessWidget {
  final String texto;
  final Color? color;
  const HeaderBadge({super.key, required this.texto, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.dorado;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withAlpha(30),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withAlpha(100), width: 1),
      ),
      child: Text(
        texto,
        style: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c == AppColors.dorado ? AppColors.doradoClaro : c,
        ),
      ),
    );
  }
}
