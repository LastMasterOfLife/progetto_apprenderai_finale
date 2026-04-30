// =============================================================================
// ApiConstants — Endpoint del backend centralizzati
// =============================================================================
//
// Cambia [baseUrl] qui per puntare a un server diverso (es. produzione).
// Tutti i file che fanno chiamate HTTP usano [ApiService], che importa
// questo file internamente — i consumer non devono importarlo direttamente.
// =============================================================================

/// Costanti per gli endpoint del backend ApprenderAI.
abstract final class ApiConstants {
  // ── Backend locale RAG ────────────────────────────────────────────────────

  /// URL base del server Flask RAG locale.
  static const String baseUrl = 'http://127.0.0.1:5000';

  /// Endpoint per le query RAG (chat + caricamento capitoli).
  static const String ragEndpoint = '$baseUrl/rag';

  /// Endpoint per il recupero dell'indice dei capitoli.
  static const String recuperaIndiceEndpoint = '$baseUrl/recupera_indice';

  // ── n8n — generazione mappa concettuale ──────────────────────────────────

  /// Webhook n8n che riceve un topic e restituisce una stringa DOT.
  static const String generateMapEndpoint =
      'https://n8ndev.inforelea.academy/webhook/generate-map';

  // ── Timeout ───────────────────────────────────────────────────────────────

  /// Timeout per la chiamata alla mappa concettuale (n8n può essere lento).
  static const Duration mapRequestTimeout = Duration(seconds: 60);
}
