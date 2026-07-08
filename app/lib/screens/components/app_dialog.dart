import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum DialogType { success, error, info }

/// Modal de alta legibilidad para mostrar mensajes del sistema.
/// Resuelve PC-002: no se confunde con el fondo, letras grandes, cerrable.
class AppDialog extends StatelessWidget {
  final String title;
  final String message;
  final DialogType type;

  const AppDialog({
    super.key,
    required this.title,
    required this.message,
    this.type = DialogType.info,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    DialogType type = DialogType.info,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AppDialog(title: title, message: message, type: type),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color iconColor;
    IconData icon;
    switch (type) {
      case DialogType.success:
        iconColor = const Color(0xFF52B788);
        icon = Icons.check_circle_outline;
        break;
      case DialogType.error:
        iconColor = const Color(0xFFDC3545);
        icon = Icons.error_outline;
        break;
      case DialogType.info:
        iconColor = const Color(0xFF00B4D8);
        icon = Icons.info_outline;
        break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      elevation: 10,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icono
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: iconColor.withOpacity(0.12),
              ),
              child: Icon(icon, color: iconColor, size: 48),
            ),
            const SizedBox(height: 20),

            // Título
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 12),

            // Mensaje
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                height: 1.5,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 24),

            // Botón Cerrar
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: iconColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Cerrar',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
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
