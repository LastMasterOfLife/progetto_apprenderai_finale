enum MessageRole { user, assistant }

class ChatMessage {
  final String id;
  final MessageRole role;
  final String text;
  final DateTime createdAt;

  // opzionali (se ti servono dopo)
  final bool? audioEnabled;
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

class ContextResult {
  final String content;
  final int page;
  final int rank;
  final double rerankScore;
  final String source;

  ContextResult({
    required this.content,
    required this.page,
    required this.rank,
    required this.rerankScore,
    required this.source,
  });

  factory ContextResult.fromJson(Map<String, dynamic> json) => ContextResult(
    content: (json['content'] ?? '').toString(),
    page: (json['page'] ?? 0) as int,
    rank: (json['rank'] ?? 0) as int,
    rerankScore: (json['rerank_score'] ?? 0).toDouble(),
    source: (json['source'] ?? '').toString(),
  );

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
