// =============================================================================
// AppButton — Bottoni riusabili del design system ApprenderAI
// =============================================================================
//
// Tre varianti di bottone tramite metodi factory statici:
//   [AppButton.primary]   — gradiente indigo→purple, 50 px di altezza.
//                           Rimpiazza il pattern DecoratedBox+ElevatedButton
//                           usato in LoginScreen, SplashScreen, StartScreen.
//   [AppButton.secondary] — bordo cs.primary, fill trasparente.
//   [AppButton.text]      — nessun bordo/fill, testo cs.primary.
//
// Tutti rispettano il tema corrente (light/dark) tramite colorScheme.
// Passare onPressed: null disabilita automaticamente il bottone.
// =============================================================================

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import 'app_spacing.dart';

/// Collezione di factory per i bottoni standard dell'app.
///
/// Non istanziare direttamente: usa i metodi statici
/// [AppButton.primary], [AppButton.secondary] e [AppButton.text].
abstract final class AppButton {
  // ---------------------------------------------------------------------------
  // PRIMARY — gradiente brand indigo → purple
  // ---------------------------------------------------------------------------

  /// Bottone primario con gradiente brand.
  ///
  /// - Altezza fissa 50 px; la larghezza è [double.infinity] se [width] è null.
  /// - Quando [isLoading] è true mostra uno spinner invece del testo.
  /// - Quando [onPressed] è null il bottone è visivamente disabilitato.
  ///
  /// Esempio:
  /// ```dart
  /// AppButton.primary(
  ///   context,
  ///   label: 'Accedi',
  ///   onPressed: _isLoading ? null : _onLogin,
  ///   isLoading: _isLoading,
  /// )
  /// ```
  static Widget primary(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    bool isLoading = false,
    double? width,
    IconData? icon,
  }) {
    final bool disabled = onPressed == null && !isLoading;

    return SizedBox(
      width: width ?? double.infinity,
      height: 50,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: disabled
                ? [Colors.grey.shade400, Colors.grey.shade500]
                : [AppTheme.indigo, AppTheme.purple],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, color: Colors.white, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                    ],
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // SECONDARY — bordo brand, fill trasparente
  // ---------------------------------------------------------------------------

  /// Bottone secondario con bordo colorato e sfondo trasparente.
  ///
  /// Esempio:
  /// ```dart
  /// AppButton.secondary(context, label: 'Annulla', onPressed: () {})
  /// ```
  static Widget secondary(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
    IconData? icon,
  }) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: cs.primary,
          side: BorderSide(color: cs.primary, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.sm),
            ],
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TEXT — nessun bordo né fill
  // ---------------------------------------------------------------------------

  /// Bottone di tipo testo senza decorazione.
  ///
  /// Esempio:
  /// ```dart
  /// AppButton.text(context, label: 'Continua come ospite', onPressed: _onGuest)
  /// ```
  static Widget text(
    BuildContext context, {
    required String label,
    required VoidCallback? onPressed,
  }) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.primary,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
