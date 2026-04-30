// =============================================================================
// AppCard — Card standard del design system ApprenderAI
// =============================================================================
//
// Wrapper attorno al widget [Card] di Material 3 con:
//   - Padding di default [AppSpacing.lg] su tutti i lati
//   - Elevation 0 (flat) come da design system
//   - Border-radius dal CardTheme globale (12 px)
//   - Opzione [onTap] per card interattive con effetto InkWell
//   - Opzione [customBorder] per bordi colorati (es. livello scolastico)
//
// Usa automaticamente cs.surface come sfondo — funziona in light e dark.
//
// Usato in: StartScreen (_StatCard, sezioni impostazioni), StartScreen livelli
// =============================================================================

import 'package:flutter/material.dart';
import 'app_spacing.dart';

/// Card standard dell'app con padding e stile coerenti.
///
/// Esempio base:
/// ```dart
/// AppCard(child: Text('Contenuto'))
/// ```
///
/// Esempio con bordo colorato e tap:
/// ```dart
/// AppCard(
///   onTap: () => print('tapped'),
///   customBorder: Border.all(color: Colors.blue, width: 1.5),
///   child: Text('Card interattiva'),
/// )
/// ```
class AppCard extends StatelessWidget {
  /// Contenuto della card.
  final Widget child;

  /// Padding interno. Default: [EdgeInsets.all(AppSpacing.lg)].
  final EdgeInsetsGeometry? padding;

  /// Elevation della card. Default: 0 (flat, come da design system).
  final double elevation;

  /// Callback per card interattive (aggiunge effetto InkWell).
  final VoidCallback? onTap;

  /// Bordo personalizzato — utile per evidenziare il colore del livello.
  final Border? customBorder;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.elevation = 0,
    this.onTap,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    // Prende il border-radius dal CardTheme globale (12 px)
    final radius = BorderRadius.circular(12);

    Widget content = Padding(
      padding: padding ?? const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );

    if (onTap != null) {
      content = InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: content,
      );
    }

    return Card(
      elevation: elevation,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: customBorder != null
            ? BorderSide.none // gestito da Container sotto
            : BorderSide.none,
      ),
      child: customBorder != null
          ? Container(
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: radius,
                border: customBorder,
              ),
              child: content,
            )
          : content,
    );
  }
}
