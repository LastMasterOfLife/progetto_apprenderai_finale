// =============================================================================
// AppTheme — Design system di ApprenderAI
// =============================================================================
//
// Contiene:
//  • [ThemeNotifier]  — ValueNotifier<ThemeMode> con persistenza su disco.
//                       Inizializzato come singleton globale [themeNotifier]
//                       in main() prima di runApp().
//
//  • [AppTheme]       — Token di colore + ThemeData completi per light e dark.
//                       Palette: navy profondo per il dark, bianco ghiaccio
//                       per il light. Accento: indigo #6366F1 (brand).
//
// Uso nelle schermate:
//   final cs = Theme.of(context).colorScheme;
//   color: cs.onSurface       // testo primario
//   color: cs.onSurfaceVariant // testo secondario
//   color: cs.surface         // sfondo card
//   color: cs.primary         // accento brand
//
// I widget del libro (BookLayer, ContentPageLayer, RightPageLayer) NON usano
// questo tema: rimangono sempre in modalità "carta vintage" chiara.
// =============================================================================

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Singleton globale — inizializzato in main() prima di runApp()
// ---------------------------------------------------------------------------

late final ThemeNotifier themeNotifier;

// ---------------------------------------------------------------------------
// ThemeNotifier
// ---------------------------------------------------------------------------

class ThemeNotifier extends ValueNotifier<ThemeMode> {
  ThemeNotifier._(super.value);

  static const String _key = 'setting_theme';

  /// Carica il tema salvato e restituisce il notifier pronto.
  static Future<ThemeNotifier> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key) ?? 'Sistema';
    return ThemeNotifier._(_themeFromString(saved));
  }

  /// Cambia il tema e lo persiste su disco.
  Future<void> setTheme(String themeName) async {
    value = _themeFromString(themeName);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, themeName);
  }

  static ThemeMode _themeFromString(String s) => switch (s) {
        'Chiaro' => ThemeMode.light,
        'Scuro'  => ThemeMode.dark,
        _        => ThemeMode.system,
      };

  static String stringFromMode(ThemeMode mode) => switch (mode) {
        ThemeMode.light => 'Chiaro',
        ThemeMode.dark  => 'Scuro',
        _               => 'Sistema',
      };
}

// ---------------------------------------------------------------------------
// AppTheme — token + ThemeData
// ---------------------------------------------------------------------------

abstract final class AppTheme {
  // ── Brand (invarianti in entrambi i temi) ────────────────────────────────
  static const Color indigo       = Color(0xFF6366F1);
  static const Color indigoLight  = Color(0xFF818CF8); // indigo più luminoso per dark
  static const Color purple       = Color(0xFFAD46FF);
  static const Color cyan         = Color(0xFF00B8DB);

  // ── Token light ──────────────────────────────────────────────────────────
  static const Color _lBg              = Color(0xFFF8FAFF);
  static const Color _lSurface         = Color(0xFFFFFFFF);
  static const Color _lSurfaceVariant  = Color(0xFFF1F5F9);
  static const Color _lPrimaryContainer= Color(0xFFEEF2FF);
  static const Color _lText            = Color(0xFF1A1A2E);
  static const Color _lTextSub         = Color(0xFF6B7280);
  static const Color _lBorder          = Color(0xFFE5E7EB);

  // ── Token dark ───────────────────────────────────────────────────────────
  static const Color _dBg              = Color(0xFF0C0E1A);
  static const Color _dSurface         = Color(0xFF131629);
  static const Color _dSurfaceVariant  = Color(0xFF1A1D30);
  static const Color _dSurfaceElevated = Color(0xFF252847);
  static const Color _dPrimaryContainer= Color(0xFF1E2457);
  static const Color _dText            = Color(0xFFF1F5F9);
  static const Color _dTextSub         = Color(0xFF94A3B8);
  static const Color _dBorder          = Color(0xFF2E3150);

  // ── ThemeData LIGHT ──────────────────────────────────────────────────────

  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: const ColorScheme.light(
      primary: indigo,
      primaryContainer: _lPrimaryContainer,
      secondary: purple,
      surface: _lSurface,
      surfaceContainerHighest: _lSurfaceVariant,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _lText,
      onSurfaceVariant: _lTextSub,
      outline: _lBorder,
      outlineVariant: Color(0xFFF3F4F6),
    ),
    scaffoldBackgroundColor: _lBg,
    // Card
    cardColor: _lSurface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: _lSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    // Divider
    dividerColor: _lBorder,
    dividerTheme: const DividerThemeData(color: _lBorder, space: 1, thickness: 1),
    // ListTile
    listTileTheme: const ListTileThemeData(
      textColor: _lText,
      iconColor: indigo,
      subtitleTextStyle: TextStyle(color: _lTextSub, fontSize: 13),
    ),
    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? indigo : Colors.white,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? indigo.withOpacity(0.45)
            : const Color(0xFFE5E7EB),
      ),
    ),
    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _lSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _lBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: indigo, width: 2),
      ),
      labelStyle: const TextStyle(color: _lTextSub),
      hintStyle: const TextStyle(color: _lTextSub),
    ),
    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: indigo),
    ),
    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: _lSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        color: _lText, fontSize: 18, fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: _lTextSub, fontSize: 14, height: 1.6,
      ),
    ),
    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1A1A2E),
      contentTextStyle: const TextStyle(color: _dText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
    // PopupMenu (DropdownButton usa canvasColor/surface)
    popupMenuTheme: const PopupMenuThemeData(
      color: _lSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    // Icon
    iconTheme: const IconThemeData(color: _lText),
    // Text
    textTheme: const TextTheme(
      displayLarge  : TextStyle(color: _lText),
      displayMedium : TextStyle(color: _lText),
      displaySmall  : TextStyle(color: _lText),
      headlineLarge : TextStyle(color: _lText, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: _lText, fontWeight: FontWeight.bold),
      headlineSmall : TextStyle(color: _lText, fontWeight: FontWeight.w600),
      titleLarge    : TextStyle(color: _lText, fontWeight: FontWeight.bold),
      titleMedium   : TextStyle(color: _lText, fontWeight: FontWeight.w600),
      titleSmall    : TextStyle(color: _lText, fontWeight: FontWeight.w500),
      bodyLarge     : TextStyle(color: _lText),
      bodyMedium    : TextStyle(color: _lText),
      bodySmall     : TextStyle(color: _lTextSub),
      labelLarge    : TextStyle(color: _lText),
      labelMedium   : TextStyle(color: _lTextSub),
      labelSmall    : TextStyle(color: _lTextSub, letterSpacing: 0.8),
    ),
  );

  // ── ThemeData DARK ───────────────────────────────────────────────────────

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: const ColorScheme.dark(
      primary: indigoLight,
      primaryContainer: _dPrimaryContainer,
      secondary: purple,
      surface: _dSurface,
      surfaceContainerHighest: _dSurfaceVariant,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: _dText,
      onSurfaceVariant: _dTextSub,
      outline: _dBorder,
      outlineVariant: Color(0xFF1E2138),
    ),
    scaffoldBackgroundColor: _dBg,
    // Card
    cardColor: _dSurface,
    cardTheme: CardThemeData(
      elevation: 0,
      color: _dSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    // Divider
    dividerColor: _dBorder,
    dividerTheme: const DividerThemeData(color: _dBorder, space: 1, thickness: 1),
    // ListTile
    listTileTheme: const ListTileThemeData(
      textColor: _dText,
      iconColor: indigoLight,
      subtitleTextStyle: TextStyle(color: _dTextSub, fontSize: 13),
    ),
    // Switch
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? indigoLight : _dTextSub,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? indigoLight.withOpacity(0.45)
            : _dBorder,
      ),
    ),
    // Input
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: _dSurfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _dBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _dBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: indigoLight, width: 2),
      ),
      labelStyle: const TextStyle(color: _dTextSub),
      hintStyle: const TextStyle(color: _dTextSub),
    ),
    // ElevatedButton
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: indigoLight,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    // TextButton
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: indigoLight),
    ),
    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: _dSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(
        color: _dText, fontSize: 18, fontWeight: FontWeight.bold,
      ),
      contentTextStyle: const TextStyle(
        color: _dTextSub, fontSize: 14, height: 1.6,
      ),
    ),
    // SnackBar
    snackBarTheme: SnackBarThemeData(
      backgroundColor: _dSurfaceElevated,
      contentTextStyle: const TextStyle(color: _dText),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      behavior: SnackBarBehavior.floating,
    ),
    // PopupMenu
    popupMenuTheme: const PopupMenuThemeData(
      color: _dSurface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    ),
    // Icon
    iconTheme: const IconThemeData(color: _dText),
    // Text
    textTheme: const TextTheme(
      displayLarge  : TextStyle(color: _dText),
      displayMedium : TextStyle(color: _dText),
      displaySmall  : TextStyle(color: _dText),
      headlineLarge : TextStyle(color: _dText, fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(color: _dText, fontWeight: FontWeight.bold),
      headlineSmall : TextStyle(color: _dText, fontWeight: FontWeight.w600),
      titleLarge    : TextStyle(color: _dText, fontWeight: FontWeight.bold),
      titleMedium   : TextStyle(color: _dText, fontWeight: FontWeight.w600),
      titleSmall    : TextStyle(color: _dText, fontWeight: FontWeight.w500),
      bodyLarge     : TextStyle(color: _dText),
      bodyMedium    : TextStyle(color: _dText),
      bodySmall     : TextStyle(color: _dTextSub),
      labelLarge    : TextStyle(color: _dText),
      labelMedium   : TextStyle(color: _dTextSub),
      labelSmall    : TextStyle(color: _dTextSub, letterSpacing: 0.8),
    ),
  );
}
