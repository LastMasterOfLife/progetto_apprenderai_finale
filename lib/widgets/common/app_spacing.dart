// =============================================================================
// AppSpacing — Sistema di spaziatura a griglia 4pt
// =============================================================================
//
// Tutte le distanze di padding, gap e margin nell'app devono usare queste
// costanti invece di valori interi letterali.
//
// Griglia: unità base = 4 px, tutti i valori sono multipli di 4.
//
// Uso:
//   SizedBox(height: AppSpacing.lg)
//   EdgeInsets.all(AppSpacing.xl)
//   padding: EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.lg)
// =============================================================================

/// Costanti di spaziatura basate su griglia a 4 punti.
///
/// Mapping dei valori raw più comuni:
///   4  → [xs]   8  → [sm]   12 → [md]
///   16 → [lg]   24 → [xl]   32 → [xxl]   48 → [huge]
abstract final class AppSpacing {
  /// 4 px — micro-gap (badge, separatori stretti, gap icona/stato)
  static const double xs = 4;

  /// 8 px — gap piccolo (icona → label, spazio tra elementi inline)
  static const double sm = 8;

  /// 12 px — medio-piccolo (ritmo verticale dentro una card)
  static const double md = 12;

  /// 16 px — standard (padding card, gap tra sezioni vicine)
  static const double lg = 16;

  /// 24 px — grande (tra sezioni, separazione blocchi form)
  static const double xl = 24;

  /// 32 px — extra-large (padding pagina, gap tra aree principali)
  static const double xxl = 32;

  /// 48 px — hero/splash (gap principali nella splash screen)
  static const double huge = 48;
}
