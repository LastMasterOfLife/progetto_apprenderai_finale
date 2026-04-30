// =============================================================================
// RightPageLayer — Pagina destra del libro con segnalibri (Note e Chat)
// =============================================================================
//
// Renderizza la pagina sul lato destro del libro aperto. Contiene due
// segnalibri cliccabili in alto a destra (tab a forma di linguetta):
//
//   - "Note" (icona sticky note, colore giallo): apre la vista note adesive
//     dove l'utente può creare, modificare e cancellare appunti personali.
//   - "Hooty" (icona chat, colore blu): apre la chat con il gufo
//     assistente Hooty, che risponde usando il backend RAG.
//
// I segnalibri funzionano come toggle: cliccando lo stesso tab si chiude
// il pannello, cliccandone un altro si cambia vista. I tab sono disegnati
// con CustomPaint (BookmarkTabPainter) per la forma a chevron.
//
// Quando nessun tab è attivo, mostra un messaggio di istruzioni.
//
// Nota: usa sempre colori "carta vintage" per il background — NON usa il
// tema app (light/dark) per mantenere la metafora fisica del libro.
//
// Usato in: BookStackWidget (quando il libro è aperto e la pagina
//           contenuto è visibile)
// =============================================================================

import 'package:flutter/material.dart';
import 'owl_face_widget.dart';
import 'book_painters.dart';
import '../models/chat_message.dart';
import '../models/sticky_note.dart';
import '../utils/app_enums.dart';

/// La pagina a destra con i segnalibri (Note & Chat Hooty)
class RightPageLayer extends StatelessWidget {
  final double width;
  final double height;
  final Color color;
  final Color levelColor;
  final BookmarkTab? activeTab;
  final ValueChanged<BookmarkTab?> onTabChanged;

  // Notes
  final List<StickyNote> notes;
  final VoidCallback onAddNote;
  final ValueChanged<int> onDeleteNote;
  final void Function(int, StickyNote) onUpdateNote;

  // Chat
  final List<ChatMessage> chatMessages;
  final TextEditingController chatController;
  final ScrollController chatScrollController;
  final OwlEyeController owlController;
  final bool isSendingChat;
  final VoidCallback onSendChat;

  /// Cancella la chat corrente e ne inizia una nuova
  final VoidCallback onNewChat;

  const RightPageLayer({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    required this.levelColor,
    required this.activeTab,
    required this.onTabChanged,
    required this.notes,
    required this.onAddNote,
    required this.onDeleteNote,
    required this.onUpdateNote,
    required this.chatMessages,
    required this.chatController,
    required this.chatScrollController,
    required this.owlController,
    required this.isSendingChat,
    required this.onSendChat,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Page content with padding (leave top space for bookmark tabs)
          Positioned.fill(
            top: height * 0.25 + 8,
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: _buildPageContent(),
            ),
          ),
          // Bookmark tabs inside the page, at top-right
          Positioned(
            top: 0,
            right: 12,
            child: Row(
              children: [
                _buildBookmarkTab(
                  label: 'Note',
                  icon: Icons.sticky_note_2_outlined,
                  tab: BookmarkTab.notes,
                  color: const Color(0xFFFFEB3B),
                ),
                const SizedBox(width: 6),
                _buildBookmarkTab(
                  label: 'Hooty',
                  icon: Icons.chat_bubble_outline,
                  tab: BookmarkTab.chat,
                  color: const Color(0xFF5C8EC8),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageContent() {
    if (activeTab == BookmarkTab.chat) {
      return _buildChatView();
    }
    // Default (notes o null): mostra le note
    return _buildNotesView();
  }

  Widget _buildBookmarkTab({
    required String label,
    required IconData icon,
    required BookmarkTab tab,
    required Color color,
  }) {
    final bool isActive = activeTab == tab;
    const double tabWidth = 48;
    final double tabHeight = height * 0.22;

    return Container(
      color: Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTabChanged(tab),
          child: SizedBox(
            width: tabWidth,
            height: tabHeight + 12,
            child: CustomPaint(
              painter: BookmarkTabPainter(
                color: isActive ? color : color.withOpacity(0.7),
                isActive: isActive,
                shadowColor: Colors.black.withOpacity(0.2),
              ),
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 18,
                      color: isActive ? Colors.black87 : Colors.black54,
                    ),
                    const SizedBox(height: 4),
                    RotatedBox(
                      quarterTurns: 1,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight:
                              isActive ? FontWeight.bold : FontWeight.w500,
                          color: isActive ? Colors.black87 : Colors.black54,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Notes View
  // ---------------------------------------------------------------------------

  Widget _buildNotesView() {
    return Column(
      children: [
        // Header
        Row(
          children: [
            const Icon(Icons.sticky_note_2,
                size: 20, color: Color(0xFFFFEB3B)),
            const SizedBox(width: 8),
            Text(
              'Le mie Note',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: levelColor,
              ),
            ),
            const Spacer(),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onAddNote,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEB3B).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFFFEB3B), width: 1),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 14, color: Colors.black87),
                      SizedBox(width: 3),
                      Text(
                        'Nuova',
                        style:
                            TextStyle(fontSize: 11, color: Colors.black87),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Divider(height: 1),
        const SizedBox(height: 10),
        // Notes area
        Expanded(
          child: notes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sticky_note_2_outlined,
                          size: 48, color: Colors.black26),
                      SizedBox(height: 8),
                      Text(
                        'Nessuna nota ancora.\nPremi "Nuova" per iniziare!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black38,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: List.generate(notes.length, (index) {
                      return _buildStickyNote(index);
                    }),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildStickyNote(int index) {
    final note = notes[index];
    return Transform.rotate(
      angle: note.rotation,
      child: Container(
        width: 130,
        constraints: const BoxConstraints(minHeight: 110),
        decoration: BoxDecoration(
          color: note.color,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 6,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Folded corner
            Positioned(
              bottom: 0,
              right: 0,
              child: CustomPaint(
                painter: FoldedCornerPainter(color: note.color),
                size: const Size(16, 16),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Titolo...',
                      hintStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.black38),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (val) =>
                        onUpdateNote(index, note.copyWith(title: val)),
                  ),
                  Container(
                      height: 1,
                      color: Colors.black12,
                      margin: const EdgeInsets.symmetric(vertical: 3)),
                  TextField(
                    maxLines: null,
                    style: const TextStyle(
                        fontSize: 10, color: Colors.black87, height: 1.4),
                    decoration: const InputDecoration(
                      hintText: 'Scrivi...',
                      hintStyle:
                          TextStyle(fontSize: 10, color: Colors.black38),
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                    ),
                    onChanged: (val) =>
                        onUpdateNote(index, note.copyWith(content: val)),
                  ),
                ],
              ),
            ),
            // Delete
            Positioned(
              top: 2,
              right: 2,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => onDeleteNote(index),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        size: 12, color: Colors.black54),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Chat View
  // ---------------------------------------------------------------------------

  /// Mostra solo i messaggi dell'utente (le risposte di Hooty appaiono sulla
  /// pagina sinistra)
  Widget _buildChatView() {
    // Filtra solo i messaggi dell'utente per la visualizzazione
    final userMessages =
        chatMessages.where((m) => m.role == MessageRole.user).toList();

    return Column(
      children: [
        // Hooty header
        ListenableBuilder(
          listenable: owlController,
          builder: (context, _) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                OwlFaceWidget(
                  eyeOffset: owlController.eyeOffset,
                  headSize: 45,
                  isBlinking: owlController.isBlinking,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hooty',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: levelColor,
                        ),
                      ),
                      const Text(
                        'Scrivi qui, la risposta apparirà a sinistra',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.black54,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottone "Nuova chat" — visibile solo se c'è già una conversazione
                if (userMessages.isNotEmpty)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: onNewChat,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: levelColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: levelColor.withOpacity(0.3), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_comment_outlined,
                                size: 12, color: levelColor),
                            const SizedBox(width: 3),
                            Text(
                              'Nuova',
                              style: TextStyle(
                                fontSize: 10,
                                color: levelColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(height: 6),
        const Divider(height: 1),
        const SizedBox(height: 6),
        // Solo messaggi utente
        Expanded(
          child: userMessages.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      OwlFaceWidget(
                          eyeOffset: 0, headSize: 70, isBlinking: false),
                      SizedBox(height: 10),
                      Text(
                        'Ciao! Sono Hooty!\nChiedimi qualsiasi cosa\nsu questo argomento!\n\nLa mia risposta apparirà\nsulla pagina a sinistra.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic,
                            height: 1.5),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  controller: chatScrollController,
                  itemCount: userMessages.length,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  itemBuilder: (context, index) {
                    return _buildUserMessageBubble(userMessages[index]);
                  },
                ),
        ),
        // Typing indicator
        if (isSendingChat)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                OwlFaceWidget(
                    eyeOffset: owlController.eyeOffset,
                    headSize: 22,
                    isBlinking: false),
                const SizedBox(width: 6),
                Text(
                  'Hooty sta scrivendo sulla pagina...',
                  style: TextStyle(
                      fontSize: 11,
                      color: levelColor,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        // Input
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.5),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: levelColor.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: chatController,
                  maxLines: 3,
                  minLines: 1,
                  style: const TextStyle(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Chiedi a Hooty...',
                    hintStyle:
                        const TextStyle(fontSize: 12, color: Colors.black38),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 6),
                    border: InputBorder.none,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isSendingChat ? null : onSendChat,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                        color: levelColor, shape: BoxShape.circle),
                    child: const Icon(Icons.send, size: 14, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Bolla per il messaggio dell'utente (allineato a destra con stile domanda)
  Widget _buildUserMessageBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 40),
      child: Align(
        alignment: Alignment.centerRight,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: levelColor.withOpacity(0.15),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14),
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(4),
            ),
            border:
                Border.all(color: levelColor.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.question_answer,
                      size: 12, color: levelColor.withOpacity(0.6)),
                  const SizedBox(width: 4),
                  Text(
                    'La tua domanda',
                    style: TextStyle(
                        fontSize: 9,
                        color: levelColor.withOpacity(0.6),
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                message.text,
                style: const TextStyle(
                    fontSize: 12, color: Colors.black87, height: 1.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
