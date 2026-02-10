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
import 'package:flutter_markdown/flutter_markdown.dart';
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

  /// Contenuto effettivo quando caricato (con supporto Markdown)
  Widget _buildContent() {
    return Markdown(
      data: widget.chapterContent,
      shrinkWrap: true,
      physics: const ClampingScrollPhysics(),
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          height: 1.6,
        ),
        h1: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: widget.levelColor,
        ),
        h2: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: widget.levelColor,
        ),
        h3: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: widget.levelColor,
        ),
        strong: const TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        em: const TextStyle(
          fontStyle: FontStyle.italic,
          color: Colors.black87,
        ),
        listBullet: TextStyle(
          fontSize: 13,
          color: widget.levelColor,
        ),
        blockquote: TextStyle(
          fontSize: 13,
          color: Colors.black54,
          fontStyle: FontStyle.italic,
        ),
        blockquoteDecoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              color: widget.levelColor.withOpacity(0.5),
              width: 3,
            ),
          ),
        ),
        code: TextStyle(
          fontSize: 12,
          backgroundColor: widget.levelColor.withOpacity(0.1),
          color: Colors.black87,
        ),
      ),
    );
  }
}
