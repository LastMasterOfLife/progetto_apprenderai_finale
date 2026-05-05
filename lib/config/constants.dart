// =============================================================================
// ApiConstants — Endpoint del backend centralizzati
// =============================================================================
//
// Le porte cambiano dinamicamente in base al livello scolastico:
//   media      → 5000
//   superior   → 5001
//   university → 5002
//
// Tutti i file che fanno chiamate HTTP usano [ApiService], che importa
// questo file internamente — i consumer non devono importarlo direttamente.
// =============================================================================

import '../utils/app_enums.dart';

/// Costanti per gli endpoint del backend ApprenderAI.
abstract final class ApiConstants {
  // ── Backend locale RAG ────────────────────────────────────────────────────

  static const String _host = '192.168.1.62';

  /// URL base del server Flask RAG, con porta dipendente dal livello scolastico.
  static String baseUrl(SchoolLevel level) =>
      'http://$_host:${level.port}';

  /// Endpoint per le query RAG (chat + caricamento capitoli).
  static String ragEndpoint(SchoolLevel level) =>
      '${baseUrl(level)}/rag';

  /// Endpoint per il recupero dell'indice dei capitoli.
  static String recuperaIndiceEndpoint(SchoolLevel level) =>
      '${baseUrl(level)}/recupera_indice';

  // ── n8n — generazione mappa concettuale ──────────────────────────────────

  /// Webhook n8n che riceve un topic e restituisce una stringa DOT.
  static const String generateMapEndpoint =
      'https://n8ndev.inforelea.academy/webhook/generate-map';

  // ── Timeout ───────────────────────────────────────────────────────────────

  /// Timeout per la chiamata alla mappa concettuale (n8n può essere lento).
  static const Duration mapRequestTimeout = Duration(seconds: 60);
}
