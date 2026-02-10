// =============================================================================
// MessageBubble — Bolla di messaggio per la chat con Hooty
// =============================================================================
//
// Renderizza un singolo messaggio nella chat tra l'utente e Hooty (il gufo
// assistente). I messaggi dell'utente sono allineati a destra, quelli
// dell'assistente a sinistra.
//
// Il contenuto del messaggio viene renderizzato in Markdown
// (flutter_markdown) con supporto per: grassetto, corsivo, liste,
// blocchi di codice, citazioni e titoli. Il testo è selezionabile.
//
// Usato in: RightPageLayer (vista chat)
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../utils/ChatMessage.dart';

class Messagebubble extends StatelessWidget {
  final ChatMessage message;
  const Messagebubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == MessageRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: const BoxConstraints(maxWidth: 520),
        decoration: BoxDecoration(
          color: isUser ? Colors.white : Colors.white.withOpacity(0.85),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black12),
        ),
        child: MarkdownBody(
          data: message.text,
          selectable: true,
          styleSheet: MarkdownStyleSheet(
            p: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
            strong: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            em: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.black87,
            ),
            listBullet: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            code: TextStyle(
              backgroundColor: Colors.grey.shade200,
              color: Colors.black87,
              fontFamily: 'monospace',
              fontSize: 13,
            ),
            codeblockDecoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(8),
            ),
            blockquotePadding: const EdgeInsets.all(8),
            blockquoteDecoration: BoxDecoration(
              color: Colors.grey.shade100,
              border: Border(
                left: BorderSide(
                  color: Colors.grey.shade400,
                  width: 4,
                ),
              ),
            ),
            h1: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            h2: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            h3: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}
