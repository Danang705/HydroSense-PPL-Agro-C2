import 'dart:async';
import 'package:flutter/material.dart';
import 'hydro_design.dart';

class HydroNotification {
  /// Menampilkan dialog sukses yang teranimasi (Scale Transition).
  ///
  /// Memiliki tombol "LANJUT" dan dapat otomatis tertutup (auto-dismiss) setelah 1.5 detik.
  static Future<void> showSuccessDialog({
    required BuildContext context,
    required String title,
    required String message,
    String buttonText = 'LANJUT',
    bool autoDismiss = true,
    VoidCallback? onConfirm,
  }) async {
    Timer? dismissTimer;

    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'SuccessDialog',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final double curveValue = Curves.easeInOutBack.transform(anim1.value);

        // Pasang timer penutupan otomatis saat dialog pertama kali dirender
        if (autoDismiss && dismissTimer == null) {
          dismissTimer = Timer(const Duration(milliseconds: 1800), () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
              if (onConfirm != null) onConfirm();
            }
          });
        }

        return Transform.scale(
          scale: curveValue,
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
              contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon badge sukses yang estetik
                  Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: HydroDesign.lightGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      color: HydroDesign.primaryGreen,
                      size: 44,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: HydroDesign.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        dismissTimer?.cancel();
                        Navigator.pop(context);
                        if (onConfirm != null) onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HydroDesign.primaryGreen,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        buttonText,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Menampilkan dialog konfirmasi dengan pilihan Ya/Tidak untuk tindakan penting.
  static Future<bool> showConfirmDialog({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'YA, LANJUTKAN',
    String cancelText = 'BATAL',
    bool isDestructive = false,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'ConfirmDialog',
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, anim1, anim2) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (context, anim1, anim2, child) {
        final double curveValue = Curves.easeOutQuad.transform(anim1.value);

        return Transform.scale(
          scale: 0.85 + (curveValue * 0.15),
          child: Opacity(
            opacity: anim1.value,
            child: AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
              ),
              backgroundColor: Colors.white,
              elevation: 10,
              contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon badge sesuai tingkat keparahan/urgensi
                  Container(
                    width: 68,
                    height: 68,
                    decoration: BoxDecoration(
                      color: isDestructive ? HydroDesign.dangerRed.withValues(alpha: 0.1) : HydroDesign.lightGreenBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isDestructive ? Icons.warning_amber_rounded : Icons.help_outline_rounded,
                      color: isDestructive ? HydroDesign.dangerRed : HydroDesign.primaryGreen,
                      size: 38,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: HydroDesign.darkText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            cancelText,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDestructive ? HydroDesign.dangerRed : HydroDesign.primaryGreen,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: Text(
                            confirmText,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return result ?? false;
  }

  /// Menampilkan SnackBar melayang (floating) dengan visual modern dan bayangan halus.
  static void showFloatingToast({
    required BuildContext context,
    required String message,
    required bool isSuccess,
    IconData? icon,
  }) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    // Hapus SnackBar yang sedang aktif agar umpan balik cepat diterima
    scaffoldMessenger.removeCurrentSnackBar();

    scaffoldMessenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(
              color: isSuccess 
                  ? HydroDesign.primaryGreen.withValues(alpha: 0.15) 
                  : HydroDesign.dangerRed.withValues(alpha: 0.15),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: isSuccess ? HydroDesign.lightGreenBg : HydroDesign.dangerRed.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon ?? (isSuccess ? Icons.check_rounded : Icons.error_outline_rounded),
                  color: isSuccess ? HydroDesign.primaryGreen : HydroDesign.dangerRed,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: HydroDesign.darkText,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
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
