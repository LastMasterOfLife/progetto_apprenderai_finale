// =============================================================================
// BookStackWidget — Widget principale del libro interattivo
// =============================================================================
//
// Contenitore principale che gestisce l'intero libro con animazioni di
// apertura/chiusura, pagine che girano con effetto 3D e navigazione tra
// indice, contenuti e pannello destro (note + chat).
//
// Funzionalità principali:
//   - Animazione a stack: il libro si presenta come una pila di pagine
//     impilate che si aprono con rotazione 3D sul bordo sinistro.
//   - Tre livelli di pagine rotanti: copertina, indice capitoli (BookLayer)
//     e pagina contenuto (ContentPageLayer).
//   - Pannello destro (RightPageLayer): appare quando si seleziona un
//     capitolo, con segnalibri per Note e Chat con Hooty.
//   - Gestione stato segnalibri: note adesive (StickyNote) e messaggi
//     chat con backend RAG (via HTTP POST a /rag).
//   - Swipe zone sul bordo inferiore per aprire/chiudere il libro e
//     tornare indietro dalla pagina contenuto.
//
// Usato in: LessonScreen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;
import 'OwlFaceWidget.dart';
import 'BookLayer.dart';
import 'ContentPageLayer.dart';
import 'RightPageLayer.dart';
import '../utils/ChatMessage.dart';
import '../utils/StickyNote.dart';
import '../utils/app_enums.dart';
import '../utils/constants.dart';

class BookStackWidget extends StatefulWidget {
  final String titleBook;
  final double bookWidth;
  final double bookHeight;
  final Color accentColor;
  final Color paperColor;
  final String chaptersIndex;
  final Function(String)? onChapterSelected;

  /// true mentre LessonScreen sta ancora caricando l'indice dall'API
  final bool isLoadingIndex;

  const BookStackWidget({
    super.key,
    required this.bookWidth,
    required this.bookHeight,
    required this.titleBook,
    this.accentColor = Colors.green,
    this.paperColor = const Color(0xFFF3EBDD),
    this.chaptersIndex = '',
    this.onChapterSelected,
    this.isLoadingIndex = false,
  });

  @override
  State<BookStackWidget> createState() => _BookStackWidgetState();
}

class _BookStackWidgetState extends State<BookStackWidget>
    with TickerProviderStateMixin {
  late AnimationController _stackMoveController;
  late AnimationController _firstPageController;
  late AnimationController _secondPageController;
  late AnimationController _thirdPageController;

  late Animation<double> _stackMoveAnimation;
  late Animation<double> _firstPageRotation;
  late Animation<double> _secondPageRotation;
  late Animation<double> _thirdPageRotation;

  bool _isOpen = false;
  bool _isContentPageOpen = false;
  bool _isLoadingContent = false;
  String _selectedChapter = "";

  /// Contenuto mostrato sulla pagina sinistra.
  /// Viene aggiornato sia dal fetch del capitolo che dalle risposte chat,
  /// riflettendo sempre l'ultima informazione richiesta dall'utente.
  String _pageContent = "";

  // === Bookmark state ===
  BookmarkTab? _activeBookmarkTab; // null visibile = mostra note (default)

  final List<StickyNote> _notes = [];

  /// Storico chat per capitolo: chiave = nome capitolo, valore = messaggi.
  /// I messaggi sopravvivono alla chiusura/riapertura del capitolo.
  final Map<String, List<ChatMessage>> _chatHistories = {};

  /// Restituisce la lista dei messaggi del capitolo corrente (mai null).
  List<ChatMessage> get _currentChatMessages =>
      _chatHistories[_selectedChapter] ?? [];

  final TextEditingController _chatTextController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final OwlEyeController _owlController = OwlEyeController();
  bool _isSendingChat = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  void initState() {
    super.initState();

    _stackMoveController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _firstPageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _secondPageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _thirdPageController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _stackMoveAnimation = Tween<double>(
      begin: 0.0,
      end: widget.bookWidth * 0.01,
    ).animate(CurvedAnimation(
      parent: _stackMoveController,
      curve: Curves.easeInOut,
    ));

    _firstPageRotation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _firstPageController, curve: Curves.easeInOut),
    );
    _secondPageRotation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _secondPageController, curve: Curves.easeInOut),
    );
    _thirdPageRotation = Tween<double>(begin: 0.0, end: math.pi).animate(
      CurvedAnimation(parent: _thirdPageController, curve: Curves.easeInOut),
    );

    _owlController.startPeriodicBlinking();

    _chatTextController.addListener(() {
      _owlController.updateEyeOffset(
        ((_chatTextController.text.length % 10 - 5) / 5).clamp(-0.8, 0.8),
      );
    });
  }

  @override
  void dispose() {
    _stackMoveController.dispose();
    _firstPageController.dispose();
    _secondPageController.dispose();
    _thirdPageController.dispose();
    _chatTextController.dispose();
    _chatScrollController.dispose();
    _owlController.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Helpers: livello scolastico
  // ---------------------------------------------------------------------------

  SchoolLevel get _schoolLevel =>
      SchoolLevel.fromRouteArgument(widget.titleBook);

  Color _getLevelColor() => _schoolLevel.color;

  String _getCoverImagePath() => _schoolLevel.coverImagePath;

  String _getTitleBook() => _schoolLevel.displayName;

  // ---------------------------------------------------------------------------
  // Apertura / chiusura libro
  // ---------------------------------------------------------------------------

  void _toggleBook() => _isOpen ? _closeBook() : _openBook();

  void _openBook() async {
    setState(() => _isOpen = true);
    _stackMoveController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _firstPageController.forward();
    await Future.delayed(const Duration(milliseconds: 300));
    _secondPageController.forward();
  }

  void _closeBook() async {
    if (_isContentPageOpen) await _closeContentPage();
    _secondPageController.reverse();
    await Future.delayed(const Duration(milliseconds: 200));
    _firstPageController.reverse();
    await Future.delayed(const Duration(milliseconds: 300));
    _stackMoveController.reverse();
    setState(() => _isOpen = false);
  }

  // ---------------------------------------------------------------------------
  // Selezione capitolo
  // ---------------------------------------------------------------------------

  void _onChapterSelected(String chapter) async {
    if (_isContentPageOpen) return;

    await Future.delayed(const Duration(milliseconds: 250));

    setState(() {
      _isContentPageOpen = true;
      _selectedChapter = chapter;
      _activeBookmarkTab = BookmarkTab.notes;
    });

    _fetchChapterContent(chapter);
    _thirdPageController.forward();

    // Se il capitolo ha già una chat, scorri fino all'ultimo messaggio
    if (_chatHistories.containsKey(chapter) &&
        _chatHistories[chapter]!.isNotEmpty) {
      _scrollChatToBottom();
    }
  }

  Future<void> _closeContentPage() async {
    await _thirdPageController.reverse();
    setState(() {
      _isContentPageOpen = false;
      _selectedChapter = "";
      _pageContent = "";
    });
  }

  // ---------------------------------------------------------------------------
  // API: contenuto capitolo
  // ---------------------------------------------------------------------------

  Future<void> _fetchChapterContent(String chapter) async {
    setState(() {
      _isLoadingContent = true;
      _selectedChapter = chapter;
      _pageContent = "";
    });

    try {
      final String query =
          "parlami di ${chapter.trim()}? (${_schoolLevel.apiLevelQuery})";

      final response = await http.post(
        Uri.parse(ApiConstants.ragEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          "query": query,
          "num_results": 30,
          "llm_mode": true,
          "conversation_history": [],
          "enable_tts": false,
          "tts_voice": "",
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() => _pageContent = data['answer'] ?? "Nessun contenuto trovato.");
      } else {
        setState(() => _pageContent = "Errore nel recupero del contenuto (HTTP ${response.statusCode}).");
      }
    } catch (e) {
      debugPrint('Errore RAG fetch capitolo: $e');
      setState(() => _pageContent = "Errore di connessione al server.");
    } finally {
      setState(() => _isLoadingContent = false);
    }
  }

  // ---------------------------------------------------------------------------
  // API: chat con Hooty
  // ---------------------------------------------------------------------------

  Future<void> _sendChatMessage() async {
    final text = _chatTextController.text.trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: MessageRole.user,
      text: text,
      createdAt: DateTime.now(),
    );

    // Assicura che esista una lista per questo capitolo
    _chatHistories.putIfAbsent(_selectedChapter, () => []);

    setState(() {
      _chatHistories[_selectedChapter]!.add(userMsg);
      _isSendingChat = true;
      _isLoadingContent = true;
    });
    _chatTextController.clear();
    _scrollChatToBottom();

    try {
      final contextSuffix = _selectedChapter.isNotEmpty
          ? ' (argomento: $_selectedChapter)'
          : '';

      final conversationHistory = _currentChatMessages
          .map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final response = await http.post(
        Uri.parse(ApiConstants.ragEndpoint),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': '$text$contextSuffix',
          'num_results': 15,
          'llm_mode': true,
          'conversation_history': conversationHistory,
          'enable_tts': false,
          'tts_voice': '',
        }),
      );

      final String answerText;
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        answerText = data['answer'] ?? 'Non ho trovato una risposta.';
      } else {
        answerText = 'Ops! Errore nella risposta dal server (HTTP ${response.statusCode}).';
      }

      setState(() {
        // La risposta di Hooty aggiorna la pagina sinistra
        _pageContent = answerText;
        _chatHistories[_selectedChapter]!.add(ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          text: answerText,
          createdAt: DateTime.now(),
        ));
      });
    } catch (e) {
      debugPrint('Errore chat RAG: $e');
      const errorText = 'Non riesco a connettermi al server.';
      setState(() {
        _pageContent = errorText;
        _chatHistories[_selectedChapter]!.add(ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          text: errorText,
          createdAt: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isSendingChat = false;
        _isLoadingContent = false;
      });
      _scrollChatToBottom();
    }
  }

  /// Cancella la chat del capitolo corrente per iniziarne una nuova.
  /// Lo storico degli altri capitoli rimane intatto.
  void _startNewChat() {
    setState(() {
      _chatHistories[_selectedChapter] = [];
      _pageContent = ""; // torna al contenuto del capitolo
    });
    // Ricarica il contenuto del capitolo sulla pagina sinistra
    _fetchChapterContent(_selectedChapter);
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Bookmark callbacks
  // ---------------------------------------------------------------------------

  void _onBookmarkTabChanged(BookmarkTab? tabId) {
    setState(() {
      // Stessa pressione = torna a notes (default), altra pressione = cambia tab
      _activeBookmarkTab =
          (_activeBookmarkTab == tabId) ? BookmarkTab.notes : tabId;
    });
  }

  // ---------------------------------------------------------------------------
  // Note callbacks
  // ---------------------------------------------------------------------------

  void _addNewNote() {
    final random = math.Random();
    const colors = [
      Color(0xFFFFEB3B),
      Color(0xFFFFF176),
      Color(0xFFFFF9C4),
      Color(0xFFFFEE58),
      Color(0xFFFFD54F),
    ];
    setState(() {
      _notes.add(StickyNote(
        title: '',
        content: '',
        color: colors[random.nextInt(colors.length)],
        rotation: (random.nextDouble() - 0.5) * 0.1,
      ));
    });
  }

  void _deleteNote(int index) {
    setState(() => _notes.removeAt(index));
  }

  // _updateNote non chiama setState intenzionalmente: i TextField delle note
  // gestiscono internamente la visualizzazione del testo digitato. Il dato
  // aggiornato viene salvato in _notes e usato al prossimo rebuild completo
  // (es. cambio tab). Aggiungere setState causerebbe perdita del focus su
  // ogni carattere digitato.
  void _updateNote(int index, StickyNote updated) {
    _notes[index] = updated;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final thinBookWidth   = widget.bookWidth * 0.99;
    final quartoBookWidth = widget.bookWidth * 0.97;
    final terzoBookWidth  = widget.bookWidth * 0.95;
    final secondoBookWidth = widget.bookWidth * 0.93;
    final primoBookWidth  = widget.bookWidth * 0.91;
    final mediumBookWidth = widget.bookWidth * 0.96;
    const double swipeZoneHeight = 60;

    final double totalWidth =
        _isOpen ? widget.bookWidth * 2 + _stackMoveAnimation.value : widget.bookWidth;

    final levelColor = _getLevelColor();

    return AnimatedBuilder(
      animation: Listenable.merge([
        _stackMoveController,
        _firstPageController,
        _secondPageController,
        _thirdPageController,
      ]),
      builder: (context, child) {
        return Center(
          child: SizedBox(
            width: totalWidth,
            height: widget.bookHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // ============================================================
                // PAGINE CHE RUOTANO (solo visive, IgnorePointer)
                // ============================================================

                // Prima pagina colorata
                if (_isOpen)
                  Positioned(
                    left: widget.bookWidth,
                    top: 0,
                    child: IgnorePointer(
                      ignoring: _firstPageRotation.value > math.pi / 2,
                      child: Transform(
                        alignment: Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_firstPageRotation.value),
                        child: Container(
                          width: widget.bookWidth,
                          height: widget.bookHeight,
                          decoration: BoxDecoration(
                            color: levelColor,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // Seconda pagina (indice) — animazione visiva
                if (_isOpen)
                  Positioned(
                    left: widget.bookWidth,
                    top: 8,
                    bottom: 5,
                    child: IgnorePointer(
                      ignoring: true,
                      child: Transform(
                        alignment: Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_secondPageRotation.value),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: BookLayer(
                            width: thinBookWidth,
                            height: widget.bookHeight * 0.98 - 16,
                            color: widget.paperColor,
                            showSpine: false,
                            indiceBook: true,
                            chaptersIndex: widget.chaptersIndex,
                            levelColor: levelColor,
                            onChapterSelected: null,
                            rotationY: _secondPageRotation.value,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Terza pagina (contenuto) — animazione visiva
                if (_isOpen &&
                    (_isContentPageOpen || _thirdPageController.value > 0))
                  Positioned(
                    left: widget.bookWidth,
                    top: 8,
                    bottom: 5,
                    child: IgnorePointer(
                      ignoring: true,
                      child: Transform(
                        alignment: Alignment.centerLeft,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001)
                          ..rotateY(_thirdPageRotation.value),
                        child: Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ContentPageLayer(
                            width: widget.bookWidth * 0.99,
                            height: widget.bookHeight * 0.98 - 16,
                            color: widget.paperColor,
                            levelColor: levelColor,
                            chapterTitle: _selectedChapter,
                            chapterContent: _pageContent,
                            isLoading: _isLoadingContent,
                            rotationY: _thirdPageRotation.value,
                            onBackPressed: () {},
                          ),
                        ),
                      ),
                    ),
                  ),

                // ============================================================
                // PAGINA SINISTRA INTERATTIVA
                // ============================================================

                // Indice interattivo
                if (_isOpen &&
                    _secondPageRotation.value >= math.pi * 0.95 &&
                    !_isContentPageOpen)
                  Positioned(
                    left: _stackMoveAnimation.value,
                    top: 8,
                    bottom: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: BookLayer(
                        width: thinBookWidth,
                        height: widget.bookHeight * 0.98 - 16,
                        color: widget.paperColor,
                        showSpine: false,
                        indiceBook: true,
                        chaptersIndex: widget.chaptersIndex,
                        isLoading: widget.isLoadingIndex,
                        levelColor: levelColor,
                        onChapterSelected: _onChapterSelected,
                        rotationY: 0,
                      ),
                    ),
                  ),

                // Pagina contenuto interattiva
                if (_isOpen &&
                    _isContentPageOpen &&
                    _thirdPageRotation.value >= math.pi * 0.95)
                  Positioned(
                    left: _stackMoveAnimation.value,
                    top: 8,
                    bottom: 5,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                            color: Colors.red.withOpacity(0.1), width: 2),
                      ),
                      child: ContentPageLayer(
                        width: widget.bookWidth * 0.99,
                        height: widget.bookHeight * 0.98 - 16,
                        color: widget.paperColor,
                        levelColor: levelColor,
                        chapterTitle: _selectedChapter,
                        chapterContent: _pageContent,
                        isLoading: _isLoadingContent,
                        rotationY: 0,
                        onBackPressed: _closeContentPage,
                      ),
                    ),
                  ),

                // ============================================================
                // PAGINA DESTRA (stack + RightPageLayer)
                // ============================================================
                Positioned(
                  left: _isOpen
                      ? widget.bookWidth + _stackMoveAnimation.value
                      : 0,
                  top: 0,
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.centerLeft,
                    children: [
                      // Rettangolo base colorato
                      Container(
                        width: widget.bookWidth,
                        height: widget.bookHeight,
                        decoration: BoxDecoration(
                          color: levelColor,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),

                      // Layer intermedi di carta
                      for (final width in [
                        thinBookWidth,
                        quartoBookWidth,
                        terzoBookWidth,
                        secondoBookWidth,
                      ])
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.only(bottom: 8, top: 8),
                          child: BookLayer(
                            width: width,
                            height: widget.bookHeight * 0.98,
                            color: widget.paperColor,
                            showSpine: false,
                          ),
                        ),

                      // Pannello destro con Note e Chat (solo con contenuto aperto)
                      if (_isOpen && _isContentPageOpen)
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.only(bottom: 8, top: 8),
                          child: RightPageLayer(
                            width: primoBookWidth,
                            height: widget.bookHeight * 0.98,
                            color: widget.paperColor,
                            levelColor: levelColor,
                            activeTab: _activeBookmarkTab,
                            onTabChanged: _onBookmarkTabChanged,
                            notes: _notes,
                            onAddNote: _addNewNote,
                            onDeleteNote: _deleteNote,
                            onUpdateNote: _updateNote,
                            chatMessages: _currentChatMessages,
                            chatController: _chatTextController,
                            chatScrollController: _chatScrollController,
                            owlController: _owlController,
                            isSendingChat: _isSendingChat,
                            onSendChat: _sendChatMessage,
                            onNewChat: _startNewChat,
                          ),
                        ),

                      // Libro chiuso: ultime due pagine + copertina
                      if (!_isOpen) ...[
                        Container(
                          decoration: BoxDecoration(
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          margin: const EdgeInsets.only(bottom: 8, top: 8),
                          child: BookLayer(
                            width: primoBookWidth,
                            height: widget.bookHeight * 0.98,
                            color: widget.paperColor,
                            showSpine: false,
                          ),
                        ),
                        Container(
                          width: mediumBookWidth,
                          height: widget.bookHeight * 0.98,
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: AssetImage(_getCoverImagePath()),
                              fit: BoxFit.cover,
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(top: 100, left: 30),
                              child: Text(
                                _getTitleBook(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 30,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                // ============================================================
                // Zona swipe sul bordo inferiore
                // ============================================================
                Positioned(
                  bottom: 0,
                  left: 0,
                  width: widget.bookWidth,
                  height: swipeZoneHeight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onHorizontalDragEnd: (details) {
                      if (_isContentPageOpen) {
                        if (details.primaryVelocity != null &&
                            details.primaryVelocity! > 300) {
                          _closeContentPage();
                        }
                        return;
                      }
                      if (details.primaryVelocity != null &&
                          details.primaryVelocity! < -500) {
                        _toggleBook();
                      } else if (details.primaryVelocity != null &&
                          details.primaryVelocity! > 500 &&
                          _isOpen) {
                        _toggleBook();
                      }
                    },
                    child: Container(
                      color: Colors.orange.withOpacity(0.01),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
