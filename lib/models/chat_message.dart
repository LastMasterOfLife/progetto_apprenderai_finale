// =============================================================================
// ChatMessage — Modello dati per i messaggi della chat con Hooty
// =============================================================================
//
// Contiene:
//   [MessageRole]  — enum user/assistant per identificare il mittente.
//   [ChatMessage]  — singolo messaggio con id, ruolo, testo, timestamp
//                    e metadati opzionali (audio, contesto RAG).
//   [ContextResult]— risultato di retrieval restituito dal backend RAG.
//
// Nessuna dipendenza da Flutter: importabile in logica pura e test.
// =============================================================================

/// Mittente del messaggio nella chat.
enum MessageRole {
  /// Messaggio scritto dall'utente.
  user,

  /// Risposta generata da Hooty (LLM).
  assistant,
}

/// Singolo messaggio nella conversazione con Hooty.
class ChatMessage {
  /// Identificatore univoco (usato come key nei widget lista).
  final String id;

  /// Chi ha scritto il messaggio.
  final MessageRole role;

  /// Testo del messaggio (può contenere markdown per i messaggi assistant).
  final String text;

  /// Timestamp di creazione.
  final DateTime createdAt;

  /// Se true il backend ha prodotto anche una risposta audio (opzionale).
  final bool? audioEnabled;

  /// Risultati di retrieval allegati alla risposta (opzionale).
  final List<ContextResult>? contextResults;

  ChatMessage({
    required this.id,
    required this.role,
    required this.text,
    required this.createdAt,
    this.audioEnabled,
    this.contextResults,
  });
}

/// Singolo risultato di retrieval restituito dal backend RAG.
class ContextResult {
  /// Testo del chunk recuperato.
  final String content;

  /// Numero di pagina nella fonte.
  final int page;

  /// Posizione nel ranking di retrieval.
  final int rank;

  /// Punteggio di re-ranking (più alto = più rilevante).
  final double rerankScore;

  /// Percorso/nome del documento sorgente.
  final String source;

  ContextResult({
    required this.content,
    required this.page,
    required this.rank,
    required this.rerankScore,
    required this.source,
  });

  /// Costruisce un [ContextResult] da un oggetto JSON del backend.
  factory ContextResult.fromJson(Map<String, dynamic> json) => ContextResult(
        content: (json['content'] ?? '').toString(),
        page: (json['page'] ?? 0) as int,
        rank: (json['rank'] ?? 0) as int,
        rerankScore: (json['rerank_score'] ?? 0).toDouble(),
        source: (json['source'] ?? '').toString(),
      );

  /// Costruisce un [ChatMessage] assistant dall'intera risposta JSON del backend.
  ChatMessage assistantMessageFromBackend(Map<String, dynamic> json) {
    final context = (json['context_results'] as List<dynamic>?)
            ?.map((e) => ContextResult.fromJson(e as Map<String, dynamic>))
            .toList() ??
        const [];

    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: MessageRole.assistant,
      text: (json['answer'] ?? '').toString(),
      createdAt: DateTime.now(),
      audioEnabled: json['audio_enabled'] as bool?,
      contextResults: context,
    );
  }
}
