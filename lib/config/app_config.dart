// =============================================================================
// AppConfig — Configurazione globale dell'applicazione
// =============================================================================
//
// Contiene i flag che controllano il comportamento dell'app in sviluppo
// e in produzione. Cambia [isDev] e [enableLogin] qui per passare tra
// le due modalità senza toccare altri file.
//
// Nessuna dipendenza da Flutter: questo file è importabile anche da codice
// Dart puro (es. test).
// =============================================================================

/// Configurazione statica dell'applicazione.
abstract final class AppConfig {
  // ── Modalità build ──────────────────────────────────────────────────────────

  /// Imposta a [false] per passare in produzione.
  ///
  /// In modalità DEV:
  ///   - Le preferenze salvate (login, livello scolastico) vengono ignorate:
  ///     l'app parte sempre come al primo avvio.
  ///   - Il banner arancione "⚙ DEV" appare in alto a sinistra.
  ///   - [debugShowCheckedModeBanner] di MaterialApp è attivo.
  static const bool isDev = false;

  /// Inverso di [isDev] — comodo per guardie esplicite.
  static const bool isProd = !isDev;

  /// Stringa leggibile della modalità corrente (usata nel badge DEV).
  static const String buildMode = isDev ? 'DEV' : 'PROD';

  /// Versione dell'app mostrata nel badge DEV e nella schermata Impostazioni.
  static const String version = '1.0.0';

  // ── Feature flags ───────────────────────────────────────────────────────────

  /// Abilita/disabilita il flusso di autenticazione.
  ///
  /// Quando [true] (default), la SplashScreen reindirizza a LoginScreen
  /// se l'utente non è ancora autenticato.
  ///
  /// Quando [false], la SplashScreen salta il login e va direttamente
  /// a StartScreen (utile per demo, classroom deployment o kiosk mode).
  static const bool enableLogin = true;
}
