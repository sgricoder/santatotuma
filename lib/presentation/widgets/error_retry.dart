import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';

class ErrorRetry extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const ErrorRetry({
    super.key,
    this.mensaje = 'No se pudo cargar la información',
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.tiempoCritico.withAlpha(18),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                size: 40,
                color: AppColors.tiempoCritico,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Sin conexión',
              style: GoogleFonts.cormorantGaramond(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.cafeOscuro,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mensaje,
              style: GoogleFonts.nunito(
                fontSize: 14,
                color: AppColors.cafeMedio,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.verdeOlivo,
                side: const BorderSide(color: AppColors.verdeOlivo, width: 1.5),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
