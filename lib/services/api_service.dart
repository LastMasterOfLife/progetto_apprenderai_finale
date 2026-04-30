// =============================================================================
// ApiService — Layer HTTP centralizzato per ApprenderAI
// =============================================================================
//
// Tutte e quattro le integrazioni backend dell'app vivono qui:
//
//   1. GET  /recupera_indice          → [fetchChaptersIndex]
//      Recupera e formatta l'indice dei capitoli da mostrare nel libro.
//
//   2. POST /rag  (caricamento cap.)  → [fetchChapterContent]
//      Carica il contenuto RAG di un capitolo per la pagina sinistra.
//
//   3. POST /rag  (chat)              → [sendChatMessage]
//      Invia un messaggio a Hooty con lo storico conversazione corrente.
//
//   4. POST n8n webhook + QuickChart  → [generateConceptMap]
//      Genera la mappa concettuale in due passi: DOT via n8n → SVG via QuickChart.
//
// I consumer (LessonScreen, BookStackWidget, ContentPageLayer) importano SOLO
// questo file e non devono mai usare il package http direttamente.
//
// Errori: le chiamate lanciano [ApiException] invece di restituire stringhe
// vuote, così i consumer possono distinguere "errore di rete" da "risposta OK
// ma vuota".
// =============================================================================

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/constants.dart';
import '../utils/app_enums.dart';

// ---------------------------------------------------------------------------
// Modelli di risposta
// ---------------------------------------------------------------------------

/// Risultato della generazione mappa concettuale.
///
/// Contiene sia la stringa DOT originale (per debug/riprova) sia
/// la stringa SVG pronta al rendering.
class ConceptMapResult {
  /// Stringa in formato DOT (Graphviz) ricevuta da n8n.
  final String dotString;

  /// Stringa SVG generata da QuickChart a partire dal DOT.
  final String svgString;

  const ConceptMapResult({
    required this.dotString,
    required this.svgString,
  });
}

// ---------------------------------------------------------------------------
// Eccezione tipizzata
// ---------------------------------------------------------------------------

/// Eccezione lanciata da [ApiService] in caso di errore HTTP o di rete.
///
/// Usare [statusCode] per distinguere errori di rete ([null]) da errori HTTP.
class ApiException implements Exception {
  /// Messaggio leggibile dall'utente (già in italiano).
  final String message;

  /// Codice HTTP del server, se disponibile.
  final int? statusCode;

  const ApiException(this.message, {this.statusCode});

  @override
  String toString() => statusCode != null
      ? 'ApiException($statusCode): $message'
      : 'ApiException: $message';
}

// ---------------------------------------------------------------------------
// ApiService
// ---------------------------------------------------------------------------

/// Service layer per tutte le chiamate HTTP di ApprenderAI.
///
/// È una classe `const` senza stato: instanziala con `const ApiService()`
/// oppure tienine una sola istanza nel widget che ne ha bisogno.
class ApiService {
  const ApiService();

  // ==========================================================================
  // 1. Indice capitoli
  // ==========================================================================

  /// Recupera e analizza l'indice dei capitoli dal backend RAG.
  ///
  /// Restituisce la stringa formattata pronta per [BookLayer.chaptersIndex].
  /// Lancia [ApiException] in caso di errore HTTP o di connessione.
  Future<String> fetchChaptersIndex() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConstants.recuperaIndiceEndpoint),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String raw = (data['answer'] ?? '') as String;
        return parseChaptersIndex(raw);
      } else {
        throw ApiException(
          'Errore nel recupero dell\'indice (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiService.fetchChaptersIndex error: $e');
      throw ApiException('Impossibile connettersi al server: $e');
    }
  }

  // ==========================================================================
  // 2. Contenuto capitolo
  // ==========================================================================

  /// Carica il contenuto RAG per [topic] al livello scolastico [level].
  ///
  /// [history] è la conversazione precedente (lista vuota al primo caricamento).
  /// Restituisce la stringa della risposta dell'LLM.
  /// Lancia [ApiException] in caso di errore.
  Future<String> fetchChapterContent({
    required String topic,
    required SchoolLevel level,
    List<Map<String, String>> history = const [],
  }) async {
    final query = 'parlami di ${topic.trim()}? (${level.apiLevelQuery})';

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ragEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
          _buildRagBody(query: query, numResults: 30, history: history),
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['answer'] as String?) ?? 'Nessun contenuto trovato.';
      } else {
        throw ApiException(
          'Errore nel recupero del capitolo (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiService.fetchChapterContent error: $e');
      throw ApiException('Errore di connessione al server: $e');
    }
  }

  // ==========================================================================
  // 3. Chat con Hooty
  // ==========================================================================

  /// Invia [question] a Hooty nel contesto di [topic] e [level].
  ///
  /// [history] deve essere lo storico completo come coppie role/content.
  /// Restituisce il testo della risposta.
  /// Lancia [ApiException] in caso di errore.
  Future<String> sendChatMessage({
    required String question,
    required String topic,
    required SchoolLevel level,
    required List<Map<String, String>> history,
  }) async {
    final contextSuffix = topic.isNotEmpty ? ' (argomento: $topic)' : '';
    final query = '$question$contextSuffix';

    try {
      final response = await http.post(
        Uri.parse(ApiConstants.ragEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(
          _buildRagBody(query: query, numResults: 15, history: history),
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['answer'] as String?) ?? 'Non ho trovato una risposta.';
      } else {
        throw ApiException(
          'Errore nella risposta dal server (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiService.sendChatMessage error: $e');
      throw ApiException('Non riesco a connettermi al server: $e');
    }
  }

  // ==========================================================================
  // 4. Mappa concettuale (n8n DOT → QuickChart SVG)
  // ==========================================================================

  /// Genera la mappa concettuale per [topic] in due passi:
  ///   1. POST a n8n → stringa DOT.
  ///   2. POST a QuickChart → stringa SVG.
  ///
  /// Restituisce un [ConceptMapResult] con entrambe le stringhe.
  /// Lancia [ApiException] se uno dei due passi fallisce.
  Future<ConceptMapResult> generateConceptMap(String topic) async {
    final trimmedTopic = topic.trim();
    if (trimmedTopic.isEmpty) {
      throw const ApiException('Il topic non può essere vuoto.');
    }

    // --- STEP 1: DOT via n8n ---
    debugPrint('=== ApiService: generateConceptMap Step 1 (DOT) topic=$trimmedTopic');

    final http.Response dotResponse;
    try {
      dotResponse = await http
          .post(
            Uri.parse(ApiConstants.generateMapEndpoint),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'topic': trimmedTopic, 'depth': 3}),
          )
          .timeout(
            ApiConstants.mapRequestTimeout,
            onTimeout: () => throw ApiException(
              'Timeout: il server impiega troppo a rispondere. Riprova tra qualche secondo.',
            ),
          );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Errore di connessione nella generazione mappa: $e');
    }

    debugPrint('ApiService: DOT response status=${dotResponse.statusCode}');

    if (dotResponse.statusCode != 200) {
      throw ApiException(
        'Errore generazione mappa (HTTP ${dotResponse.statusCode}).',
        statusCode: dotResponse.statusCode,
      );
    }

    final dotString = _extractDotFromResponse(dotResponse.body);
    debugPrint('ApiService: DOT estratto (${dotString.length} chars)');

    if (dotString.isEmpty) {
      throw const ApiException(
        'La risposta del server non contiene una mappa DOT valida.',
      );
    }

    // --- STEP 2: SVG via QuickChart ---
    final svgString = await _fetchSvgFromDot(dotString);

    return ConceptMapResult(dotString: dotString, svgString: svgString);
  }

  // ==========================================================================
  // Helper privati
  // ==========================================================================

  /// Costruisce il body JSON condiviso dalle chiamate RAG (fetchChapterContent
  /// e sendChatMessage).
  Map<String, dynamic> _buildRagBody({
    required String query,
    required int numResults,
    required List<Map<String, String>> history,
  }) =>
      {
        'query': query,
        'num_results': numResults,
        'llm_mode': true,
        'conversation_history': history,
        'enable_tts': false,
        'tts_voice': '',
      };

  /// Estrae la stringa DOT dalla risposta raw del server n8n.
  ///
  /// Supporta tre formati:
  ///   1. Testo DOT diretto (inizia con "digraph", "graph" o "strict")
  ///   2. JSON con campo "dot", "output", "graph", "answer" o "result"
  ///   3. JSON con campo "data" che contiene a sua volta la stringa DOT
  String _extractDotFromResponse(String responseBody) {
    final trimmed = responseBody.trim();

    // Formato 1: DOT diretto
    if (trimmed.startsWith('digraph') ||
        trimmed.startsWith('graph ') ||
        trimmed.startsWith('strict ')) {
      return trimmed;
    }

    // Formato 2: JSON
    try {
      final parsed = json.decode(trimmed);
      if (parsed is Map) {
        // Campi comuni usati da n8n
        for (final key in [
          'dot',
          'output',
          'graph',
          'answer',
          'result',
          'data'
        ]) {
          final value = parsed[key];
          if (value is String && value.trim().isNotEmpty) {
            final inner = value.trim();
            if (inner.startsWith('digraph') ||
                inner.startsWith('graph ') ||
                inner.startsWith('strict ')) {
              return inner;
            }
            // Tenta parsing JSON annidato
            try {
              final nested = json.decode(inner);
              if (nested is Map) {
                for (final nk in ['dot', 'output', 'graph']) {
                  if (nested[nk] is String) return (nested[nk] as String).trim();
                }
              }
            } catch (_) {}
            return inner;
          }
        }
        // Se la mappa ha un solo valore stringa, usalo
        final stringValues = parsed.values.whereType<String>().toList();
        if (stringValues.length == 1) return stringValues.first.trim();
      }
    } catch (_) {
      // Non è JSON valido — fallback al body grezzo
    }

    return trimmed;
  }

  /// Converte una stringa DOT in SVG usando QuickChart.io.
  ///
  /// Lancia [ApiException] se la conversione fallisce.
  Future<String> _fetchSvgFromDot(String dotString) async {
    debugPrint('=== ApiService: generateConceptMap Step 2 (SVG) ===');
    try {
      final response = await http
          .post(
            Uri.parse('https://quickchart.io/graphviz'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'graph': dotString, 'format': 'svg'}),
          )
          .timeout(const Duration(seconds: 30));

      debugPrint(
          'ApiService: SVG response status=${response.statusCode} len=${response.body.length}');

      if (response.statusCode == 200) {
        return response.body;
      } else {
        throw ApiException(
          'Errore nella conversione DOT→SVG (HTTP ${response.statusCode}).',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      debugPrint('ApiService._fetchSvgFromDot error: $e');
      throw ApiException('Errore QuickChart: $e');
    }
  }
}
