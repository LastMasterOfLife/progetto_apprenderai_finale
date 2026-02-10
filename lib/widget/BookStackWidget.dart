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

class BookStackWidget extends StatefulWidget {

  final String titleBook;
  /// Larghezza del libro chiuso (base dello stack)
  final double bookWidth;

  /// Altezza del libro chiuso
  final double bookHeight;

  /// Colore del primo e ultimo elemento (default: rosso)
  final Color accentColor;

  /// Colore degli elementi intermedi (default: color carta)
  final Color paperColor;

  /// Indice dei capitoli da mostrare quando il libro è aperto
  final String chaptersIndex;

  /// Callback quando un capitolo viene selezionato
  final Function(String)? onChapterSelected;

  const BookStackWidget({
    super.key,
    required this.bookWidth,
    required this.bookHeight,
    required this.titleBook,
    this.accentColor = Colors.green,
    this.paperColor = const Color(0xFFF3EBDD),
    this.chaptersIndex = '',
    this.onChapterSelected,
  });

  @override
  State<BookStackWidget> createState() => _BookStackWidgetState();
}

class _BookStackWidgetState extends State<BookStackWidget> with TickerProviderStateMixin {
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
  String _chapterContent = "";

  // === Bookmark state (lives here because the right page is in the main stack) ===
  String? _activeBookmarkTab; // null | 'notes' | 'chat'
  final List<StickyNote> _notes = [];
  final List<ChatMessage> _chatMessages = [];
  final TextEditingController _chatTextController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();
  final OwlEyeController _owlController = OwlEyeController();
  bool _isSendingChat = false;

  @override
  void initState() {
    super.initState();

    // Controller per lo spostamento dello stack
    _stackMoveController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Controller per la rotazione della prima pagina (elemento top)
    _firstPageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Controller per la rotazione della seconda pagina
    _secondPageController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // Controller per la rotazione della terza pagina (contenuto) - più lenta
    _thirdPageController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Animazione di spostamento dello stack verso destra
    _stackMoveAnimation = Tween<double>(
      begin: 0.0,
      end: widget.bookWidth * 0.01,
    ).animate(CurvedAnimation(
      parent: _stackMoveController,
      curve: Curves.easeInOut,
    ));

    // Rotazione della prima pagina (da 0 a 180 gradi)
    _firstPageRotation = Tween<double>(
      begin: 0.0,
      end: math.pi,
    ).animate(CurvedAnimation(
      parent: _firstPageController,
      curve: Curves.easeInOut,
    ));

    // Rotazione della seconda pagina con delay
    _secondPageRotation = Tween<double>(
      begin: 0.0,
      end: math.pi,
    ).animate(CurvedAnimation(
      parent: _secondPageController,
      curve: Curves.easeInOut,
    ));

    // Rotazione della terza pagina (contenuto)
    _thirdPageRotation = Tween<double>(
      begin: 0.0,
      end: math.pi,
    ).animate(CurvedAnimation(
      parent: _thirdPageController,
      curve: Curves.easeInOut,
    ));

    // Owl blinking
    _owlController.startPeriodicBlinking();

    // Track chat text for owl eyes
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

  void _toggleBook() {
    if (_isOpen) {
      _closeBook();
    } else {
      _openBook();
    }
  }

  void _openBook() async {
    setState(() => _isOpen = true);

    // Sposta lo stack verso destra
    _stackMoveController.forward();

    // Dopo un breve delay, inizia a girare la prima pagina
    await Future.delayed(const Duration(milliseconds: 200));
    _firstPageController.forward();

    // Dopo altro delay, gira la seconda pagina
    await Future.delayed(const Duration(milliseconds: 300));
    _secondPageController.forward();
  }

  void _closeBook() async {
    debugPrint('_closeBook chiamato');

    // Se la pagina contenuto è aperta, chiudila prima
    if (_isContentPageOpen) {
      debugPrint('Chiudo prima la pagina contenuto');
      await _closeContentPage();
    }

    // Chiude le pagine nell'ordine inverso
    debugPrint('Chiudo le pagine del libro');
    _secondPageController.reverse();
    await Future.delayed(const Duration(milliseconds: 200));
    _firstPageController.reverse();
    await Future.delayed(const Duration(milliseconds: 300));
    _stackMoveController.reverse();

    setState(() => _isOpen = false);
  }

  /// Restituisce il livello scolastico formattato per la query API
  String _getSchoolLevelForQuery() {
    switch (widget.titleBook.toLowerCase()) {
      case 'media':
        return 'LIVELLO=MEDIE';
      case 'superior':
        return 'LIVELLO=SUPERIORI';
      case 'university':
        return 'LIVELLO=UNIVERSITA';
      default:
        return 'LIVELLO=MEDIE';
    }
  }

  /// Formatta il topic per la query API
  String _formatTopicForQuery(String chapter) {
    return chapter.trim();
  }

  /// Chiamata API per recuperare il contenuto dell'argomento selezionato
  Future<void> _fetchChapterContent(String chapter) async {
    setState(() {
      _isLoadingContent = true;
      _selectedChapter = chapter;
      _chapterContent = "";
    });

    try {
      var url = Uri.parse('http://127.0.0.1:5000/rag');
      final String levelQuery = _getSchoolLevelForQuery();
      final String topic = _formatTopicForQuery(chapter);
      final String query = "parlami di $topic? ($levelQuery)";

      debugPrint('=== RAG API Call ===');
      debugPrint('Original chapter: $chapter');
      debugPrint('Extracted topic: $topic');
      debugPrint('Final query: $query');

      final Map<String, dynamic> info = {
        "query": query,
        "num_results": 30,
        "llm_mode": true,
        "conversation_history": [],
        "enable_tts": false,
        "tts_voice": "",
      };

      debugPrint('Request body: ${json.encode(info)}');

      var response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode(info),
      );

      debugPrint('RAG Response status: ${response.statusCode}');
      debugPrint('RAG Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _chapterContent = data['answer'] ?? "Nessun contenuto trovato.";
        });
      } else {
        setState(() {
          _chapterContent = "Errore nel recupero del contenuto.";
        });
      }
    } catch (e) {
      debugPrint('Errore nella chiamata API RAG: $e');
      setState(() {
        _chapterContent = "Errore di connessione al server.";
      });
    } finally {
      setState(() {
        _isLoadingContent = false;
      });
    }
  }

  /// Apre la pagina del contenuto quando viene selezionato un capitolo.
  /// Un breve ritardo prima del flip permette all'InkWell di mostrare
  /// il feedback visivo (splash/highlight) del tap.
  void _onChapterSelected(String chapter) async {
    debugPrint('_onChapterSelected chiamato con: $chapter');
    debugPrint('_isContentPageOpen: $_isContentPageOpen');

    if (_isContentPageOpen) {
      debugPrint('Pagina già aperta, ignoro');
      return;
    }

    // Breve ritardo per mostrare il feedback visivo del tap
    await Future.delayed(const Duration(milliseconds: 250));

    debugPrint('Apro la pagina contenuto...');
    setState(() {
      _isContentPageOpen = true;
      _selectedChapter = chapter;
      _activeBookmarkTab = 'chat'; // Default: mostra le note
    });

    // Avvia la chiamata API
    _fetchChapterContent(chapter);

    // Gira la pagina
    _thirdPageController.forward().then((_) {
      debugPrint('Animazione pagina completata');
      debugPrint('_isContentPageOpen dopo animazione: $_isContentPageOpen');
      debugPrint('_thirdPageController.value: ${_thirdPageController.value}');
    });
  }

  /// Chiude la pagina del contenuto
  Future<void> _closeContentPage() async {
    await _thirdPageController.reverse();
    setState(() {
      _isContentPageOpen = false;
      _selectedChapter = "";
      _chapterContent = "";
    });
  }

  String _getCoverImagePath() {
    switch (widget.titleBook.toLowerCase()) {
      case 'media':
        return 'assets/image/cover_book_verde.jpg';
      case 'superior':
        return 'assets/image/cover_book_blu.png';
      case 'university':
        return 'assets/image/cover_book_rosso.png';
      default:
        return 'assets/image/cover_book_decoratioon.png';
    }
  }

  String get_titleBook(String titleBook) {
    if (titleBook == 'media') {
      return 'Scuole medie';
    } else if (titleBook == 'superior') {
      return 'Scuole superiori';
    } else {
      return 'Università';
    }
  }

  Color _getLevelColor() {
    switch (widget.titleBook.toLowerCase()) {
      case 'media':
        return Colors.green;
      case 'superior':
        return Colors.blue;
      case 'university':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  // === Bookmark callbacks ===
  void _onBookmarkTabChanged(String? tabId) {
    debugPrint('=== BOOKMARK CALLBACK === tabId ricevuto: $tabId, activeTab corrente: $_activeBookmarkTab');
    setState(() {
      _activeBookmarkTab = (_activeBookmarkTab == tabId) ? null : tabId;
    });
    debugPrint('=== BOOKMARK CALLBACK === nuovo activeTab: $_activeBookmarkTab');
  }

  void _addNewNote() {
    final random = math.Random();
    final rotation = (random.nextDouble() - 0.5) * 0.1;
    final colors = [
      const Color(0xFFFFEB3B),
      const Color(0xFFFFF176),
      const Color(0xFFFFF9C4),
      const Color(0xFFFFEE58),
      const Color(0xFFFFD54F),
    ];
    setState(() {
      _notes.add(StickyNote(
        title: '',
        content: '',
        color: colors[random.nextInt(colors.length)],
        rotation: rotation,
      ));
    });
  }

  void _deleteNote(int index) {
    setState(() {
      _notes.removeAt(index);
    });
  }

  void _updateNote(int index, StickyNote updated) {
    _notes[index] = updated;
  }

  Future<void> _sendChatMessage() async {
    final text = _chatTextController.text.trim();
    if (text.isEmpty) return;

    final userMsg = ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      role: MessageRole.user,
      text: text,
      createdAt: DateTime.now(),
    );

    setState(() {
      _chatMessages.add(userMsg);
      _isSendingChat = true;
      _isLoadingContent = true;
    });
    _chatTextController.clear();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      final url = Uri.parse('http://127.0.0.1:5000/rag');
      final levelQuery = _selectedChapter.isNotEmpty
          ? ' (argomento: $_selectedChapter)'
          : '';
      final conversationHistory = _chatMessages
          .map((m) => {
                'role': m.role == MessageRole.user ? 'user' : 'assistant',
                'content': m.text,
              })
          .toList();

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'query': '$text$levelQuery',
          'num_results': 15,
          'llm_mode': true,
          'conversation_history': conversationHistory,
          'enable_tts': false,
          'tts_voice': '',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final answerText = data['answer'] ?? 'Non ho trovato una risposta.';
        setState(() {
          // La risposta di Hooty va nella pagina sinistra come schema strutturato
          _chapterContent = answerText;
          // Aggiungiamo anche alla conversation history per il contesto
          _chatMessages.add(ChatMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            role: MessageRole.assistant,
            text: answerText,
            createdAt: DateTime.now(),
          ));
        });
      } else {
        setState(() {
          _chapterContent = 'Ops! Errore nella risposta dal server.';
          _chatMessages.add(ChatMessage(
            id: DateTime.now().microsecondsSinceEpoch.toString(),
            role: MessageRole.assistant,
            text: 'Ops! Errore nella risposta dal server.',
            createdAt: DateTime.now(),
          ));
        });
      }
    } catch (e) {
      setState(() {
        _chapterContent = 'Non riesco a connettermi al server.';
        _chatMessages.add(ChatMessage(
          id: DateTime.now().microsecondsSinceEpoch.toString(),
          role: MessageRole.assistant,
          text: 'Non riesco a connettermi al server.',
          createdAt: DateTime.now(),
        ));
      });
    } finally {
      setState(() {
        _isSendingChat = false;
        _isLoadingContent = false;
      });
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
  }

  @override
  Widget build(BuildContext context) {
    // Calcola le dimensioni dei rettangoli intermedi
    final thinBookWidth = widget.bookWidth * 0.99;
    final quartoBookWidth = widget.bookWidth * 0.97;
    final terzoBookWidth = widget.bookWidth * 0.95;
    final secondoBookWidth = widget.bookWidth * 0.93;
    final primoBookWidth = widget.bookWidth * 0.91;
    final mediumBookWidth = widget.bookWidth * 0.96;

    // Altezza della zona swipe sul bordo inferiore
    const double swipeZoneHeight = 60;

    // Larghezza totale dell'area di layout:
    // - Chiuso: bookWidth (solo lo stack destro)
    // - Aperto: bookWidth * 2 (pagina sinistra + pagina destra)
    final double totalWidth = _isOpen ? widget.bookWidth * 2 + _stackMoveAnimation.value : widget.bookWidth;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _stackMoveController,
        _firstPageController,
        _secondPageController,
        _thirdPageController,
      ]),
      builder: (context, child) {
        return Center(
          // SizedBox definisce l'area REALE di layout (e quindi di hit-test)
          // che si espande quando il libro è aperto.
          child: SizedBox(
            width: totalWidth,
            height: widget.bookHeight,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
              // ============================================================
              // PAGINE CHE RUOTANO (solo visive, IgnorePointer)
              // Ancorate al centro del libro (il "dorso") = metà della
              // larghezza totale quando aperto.
              // ============================================================

              // Pagina base colorata (sotto tutto quando aperto)
              if (_isOpen)
                Positioned(
                  left: widget.bookWidth, // dorso = metà di totalWidth
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
                          color: widget.titleBook == 'media'
                              ? Colors.green
                              : widget.titleBook == 'superior'
                                  ? Colors.blue
                                  : Colors.red,
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

              // Seconda pagina che ruota (carta con indice) - solo animazione visiva.
              if (_isOpen)
                Positioned(
                  left: widget.bookWidth,
                  top: 8,
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
                          levelColor: _getLevelColor(),
                          onChapterSelected: null, // solo visivo
                          rotationY: _secondPageRotation.value,
                        ),
                      ),
                    ),
                  ),
                ),

              // Terza pagina che ruota (contenuto) — solo animazione visiva.
              if (_isOpen && (_isContentPageOpen || _thirdPageController.value > 0))
                Positioned(
                  left: widget.bookWidth,
                  top: 8,
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
                          levelColor: _getLevelColor(),
                          chapterTitle: _selectedChapter,
                          chapterContent: _chapterContent,
                          isLoading: _isLoadingContent,
                          rotationY: _thirdPageRotation.value,
                          onBackPressed: () {}, // solo visivo
                        ),
                      ),
                    ),
                  ),
                ),

              // ============================================================
              // PAGINA SINISTRA INTERATTIVA (non trasformata)
              // Posizionata nella metà sinistra con Positioned reale,
              // così l'area di hit-test corrisponde alla posizione visiva.
              // ============================================================

              // Indice interattivo — posizionato a sinistra dopo che la
              // pagina dell'indice ha completato la rotazione.
              if (_isOpen && _secondPageRotation.value >= math.pi * 0.95 && !_isContentPageOpen)
                Positioned(
                  left: _stackMoveAnimation.value,
                  top: 8,
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
                      levelColor: _getLevelColor(),
                      onChapterSelected: _onChapterSelected,
                      rotationY: 0, // non trasformato, testo leggibile
                    ),
                  ),
                ),

              // Pagina contenuto interattiva — a sinistra quando la pagina
              // è completamente girata. Riceve click su bottone indietro e
              // scroll del contenuto.
              if (_isOpen && _isContentPageOpen && _thirdPageRotation.value >= math.pi * 0.95)
                Positioned(
                  left: _stackMoveAnimation.value,
                  top: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                      // DEBUG: bordo rosso per visualizzare l'area della pagina contenuto
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: ContentPageLayer(
                      width: widget.bookWidth * 0.99,
                      height: widget.bookHeight * 0.98 - 16,
                      color: widget.paperColor,
                      levelColor: _getLevelColor(),
                      chapterTitle: _selectedChapter,
                      chapterContent: _chapterContent,
                      isLoading: _isLoadingContent,
                      rotationY: 0,
                      onBackPressed: _closeContentPage,
                    ),
                  ),
                ),

              // ============================================================
              // PAGINA DESTRA (stack di pagine + RightPageLayer)
              // Posizionata nella metà destra con Positioned reale.
              // ============================================================
              Positioned(
                left: _isOpen ? widget.bookWidth + _stackMoveAnimation.value : 0,
                top: 0,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // 1. Rettangolo base colorato
                    Container(
                      width: widget.bookWidth,
                      height: widget.bookHeight,
                      decoration: BoxDecoration(
                        color: widget.titleBook == 'media'
                            ? Colors.green
                            : widget.titleBook == 'superior'
                                ? Colors.blue
                                : Colors.red,
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
                    // 2-5. Layer intermedi di carta
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
                        width: thinBookWidth,
                        height: widget.bookHeight * 0.98,
                        color: widget.paperColor,
                        showSpine: false,
                      ),
                    ),
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
                        width: quartoBookWidth,
                        height: widget.bookHeight * 0.98,
                        color: widget.paperColor,
                        showSpine: false,
                      ),
                    ),
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
                        width: terzoBookWidth,
                        height: widget.bookHeight * 0.98,
                        color: widget.paperColor,
                        showSpine: false,
                      ),
                    ),
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
                        width: secondoBookWidth,
                        height: widget.bookHeight * 0.98,
                        color: widget.paperColor,
                        showSpine: false,
                      ),
                    ),
                    // Quando il libro è aperto e la pagina contenuto è visibile,
                    // mostra la pagina destra con i segnalibri (Note e Chat)
                    if (_isOpen && _isContentPageOpen) ...[
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
                          levelColor: _getLevelColor(),
                          activeTab: _activeBookmarkTab,
                          onTabChanged: _onBookmarkTabChanged,
                          notes: _notes,
                          onAddNote: _addNewNote,
                          onDeleteNote: _deleteNote,
                          onUpdateNote: _updateNote,
                          chatMessages: _chatMessages,
                          chatController: _chatTextController,
                          chatScrollController: _chatScrollController,
                          owlController: _owlController,
                          isSendingChat: _isSendingChat,
                          onSendChat: _sendChatMessage,
                        ),
                      ),
                    ],
                    // Gli ultimi due elementi vengono mostrati solo quando chiuso
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
                            padding: const EdgeInsets.only(top: 100, left: 30),
                            child: Text(
                              get_titleBook(widget.titleBook),
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

              // === Zona swipe sul bordo inferiore del libro ===
              // Copre tutta la larghezza del layout corrente (si espande con il libro)
              Positioned(
                bottom: 0,
                left: 0,
                width: _isOpen ? widget.bookWidth : widget.bookWidth,
                height: swipeZoneHeight,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTapDown: (_) => debugPrint('TOCCO SWIPE-ZONE'),
                  onHorizontalDragEnd: (details) {
                    if (_isContentPageOpen) {
                      if (details.primaryVelocity != null && details.primaryVelocity! > 300) {
                        debugPrint('Swipe right on bottom zone - closing content page');
                        _closeContentPage();
                      }
                      return;
                    }
                    if (details.primaryVelocity != null && details.primaryVelocity! < -500) {
                      _toggleBook();
                    } else if (details.primaryVelocity != null && details.primaryVelocity! > 500 && _isOpen) {
                      _toggleBook();
                    }
                  },
                  // DEBUG: sfondo arancione per visualizzare la swipe zone
                  child: Container(
                    color: Colors.orange.withOpacity(0.3),
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
