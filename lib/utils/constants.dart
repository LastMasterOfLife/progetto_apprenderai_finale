// =============================================================================
// ApiConstants — Endpoint del backend centralizzati
// =============================================================================
//
// Cambia baseUrl qui per puntare a un server diverso (es. produzione).
// Tutti i file che fanno chiamate HTTP importano questo file.
// =============================================================================

class ApiConstants {
  // Backend locale RAG
  static const String baseUrl = 'http://127.0.0.1:5000';
  static const String ragEndpoint = '$baseUrl/rag';
  static const String recuperaIndiceEndpoint = '$baseUrl/recupera_indice';

  // n8n workflow — generazione mappa concettuale
  static const String generateMapEndpoint =
      'https://n8ndev.inforelea.academy/webhook/generate-map';

  // Timeout per le chiamate all'API mappa (n8n può essere lento)
  static const Duration mapRequestTimeout = Duration(seconds: 60);
}
