// =============================================================================
// ContentPageLayer — Pagina "appunti di Hooty"
// =============================================================================
//
// Mostra la risposta di Hooty come appunti scritti a mano su una pagina
// del libro, con frecce, cerchi, sottolineature, box e scarabocchi
// disegnati tramite CustomPainter per simulare note prese su carta.
//
// Il contenuto supporta la rotazione 3D (mirror quando la pagina è
// girata oltre 90°).
//
// Usato in: BookStackWidget
// =============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Modalità di visualizzazione della pagina sinistra
enum ContentViewMode {
  /// Appunti scritti a mano (default) con decorazioni
  notes,
  /// Testo pulito senza decorazioni markdown
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
  late AnimationController _writeController;
  late Animation<double> _pulseAnimation;

  /// Modalità corrente della pagina (default: notes = appunti decorati)
  ContentViewMode _viewMode = ContentViewMode.notes;

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

    _writeController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _writeController.dispose();
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
          // Icona 1: Testo pulito (senza decorazioni)
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
          // Icona 2: Pagina vuota / container custom
          _buildSidePanelIcon(
            icon: Icons.dashboard_customize_outlined,
            tooltip: 'Pagina personalizzata',
            isActive: _viewMode == ContentViewMode.custom,
            onTap: () {
              setState(() {
                _viewMode = _viewMode == ContentViewMode.custom
                    ? ContentViewMode.notes
                    : ContentViewMode.custom;
              });
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

  /// Vista testo pulito — risposta di Hooty senza decorazioni markdown
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

  /// Pagina vuota con container personalizzabile
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
      // TODO: Personalizza questo container come preferisci
      child: const SizedBox.expand(),
    );
  }

  /// Animazione di caricamento - Hooty sta scrivendo gli appunti
  Widget _buildLoadingAnimation() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: AnimatedBuilder(
              animation: _writeController,
              builder: (context, child) {
                return CustomPaint(
                  painter: _LoadingScribblePainter(
                    progress: _writeController.value,
                    color: widget.levelColor,
                  ),
                  child: const SizedBox.expand(),
                );
              },
            ),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _pulseAnimation.value.clamp(0.4, 1.0),
                  child: Text(
                    'Hooty sta prendendo appunti...',
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

  // =====================================================================
  // PARSING: da markdown a sezioni strutturate
  // =====================================================================

  List<_NoteSection> _parseToNoteSections(String content) {
    final sections = <_NoteSection>[];
    String currentTitle = '';
    final currentItems = <_NoteItem>[];

    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('#')) {
        if (currentTitle.isNotEmpty || currentItems.isNotEmpty) {
          sections.add(_NoteSection(
            title: currentTitle.isNotEmpty ? currentTitle : 'Appunti',
            items: List.from(currentItems),
          ));
          currentItems.clear();
        }
        currentTitle = trimmed.replaceAll(RegExp(r'^#+\s*'), '').trim();
      } else if (trimmed.startsWith('- ') ||
          trimmed.startsWith('* ') ||
          trimmed.startsWith('• ')) {
        final text = trimmed.replaceFirst(RegExp(r'^[-*•]\s*'), '').trim();
        if (text.isNotEmpty) {
          currentItems.add(_NoteItem(
            text: _cleanMarkdown(text),
            type: _NoteItemType.bullet,
          ));
        }
      } else if (trimmed.contains('**')) {
        final boldPattern = RegExp(r'\*\*(.+?)\*\*');
        final matches = boldPattern.allMatches(trimmed);
        if (matches.isNotEmpty) {
          for (final match in matches) {
            final kw = match.group(1)?.trim() ?? '';
            if (kw.isNotEmpty && kw.length < 80) {
              currentItems.add(_NoteItem(
                text: kw,
                type: _NoteItemType.keyword,
              ));
            }
          }
          // Aggiungi anche il testo completo ripulito come contesto
          final fullText = _cleanMarkdown(trimmed);
          if (fullText.length > 20) {
            currentItems.add(_NoteItem(
              text: fullText,
              type: _NoteItemType.note,
            ));
          }
        } else {
          currentItems.add(_NoteItem(
            text: _cleanMarkdown(trimmed),
            type: _NoteItemType.note,
          ));
        }
      } else {
        final cleaned = _cleanMarkdown(trimmed);
        if (cleaned.length <= 50) {
          currentItems.add(_NoteItem(text: cleaned, type: _NoteItemType.keyword));
        } else {
          currentItems.add(_NoteItem(text: cleaned, type: _NoteItemType.note));
        }
      }
    }

    if (currentTitle.isNotEmpty || currentItems.isNotEmpty) {
      sections.add(_NoteSection(
        title: currentTitle.isNotEmpty ? currentTitle : 'Concetti chiave',
        items: List.from(currentItems),
      ));
    }

    if (sections.isEmpty) {
      sections.add(_NoteSection(
        title: widget.chapterTitle,
        items: [
          _NoteItem(
            text: content.substring(0, math.min(200, content.length)),
            type: _NoteItemType.note,
          )
        ],
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
        .trim();
  }

  // =====================================================================
  // BUILD: Pagina stile "appunti scritti a mano"
  // =====================================================================

  Widget _buildContent() {
    final sections = _parseToNoteSections(widget.chapterContent);
    final rng = math.Random(widget.chapterContent.hashCode);

    // Colori "penna" per le sezioni
    final penColors = [
      widget.levelColor,
      const Color(0xFF1A237E), // blu scuro
      const Color(0xFF4A148C), // viola
      const Color(0xFFB71C1C), // rosso
      const Color(0xFF004D40), // teal scuro
      const Color(0xFFE65100), // arancione
    ];

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...sections.asMap().entries.map((entry) {
            final idx = entry.key;
            final section = entry.value;
            final penColor = penColors[idx % penColors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: _buildHandwrittenSection(section, penColor, rng, idx),
            );
          }),
        ],
      ),
    );
  }

  /// Sezione scritta a mano con titolo cerchiato/sottolineato e items
  Widget _buildHandwrittenSection(
      _NoteSection section, Color penColor, math.Random rng, int sectionIdx) {
    // Tipo di decorazione titolo: alterna cerchio, rettangolo, sottolineatura
    final titleDecoType = sectionIdx % 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // === TITOLO con decorazione "scarabocchiata" ===
        _buildHandwrittenTitle(section.title, penColor, titleDecoType, rng),
        const SizedBox(height: 10),
        // === ITEMS ===
        ...section.items.asMap().entries.map((e) {
          final itemIdx = e.key;
          final item = e.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildHandwrittenItem(item, penColor, rng, itemIdx),
          );
        }),
        // Freccia di connessione verso la sezione successiva
        if (sectionIdx < 5) // massimo 5 frecce
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: CustomPaint(
              painter: _ConnectionArrowPainter(
                color: penColor.withOpacity(0.3),
                seed: sectionIdx,
              ),
              child: const SizedBox(width: double.infinity, height: 20),
            ),
          ),
      ],
    );
  }

  /// Titolo con decorazione "a mano" — cerchiato, boxato o sottolineato
  Widget _buildHandwrittenTitle(
      String title, Color penColor, int decoType, math.Random rng) {
    return CustomPaint(
      painter: _TitleDecorationPainter(
        type: decoType,
        color: penColor,
        seed: title.hashCode,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: penColor,
            letterSpacing: 1.2,
            height: 1.3,
          ),
        ),
      ),
    );
  }

  /// Singolo item degli appunti
  Widget _buildHandwrittenItem(
      _NoteItem item, Color penColor, math.Random rng, int idx) {
    switch (item.type) {
      case _NoteItemType.keyword:
        return _buildKeywordNote(item.text, penColor, rng, idx);
      case _NoteItemType.bullet:
        return _buildBulletNote(item.text, penColor, idx);
      case _NoteItemType.note:
        return _buildTextNote(item.text, penColor, idx);
    }
  }

  /// Keyword: box disegnato a mano con testo dentro
  Widget _buildKeywordNote(
      String text, Color penColor, math.Random rng, int idx) {
    final slight = (rng.nextDouble() - 0.5) * 2.0; // rotazione leggera

    return Transform.rotate(
      angle: slight * 0.015,
      child: CustomPaint(
        painter: _HanddrawnBoxPainter(
          color: penColor,
          seed: idx + text.hashCode,
          filled: idx % 3 == 0,
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Piccolo simbolo disegnato a mano
              CustomPaint(
                painter: _SmallDoodlePainter(
                  type: idx % 4,
                  color: penColor,
                ),
                child: const SizedBox(width: 14, height: 14),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: penColor.withOpacity(0.9),
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Bullet: freccia disegnata a mano + testo
  Widget _buildBulletNote(String text, Color penColor, int idx) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Freccia/simbolo disegnato a mano
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: CustomPaint(
              painter: _HanddrawnArrowPainter(
                color: penColor,
                seed: idx,
              ),
              child: const SizedBox(width: 18, height: 14),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.5,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Testo note: con sottolineatura ondulata se importanti
  Widget _buildTextNote(String text, Color penColor, int idx) {
    final isShort = text.length < 60;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 4),
      child: CustomPaint(
        painter: isShort
            ? _WavyUnderlinePainter(
                color: penColor.withOpacity(0.2),
                seed: idx,
              )
            : null,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withOpacity(0.75),
              height: 1.6,
            ),
          ),
        ),
      ),
    );
  }
}

// =======================================================================
// CUSTOM PAINTERS — Effetti "scritti a mano"
// =======================================================================

/// Painter per lo scarabocchio animato durante il caricamento
class _LoadingScribblePainter extends CustomPainter {
  final double progress;
  final Color color;

  _LoadingScribblePainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rng = math.Random(42);

    // Disegna linee "scarabocchio" che si scrivono progressivamente
    for (int i = 0; i < 8; i++) {
      final y = 20.0 + i * (size.height - 40) / 8;
      final lineProgress = ((progress * 10 - i) / 2.0).clamp(0.0, 1.0);
      if (lineProgress <= 0) continue;

      final path = Path();
      final startX = 10.0 + rng.nextDouble() * 20;
      final endX = size.width * (0.5 + rng.nextDouble() * 0.45) * lineProgress;

      path.moveTo(startX, y);
      for (double x = startX; x < endX; x += 8) {
        final wobble = (rng.nextDouble() - 0.5) * 3;
        path.lineTo(x, y + wobble);
      }

      canvas.drawPath(path, paint);

      // Ogni tanto un cerchietto o stellina
      if (i % 3 == 0 && lineProgress > 0.5) {
        final cx = 10.0 + rng.nextDouble() * 30;
        canvas.drawCircle(
          Offset(cx, y),
          4 + rng.nextDouble() * 3,
          paint..strokeWidth = 1.2,
        );
        paint.strokeWidth = 1.5;
      }
    }

    // Box scarabocchiato al centro
    final boxProgress = ((progress * 3) - 1).clamp(0.0, 1.0);
    if (boxProgress > 0) {
      final boxPaint = Paint()
        ..color = color.withOpacity(0.15)
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;

      final bx = size.width * 0.15;
      final by = size.height * 0.35;
      final bw = size.width * 0.7 * boxProgress;
      final bh = 50.0;

      final boxPath = Path();
      // Rettangolo leggermente storto
      boxPath.moveTo(bx + 2, by - 1);
      boxPath.lineTo(bx + bw - 3, by + 2);
      boxPath.lineTo(bx + bw + 1, by + bh - 2);
      boxPath.lineTo(bx - 1, by + bh + 1);
      boxPath.close();

      canvas.drawPath(boxPath, boxPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _LoadingScribblePainter oldDelegate) =>
      progress != oldDelegate.progress;
}

/// Decorazione titolo: 0=cerchio, 1=rettangolo, 2=sottolineatura
class _TitleDecorationPainter extends CustomPainter {
  final int type;
  final Color color;
  final int seed;

  _TitleDecorationPainter({
    required this.type,
    required this.color,
    required this.seed,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final rng = math.Random(seed);

    switch (type) {
      case 0:
        // Cerchio/ovale a mano libera attorno al testo
        _drawHanddrawnEllipse(canvas, size, paint, rng);
        break;
      case 1:
        // Rettangolo a mano libera
        _drawHanddrawnRect(canvas, size, paint, rng);
        break;
      case 2:
        // Doppia sottolineatura ondulata
        _drawHanddrawnUnderline(canvas, size, paint, rng);
        break;
    }
  }

  void _drawHanddrawnEllipse(
      Canvas canvas, Size size, Paint paint, math.Random rng) {
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final rx = size.width / 2 + 4;
    final ry = size.height / 2 + 4;

    for (int i = 0; i <= 36; i++) {
      final angle = (i / 36) * 2 * math.pi;
      final wobble = (rng.nextDouble() - 0.5) * 3;
      final x = cx + (rx + wobble) * math.cos(angle);
      final y = cy + (ry + wobble) * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawHanddrawnRect(
      Canvas canvas, Size size, Paint paint, math.Random rng) {
    final path = Path();
    final w = (rng.nextDouble() - 0.5) * 2; // wobble

    path.moveTo(-4 + w, -3 + w);
    path.lineTo(size.width + 4 - w, -2 + w);
    path.lineTo(size.width + 3 + w, size.height + 3 - w);
    path.lineTo(-3 - w, size.height + 4 + w);
    path.close();

    canvas.drawPath(path, paint);
  }

  void _drawHanddrawnUnderline(
      Canvas canvas, Size size, Paint paint, math.Random rng) {
    // Prima linea
    final path1 = Path();
    path1.moveTo(0, size.height + 2);
    for (double x = 0; x < size.width; x += 6) {
      final wobble = (rng.nextDouble() - 0.5) * 2;
      path1.lineTo(x, size.height + 2 + wobble);
    }
    canvas.drawPath(path1, paint);

    // Seconda linea (leggermente sotto)
    final path2 = Path();
    path2.moveTo(4, size.height + 6);
    for (double x = 4; x < size.width - 8; x += 6) {
      final wobble = (rng.nextDouble() - 0.5) * 2;
      path2.lineTo(x, size.height + 6 + wobble);
    }
    canvas.drawPath(path2, paint..strokeWidth = 1.5);
  }

  @override
  bool shouldRepaint(covariant _TitleDecorationPainter oldDelegate) =>
      type != oldDelegate.type || color != oldDelegate.color;
}

/// Box disegnato a mano attorno alle keyword
class _HanddrawnBoxPainter extends CustomPainter {
  final Color color;
  final int seed;
  final bool filled;

  _HanddrawnBoxPainter({
    required this.color,
    required this.seed,
    this.filled = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()
      ..color = color.withOpacity(filled ? 0.08 : 0.25)
      ..strokeWidth = 1.5
      ..style = filled ? PaintingStyle.fill : PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    final w = (rng.nextDouble() - 0.5) * 2;

    // Rettangolo con angoli leggermente imprecisi
    path.moveTo(-2 + w, -1 + w * 0.5);
    path.lineTo(size.width + 2 - w, -2 + w);
    path.lineTo(size.width + 1 + w * 0.5, size.height + 2 - w);
    path.lineTo(-1 - w * 0.5, size.height + 1 + w);
    path.close();

    canvas.drawPath(path, paint);

    // Se riempito, disegna anche il bordo
    if (filled) {
      canvas.drawPath(
        path,
        Paint()
          ..color = color.withOpacity(0.25)
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _HanddrawnBoxPainter oldDelegate) =>
      color != oldDelegate.color || seed != oldDelegate.seed;
}

/// Freccia disegnata a mano per i bullet
class _HanddrawnArrowPainter extends CustomPainter {
  final Color color;
  final int seed;

  _HanddrawnArrowPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final arrowType = seed % 4;

    final paint = Paint()
      ..color = color.withOpacity(0.7)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final w = (rng.nextDouble() - 0.5) * 1.5;

    switch (arrowType) {
      case 0:
        // Freccia → classica
        final path = Path()
          ..moveTo(0, size.height / 2 + w)
          ..lineTo(size.width - 5, size.height / 2 - w)
          ..moveTo(size.width - 8, size.height / 2 - 4 + w)
          ..lineTo(size.width - 3, size.height / 2 - w)
          ..lineTo(size.width - 8, size.height / 2 + 4 + w);
        canvas.drawPath(path, paint);
        break;
      case 1:
        // Pallino pieno
        canvas.drawCircle(
          Offset(size.width / 2, size.height / 2),
          4,
          paint..style = PaintingStyle.fill,
        );
        break;
      case 2:
        // Asterisco *
        final cx = size.width / 2;
        final cy = size.height / 2;
        for (int i = 0; i < 3; i++) {
          final angle = i * math.pi / 3;
          canvas.drawLine(
            Offset(cx + 5 * math.cos(angle), cy + 5 * math.sin(angle)),
            Offset(cx - 5 * math.cos(angle), cy - 5 * math.sin(angle)),
            paint..style = PaintingStyle.stroke,
          );
        }
        break;
      case 3:
        // Trattino ondulato ~
        final path = Path()..moveTo(2, size.height / 2);
        for (double x = 2; x < size.width - 2; x += 4) {
          final y =
              size.height / 2 + math.sin(x * 0.8) * 3 + w;
          path.lineTo(x, y);
        }
        canvas.drawPath(path, paint);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _HanddrawnArrowPainter oldDelegate) =>
      seed != oldDelegate.seed;
}

/// Piccoli scarabocchi/simboli accanto alle keyword
class _SmallDoodlePainter extends CustomPainter {
  final int type;
  final Color color;

  _SmallDoodlePainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.5)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 1;

    switch (type) {
      case 0:
        // Stellina
        final path = Path();
        for (int i = 0; i < 5; i++) {
          final angle = (i * 4 * math.pi / 5) - math.pi / 2;
          final x = cx + r * math.cos(angle);
          final y = cy + r * math.sin(angle);
          if (i == 0) {
            path.moveTo(x, y);
          } else {
            path.lineTo(x, y);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
        break;
      case 1:
        // Rombo
        final path = Path()
          ..moveTo(cx, cy - r)
          ..lineTo(cx + r, cy)
          ..lineTo(cx, cy + r)
          ..lineTo(cx - r, cy)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case 2:
        // Cerchietto
        canvas.drawCircle(Offset(cx, cy), r, paint);
        break;
      case 3:
        // Quadratino
        canvas.drawRect(
          Rect.fromCenter(center: Offset(cx, cy), width: r * 2, height: r * 2),
          paint,
        );
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _SmallDoodlePainter oldDelegate) =>
      type != oldDelegate.type;
}

/// Freccia di connessione tra sezioni
class _ConnectionArrowPainter extends CustomPainter {
  final Color color;
  final int seed;

  _ConnectionArrowPainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(seed);
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final style = seed % 3;

    switch (style) {
      case 0:
        // Freccia curva verso il basso
        final path = Path();
        final startX = 20.0 + rng.nextDouble() * 30;
        path.moveTo(startX, 2);
        path.quadraticBezierTo(
          startX + 30,
          size.height + 5,
          startX + 60,
          size.height - 2,
        );
        // Punta
        path.moveTo(startX + 55, size.height - 7);
        path.lineTo(startX + 62, size.height - 2);
        path.lineTo(startX + 55, size.height + 2);
        canvas.drawPath(path, paint);
        break;
      case 1:
        // Linea tratteggiata orizzontale con freccia
        final y = size.height / 2;
        for (double x = 10; x < size.width * 0.4; x += 8) {
          canvas.drawLine(Offset(x, y), Offset(x + 4, y), paint);
        }
        break;
      case 2:
        // Tre puntini verticali ⋮
        for (int i = 0; i < 3; i++) {
          canvas.drawCircle(
            Offset(25, 3.0 + i * 7),
            2,
            paint..style = PaintingStyle.fill,
          );
        }
        paint.style = PaintingStyle.stroke;
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _ConnectionArrowPainter oldDelegate) =>
      seed != oldDelegate.seed;
}

/// Sottolineatura ondulata per il testo
class _WavyUnderlinePainter extends CustomPainter {
  final Color color;
  final int seed;

  _WavyUnderlinePainter({required this.color, required this.seed});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height - 1);

    for (double x = 0; x < size.width; x += 6) {
      final y = size.height - 1 + math.sin(x * 0.5 + seed) * 2;
      path.lineTo(x, y);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _WavyUnderlinePainter oldDelegate) =>
      seed != oldDelegate.seed;
}

// =======================================================================
// MODELLI DATI
// =======================================================================

enum _NoteItemType { keyword, bullet, note }

class _NoteItem {
  final String text;
  final _NoteItemType type;

  const _NoteItem({required this.text, required this.type});
}

class _NoteSection {
  final String title;
  final List<_NoteItem> items;

  const _NoteSection({required this.title, required this.items});
}
