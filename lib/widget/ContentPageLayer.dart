// =============================================================================
// ContentPageLayer — Pagina contenuto di Hooty
// =============================================================================
//
// Mostra la risposta di Hooty come testo pulito sulla pagina sinistra del
// libro. Supporta tre modalità di visualizzazione tramite pannello laterale:
//   - notes: testo formattato (default)
//   - plainText: testo grezzo senza alcuna formattazione
//   - custom: container vuoto personalizzabile
//
// Il contenuto supporta la rotazione 3D (mirror quando la pagina è
// girata oltre 90°).
//
// Usato in: BookStackWidget
// =============================================================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' as math;

/// Modalità di visualizzazione della pagina sinistra
enum ContentViewMode {
  /// Testo formattato con titoli e paragrafi (default)
  notes,
  /// Testo grezzo senza alcuna formattazione
  plainText,
  /// Pagina vuota con container personalizzabile
  custom,
}

/// Widget per la pagina del contenuto dell'argomento (RAG)
class ContentPageLayer extends StatefulWidget {
  final double width;
  final double height;
  final Color color;
  final Color levelColor;
  final String chapterTitle;
  final String chapterContent;
  final bool isLoading;
  final double rotationY;
  final VoidCallback onBackPressed;

  const ContentPageLayer({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    required this.levelColor,
    required this.chapterTitle,
    required this.chapterContent,
    required this.isLoading,
    required this.rotationY,
    required this.onBackPressed,
  });

  @override
  State<ContentPageLayer> createState() => _ContentPageLayerState();
}

class _ContentPageLayerState extends State<ContentPageLayer>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _dotsController;
  late Animation<double> _pulseAnimation;

  /// Modalità corrente della pagina (default: notes = testo formattato)
  ContentViewMode _viewMode = ContentViewMode.notes;

  /// Stringa DOT ricevuta dall'API generate-map
  String _mapDotString = '';

  /// Stringa SVG generata da QuickChart a partire dal DOT
  String _mapSvgString = '';

  /// Stato di caricamento della mappa
  bool _isLoadingMap = false;

  /// Eventuale errore nella chiamata API della mappa
  String? _mapError;

  /// Tiene traccia dell'ultimo topic per cui è stata richiesta la mappa
  /// (evita chiamate duplicate)
  String _lastMapTopic = '';

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _dotsController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isFlipped = widget.rotationY > math.pi / 2;

    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          color: widget.color,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.all(16),
        child: isFlipped
            ? Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()..rotateY(math.pi),
                child: _buildContentPage(),
              )
            : _buildContentPage(),
      ),
    );
  }

  Widget _buildContentPage() {
    return Row(
      children: [
        // === PANNELLO LATERALE SINISTRO con icone ===
        _buildSidePanel(),
        // === CONTENUTO PRINCIPALE ===
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con titolo e bottone indietro
              Row(
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        debugPrint('Back button pressed');
                        widget.onBackPressed();
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: widget.levelColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_back,
                          color: widget.levelColor,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.chapterTitle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: widget.levelColor,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              // Contenuto — varia in base alla modalità
              Expanded(
                child: widget.isLoading
                    ? _buildLoadingAnimation()
                    : _buildContentForMode(),
              ),
              // Indicazione swipe per tornare indietro
              if (!widget.isLoading)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.swipe_left,
                        color: widget.levelColor.withOpacity(0.4),
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Swipe per tornare all\'indice',
                        style: TextStyle(
                          fontSize: 10,
                          color: widget.levelColor.withOpacity(0.4),
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  /// Pannello laterale sinistro con icone per cambiare modalità
  Widget _buildSidePanel() {
    return Container(
      width: 36,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: widget.levelColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: widget.levelColor.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icona 1: Testo pulito (senza formattazione)
          _buildSidePanelIcon(
            icon: Icons.text_snippet_outlined,
            tooltip: 'Testo semplice',
            isActive: _viewMode == ContentViewMode.plainText,
            onTap: () {
              setState(() {
                _viewMode = _viewMode == ContentViewMode.plainText
                    ? ContentViewMode.notes
                    : ContentViewMode.plainText;
              });
            },
          ),
          const SizedBox(height: 12),
          // Icona 2: Mappa concettuale
          _buildSidePanelIcon(
            icon: Icons.account_tree_outlined,
            tooltip: 'Mappa concettuale',
            isActive: _viewMode == ContentViewMode.custom,
            onTap: () {
              setState(() {
                _viewMode = _viewMode == ContentViewMode.custom
                    ? ContentViewMode.notes
                    : ContentViewMode.custom;
              });
              // Quando si attiva la vista mappa, lancia la chiamata API
              if (_viewMode == ContentViewMode.custom) {
                _fetchMap();
              }
            },
          ),
        ],
      ),
    );
  }

  /// Singola icona del pannello laterale
  Widget _buildSidePanelIcon({
    required IconData icon,
    required String tooltip,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive
                  ? widget.levelColor.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
              border: isActive
                  ? Border.all(color: widget.levelColor.withOpacity(0.4), width: 1)
                  : null,
            ),
            child: Icon(
              icon,
              size: 16,
              color: isActive
                  ? widget.levelColor
                  : widget.levelColor.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }

  /// Contenuto in base alla modalità selezionata
  Widget _buildContentForMode() {
    switch (_viewMode) {
      case ContentViewMode.notes:
        return _buildContent();
      case ContentViewMode.plainText:
        return _buildPlainTextContent();
      case ContentViewMode.custom:
        return _buildCustomContainer();
    }
  }

  // =====================================================================
  // API: generazione mappa concettuale
  // =====================================================================

  /// Flusso completo: genera DOT → converte in SVG → mostra.
  /// Viene invocata automaticamente quando si attiva la vista custom
  /// e il topic è cambiato rispetto all'ultima richiesta.
  Future<void> _fetchMap() async {
    final topic = widget.chapterTitle.trim();
    if (topic.isEmpty) return;

    // Evita chiamate duplicate per lo stesso argomento
    if (topic == _lastMapTopic && _mapSvgString.isNotEmpty) return;

    setState(() {
      _isLoadingMap = true;
      _mapError = null;
      _mapDotString = '';
      _mapSvgString = '';
    });

    try {
      // === STEP 1: Genera la stringa DOT dall'API ===
      final dotUrl = Uri.parse(
        'https://n8ndev.inforelea.academy/webhook-test/generate-map',
      );

      debugPrint('=== Map API Call (Step 1: DOT) ===');
      debugPrint('Topic: $topic');

      final dotResponse = await http.post(
        dotUrl,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'topic': topic,
          'depth': 3,
        }),
      );

      debugPrint('DOT Response status: ${dotResponse.statusCode}');

      if (dotResponse.statusCode != 200) {
        setState(() {
          _mapError = 'Errore generazione mappa (${dotResponse.statusCode})';
        });
        return;
      }

      final dotString = dotResponse.body;
      debugPrint('DOT ricevuto (${dotString.length} chars)');

      setState(() {
        _mapDotString = dotString;
      });

      // === STEP 2: Converti DOT in SVG tramite QuickChart ===
      final svgString = await _fetchSvgFromDot(dotString);

      if (svgString != null) {
        setState(() {
          _mapSvgString = svgString;
          _lastMapTopic = topic;
        });
      } else {
        setState(() {
          _mapError = 'Errore nella conversione DOT → SVG';
        });
      }
    } catch (e) {
      debugPrint('Errore nella chiamata API mappa: $e');
      setState(() {
        _mapError = 'Errore di connessione: $e';
      });
    } finally {
      setState(() {
        _isLoadingMap = false;
      });
    }
  }

  /// Converte una stringa DOT in SVG usando QuickChart.io
  Future<String?> _fetchSvgFromDot(String dotString) async {
    try {
      final url = Uri.parse('https://quickchart.io/graphviz');

      debugPrint('=== QuickChart API Call (Step 2: SVG) ===');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'graph': dotString,
          'layout': 'dot',
          'format': 'svg',
        }),
      );

      debugPrint('SVG Response status: ${response.statusCode}');
      debugPrint('SVG Response length: ${response.body.length}');

      if (response.statusCode == 200) {
        return response.body;
      } else {
        debugPrint('QuickChart error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Errore QuickChart: $e');
      return null;
    }
  }

  // =====================================================================
  // ANIMAZIONE DI CARICAMENTO
  // =====================================================================

  /// Animazione di caricamento — linee placeholder + testo pulsante
  Widget _buildLoadingAnimation() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _dotsController,
              builder: (context, child) {
                return _buildShimmerLines();
              },
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                // Punti animati: da 1 a 3
                final dotCount = (_dotsController.value * 3).floor() + 1;
                final dots = '.' * dotCount;

                return Opacity(
                  opacity: _pulseAnimation.value.clamp(0.4, 1.0),
                  child: Text(
                    'Hooty sta preparando la risposta$dots',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.levelColor.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Linee shimmer/placeholder durante il caricamento
  Widget _buildShimmerLines() {
    final rng = math.Random(42);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(8, (i) {
        // Larghezza variabile per simulare righe di testo
        final widthFraction = 0.5 + rng.nextDouble() * 0.45;
        // Opacità che pulsa leggermente in modo sfalsato per ogni riga
        final phase = (_dotsController.value + i * 0.12) % 1.0;
        final opacity = 0.08 + 0.08 * math.sin(phase * math.pi);

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: widthFraction,
            child: Container(
              height: 10,
              decoration: BoxDecoration(
                color: widget.levelColor.withOpacity(opacity),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        );
      }),
    );
  }

  // =====================================================================
  // CONTENUTO: testo formattato (default)
  // =====================================================================

  Widget _buildContent() {
    final sections = _parseToSections(widget.chapterContent);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...sections.map((section) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titolo sezione
                    if (section.title.isNotEmpty) ...[
                      Text(
                        section.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: widget.levelColor,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    // Paragrafi della sezione
                    ...section.paragraphs.map((paragraph) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          paragraph,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black.withOpacity(0.8),
                            height: 1.7,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // =====================================================================
  // CONTENUTO: testo grezzo (plainText)
  // =====================================================================

  /// Vista testo grezzo — risposta di Hooty senza alcuna formattazione
  Widget _buildPlainTextContent() {
    final plainText = _cleanMarkdown(widget.chapterContent);

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          plainText,
          style: TextStyle(
            fontSize: 12,
            color: Colors.black.withOpacity(0.8),
            height: 1.7,
          ),
        ),
      ),
    );
  }

  // =====================================================================
  // CONTENUTO: container custom
  // =====================================================================

  /// Container per la mappa concettuale — mostra loading, errore o DOT ricevuto
  Widget _buildCustomContainer() {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: widget.levelColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: _buildMapContent(),
    );
  }

  /// Contenuto del container mappa in base allo stato corrente
  Widget _buildMapContent() {
    // === LOADING ===
    if (_isLoadingMap) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                color: widget.levelColor,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 14),
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                final dotCount = (_dotsController.value * 3).floor() + 1;
                final dots = '.' * dotCount;
                return Opacity(
                  opacity: _pulseAnimation.value.clamp(0.4, 1.0),
                  child: Text(
                    'Generazione mappa concettuale$dots',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.levelColor.withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      );
    }

    // === ERRORE ===
    if (_mapError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red.withOpacity(0.6),
                size: 32,
              ),
              const SizedBox(height: 10),
              Text(
                _mapError!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.red.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _fetchMap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: widget.levelColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Riprova',
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.levelColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // === NESSUN DATO (non ancora richiesto) ===
    if (_mapSvgString.isEmpty && _mapDotString.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_tree_outlined,
                color: widget.levelColor.withOpacity(0.3),
                size: 40,
              ),
              const SizedBox(height: 10),
              Text(
                'Nessuna mappa disponibile.\nSeleziona un argomento per generarla.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: widget.levelColor.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // === SVG RICEVUTO — rendering grafico con pan/zoom ===
    if (_mapSvgString.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: InteractiveViewer(
          constrained: false,
          boundaryMargin: const EdgeInsets.all(100),
          minScale: 0.2,
          maxScale: 4.0,
          child: SvgPicture.string(
            _mapSvgString,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    // === Fallback: DOT ricevuto ma SVG non ancora generato ===
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.warning_amber_outlined,
            color: Colors.orange.withOpacity(0.6),
            size: 32,
          ),
          const SizedBox(height: 10),
          Text(
            'Mappa DOT ricevuta ma conversione SVG fallita.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.orange.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                // Riprova solo la conversione SVG
                setState(() {
                  _isLoadingMap = true;
                  _mapError = null;
                });
                _fetchSvgFromDot(_mapDotString).then((svg) {
                  setState(() {
                    _isLoadingMap = false;
                    if (svg != null) {
                      _mapSvgString = svg;
                    } else {
                      _mapError = 'Conversione SVG fallita';
                    }
                  });
                });
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: widget.levelColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Riprova conversione',
                  style: TextStyle(
                    fontSize: 12,
                    color: widget.levelColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================================
  // PARSING: da markdown a sezioni con titoli e paragrafi
  // =====================================================================

  List<_TextSection> _parseToSections(String content) {
    final sections = <_TextSection>[];
    String currentTitle = '';
    final currentParagraphs = <String>[];

    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#')) {
        // Nuova sezione: salva la precedente
        if (currentTitle.isNotEmpty || currentParagraphs.isNotEmpty) {
          sections.add(_TextSection(
            title: currentTitle,
            paragraphs: List.from(currentParagraphs),
          ));
          currentParagraphs.clear();
        }
        currentTitle = trimmed.replaceAll(RegExp(r'^#+\s*'), '').trim();
      } else {
        // Riga di testo — rimuovi solo la sintassi markdown
        final cleaned = _cleanMarkdown(trimmed);
        if (cleaned.isNotEmpty) {
          currentParagraphs.add(cleaned);
        }
      }
    }

    // Ultima sezione
    if (currentTitle.isNotEmpty || currentParagraphs.isNotEmpty) {
      sections.add(_TextSection(
        title: currentTitle,
        paragraphs: List.from(currentParagraphs),
      ));
    }

    // Fallback se nessuna sezione trovata
    if (sections.isEmpty) {
      sections.add(_TextSection(
        title: '',
        paragraphs: [content.substring(0, math.min(500, content.length))],
      ));
    }

    return sections;
  }

  String _cleanMarkdown(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'_+'), '')
        .replaceAll(RegExp(r'`+'), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1')
        .replaceFirst(RegExp(r'^[-*•]\s*'), '')
        .trim();
  }
}

// =======================================================================
// MODELLI DATI
// =======================================================================

class _TextSection {
  final String title;
  final List<String> paragraphs;

  const _TextSection({required this.title, required this.paragraphs});
}
