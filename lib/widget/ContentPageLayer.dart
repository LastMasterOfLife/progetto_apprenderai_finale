// =============================================================================
// ContentPageLayer — Pagina del contenuto dell'argomento selezionato
// =============================================================================
//
// Mostra il contenuto di un capitolo recuperato dal backend RAG. Quando
// l'utente seleziona un argomento dall'indice, questa pagina si apre con
// un'animazione di rotazione 3D e visualizza:
//
//   - Header con bottone "indietro" e titolo del capitolo.
//   - Animazione di caricamento: righe che si "scrivono" progressivamente
//     sulla pagina, simulando l'effetto scrittura su carta.
//   - Contenuto in formato Markdown (flutter_markdown) con stili
//     personalizzati per titoli, grassetto, corsivo, citazioni e codice.
//   - Indicazione swipe in basso per tornare all'indice.
//
// Il contenuto supporta la rotazione 3D (mirror quando la pagina è
// girata oltre 90°).
//
// Usato in: BookStackWidget
// =============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;

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
    return Column(
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
        // Contenuto
        Expanded(
          child: widget.isLoading ? _buildLoadingAnimation() : _buildContent(),
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
    );
  }

  /// Animazione di caricamento - righe che si scrivono come su una pagina
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
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ..._buildParagraphLines(0, [1.0, 0.95, 0.88, 0.92, 0.7]),
                    const SizedBox(height: 16),
                    ..._buildParagraphLines(5, [0.85, 0.92, 0.78, 0.95, 0.65]),
                    const SizedBox(height: 16),
                    ..._buildParagraphLines(10, [0.9, 0.82, 0.88, 0.5]),
                  ],
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
                    'Caricamento in corso...',
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

  List<Widget> _buildParagraphLines(int startIndex, List<double> widths) {
    return List.generate(widths.length, (index) {
      final globalIndex = startIndex + index;
      final delay = globalIndex * 0.05;
      final progress = ((_writeController.value - delay) / 0.4).clamp(0.0, 1.0);

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _buildAnimatedLine(
          progress: progress,
          widthFactor: widths[index],
        ),
      );
    });
  }

  Widget _buildAnimatedLine({required double progress, required double widthFactor}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth * widthFactor;
        return Container(
          height: 12,
          width: maxWidth * progress,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            gradient: LinearGradient(
              colors: [
                widget.levelColor.withOpacity(0.3),
                widget.levelColor.withOpacity(0.15),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Parsa il contenuto markdown e estrae sezioni con parole chiave raggruppate
  List<_ContentSection> _parseContentToSections(String content) {
    final sections = <_ContentSection>[];
    String currentTitle = '';
    final currentKeywords = <String>[];

    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Riconosce header markdown (## o ### o #)
      if (trimmed.startsWith('#')) {
        // Salva la sezione precedente se ha contenuto
        if (currentTitle.isNotEmpty || currentKeywords.isNotEmpty) {
          sections.add(_ContentSection(
            title: currentTitle.isNotEmpty ? currentTitle : 'Informazioni',
            keywords: List.from(currentKeywords),
          ));
          currentKeywords.clear();
        }
        currentTitle = trimmed.replaceAll(RegExp(r'^#+\s*'), '').trim();
      } else if (trimmed.startsWith('- ') || trimmed.startsWith('* ') || trimmed.startsWith('• ')) {
        // Bullet point → parola chiave
        final keyword = trimmed.replaceFirst(RegExp(r'^[-*•]\s*'), '').trim();
        if (keyword.isNotEmpty) {
          currentKeywords.add(keyword);
        }
      } else if (trimmed.contains('**')) {
        // Testo con grassetto → estrai le parti in grassetto come keywords
        final boldPattern = RegExp(r'\*\*(.+?)\*\*');
        final matches = boldPattern.allMatches(trimmed);
        if (matches.isNotEmpty) {
          for (final match in matches) {
            final keyword = match.group(1)?.trim() ?? '';
            if (keyword.isNotEmpty && keyword.length < 80) {
              currentKeywords.add(keyword);
            }
          }
        } else {
          // Se non ci sono grassetti, estrai frasi brevi come keyword
          _extractKeywordsFromText(trimmed, currentKeywords);
        }
      } else {
        // Testo normale → estrai concetti chiave
        _extractKeywordsFromText(trimmed, currentKeywords);
      }
    }

    // Aggiungi l'ultima sezione
    if (currentTitle.isNotEmpty || currentKeywords.isNotEmpty) {
      sections.add(_ContentSection(
        title: currentTitle.isNotEmpty ? currentTitle : 'Concetti chiave',
        keywords: List.from(currentKeywords),
      ));
    }

    // Se non abbiamo trovato sezioni strutturate, crea una sezione unica
    if (sections.isEmpty) {
      final allKeywords = <String>[];
      _extractKeywordsFromText(content, allKeywords);
      sections.add(_ContentSection(
        title: widget.chapterTitle,
        keywords: allKeywords.isNotEmpty ? allKeywords : [content.substring(0, math.min(200, content.length))],
      ));
    }

    return sections;
  }

  /// Estrae frasi significative da un testo come parole chiave
  void _extractKeywordsFromText(String text, List<String> keywords) {
    // Rimuovi markdown inline
    final cleaned = text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'_+'), '')
        .replaceAll(RegExp(r'`+'), '')
        .trim();

    if (cleaned.isEmpty) return;

    // Se la frase è corta, usala direttamente
    if (cleaned.length <= 60) {
      keywords.add(cleaned);
    } else {
      // Dividi in frasi e prendi quelle significative
      final sentences = cleaned.split(RegExp(r'[.;:!?]+'));
      for (final sentence in sentences) {
        final s = sentence.trim();
        if (s.length >= 5 && s.length <= 80) {
          keywords.add(s);
        } else if (s.length > 80) {
          // Tronca frasi troppo lunghe
          keywords.add('${s.substring(0, 77)}...');
        }
      }
    }
  }

  /// Contenuto strutturato come schema logico di parole chiave raggruppate
  Widget _buildContent() {
    final sections = _parseContentToSections(widget.chapterContent);

    // Colori per le diverse sezioni (ciclici)
    final sectionColors = [
      widget.levelColor,
      widget.levelColor.withOpacity(0.8),
      HSLColor.fromColor(widget.levelColor).withHue(
        (HSLColor.fromColor(widget.levelColor).hue + 30) % 360
      ).toColor(),
      HSLColor.fromColor(widget.levelColor).withHue(
        (HSLColor.fromColor(widget.levelColor).hue + 60) % 360
      ).toColor(),
      HSLColor.fromColor(widget.levelColor).withHue(
        (HSLColor.fromColor(widget.levelColor).hue - 30) % 360
      ).toColor(),
    ];

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icona schema
          Row(
            children: [
              Icon(Icons.account_tree, size: 16, color: widget.levelColor.withOpacity(0.5)),
              const SizedBox(width: 6),
              Text(
                'Schema logico — Risposta di Hooty',
                style: TextStyle(
                  fontSize: 10,
                  color: widget.levelColor.withOpacity(0.5),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sezioni raggruppate
          ...sections.asMap().entries.map((entry) {
            final index = entry.key;
            final section = entry.value;
            final sectionColor = sectionColors[index % sectionColors.length];

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildSectionBlock(section, sectionColor),
            );
          }),
        ],
      ),
    );
  }

  /// Costruisce un blocco sezione con titolo e parole chiave come tag
  Widget _buildSectionBlock(_ContentSection section, Color sectionColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: sectionColor, width: 3),
        ),
      ),
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titolo sezione
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: sectionColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: sectionColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Parole chiave come tag/chip
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: section.keywords.map((keyword) {
              return _buildKeywordChip(keyword, sectionColor);
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Costruisce un singolo chip/tag per una parola chiave
  Widget _buildKeywordChip(String keyword, Color color) {
    // Se la keyword è breve (< 30 char) → chip compatto
    // Se è lunga → box informativo
    final isLong = keyword.length > 35;

    if (isLong) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withOpacity(0.15), width: 0.5),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(Icons.arrow_right, size: 14, color: color.withOpacity(0.5)),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                keyword,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.black87,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.5),
      ),
      child: Text(
        keyword,
        style: TextStyle(
          fontSize: 11,
          color: color.withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// Modello per una sezione di contenuto con titolo e parole chiave
class _ContentSection {
  final String title;
  final List<String> keywords;

  const _ContentSection({
    required this.title,
    required this.keywords,
  });
}
