// =============================================================================
// BookLayer — Singola pagina dello stack del libro
// =============================================================================
//
// Rappresenta un singolo foglio nella pila del libro. Può funzionare in
// due modalità:
//
//   - Pagina semplice (indiceBook = false): foglio bianco decorativo con
//     effetto luce, dorso (spine) e ombra. Usata come layer intermedio
//     per dare profondità visiva allo stack.
//
//   - Pagina indice (indiceBook = true): mostra l'elenco dei capitoli
//     raggruppati per materia (formato "SUBJECT:NomeMateria"), con
//     argomenti cliccabili, linea punteggiata e numero pagina.
//     Supporta la rotazione 3D (mirror del contenuto quando girato).
//
// Il contenuto dell'indice viene fornito come stringa con righe separate
// da '\n'. Le righe che iniziano con "SUBJECT:" sono trattate come
// intestazioni di materia, le altre come argomenti selezionabili.
//
// Usato in: BookStackWidget (sia come layer decorativi che come indice)
// =============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'BookPainters.dart';

/// Singolo layer dello stack (pagina bianca o pagina indice)
class BookLayer extends StatelessWidget {
  final bool indiceBook;
  final double width;
  final double height;
  final Color color;
  final bool showSpine;
  final String chaptersIndex;
  final Color levelColor;
  final Function(String)? onChapterSelected;
  final double rotationY;

  const BookLayer({
    super.key,
    required this.width,
    required this.height,
    required this.color,
    this.showSpine = true,
    this.indiceBook = false,
    this.chaptersIndex = '',
    this.levelColor = Colors.black,
    this.onChapterSelected,
    this.rotationY = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (!indiceBook) {
      return Container(
        width: width,
        height: height,
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
        child: Stack(
          children: [
            // Corpo principale del libro
            Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),

            // Dorso del libro (spine) - bordo sinistro più scuro
            if (showSpine)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 8,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Color(0xFF150A09).withOpacity(0.6),
                        Color(0xFF3E2723).withOpacity(0.4),
                        Colors.transparent,
                      ],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(4),
                      bottomLeft: Radius.circular(4),
                    ),
                  ),
                ),
              ),

            // Effetto luce sulla copertina
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.15),
                      Colors.transparent,
                      Colors.black.withOpacity(0.1),
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      // Pagina indice con argomenti cliccabili e tabulazione
      final bool isFlipped = rotationY > math.pi / 2;

      return Container(
        width: width,
        height: height,
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
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.all(16),
          child: isFlipped
              ? Transform(
                  alignment: Alignment.center,
                  transform: Matrix4.identity()..rotateY(math.pi),
                  child: _buildIndexContent(),
                )
              : _buildIndexContent(),
        ),
      );
    }
  }

  Widget _buildIndexContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Indice
        Text(
          'Indice',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: levelColor,
          ),
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 8),
        // Lista capitoli
        Expanded(
          child: chaptersIndex.isEmpty
              ? Center(
                  child: Text(
                    'Caricamento indice...',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.black54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              : _buildChaptersListWidget(),
        ),
      ],
    );
  }

  /// Costruisce la lista dei capitoli con tabulazione e argomenti cliccabili
  Widget _buildChaptersListWidget() {
    final chapters = chaptersIndex
        .split('\n')
        .where((c) => c.trim().isNotEmpty)
        .toList();

    int pageNumber = 0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(chapters.length, (index) {
          final line = chapters[index].trim();

          // Verifica se è un marcatore di materia (SUBJECT:)
          if (line.startsWith('SUBJECT:')) {
            final subjectName = line.substring('SUBJECT:'.length);
            return Padding(
              padding: const EdgeInsets.only(top: 14.0, bottom: 6.0),
              child: Text(
                subjectName,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: levelColor,
                  height: 1.4,
                ),
              ),
            );
          } else {
            // È un argomento - incrementa numero pagina e mostra con indentazione
            pageNumber++;
            final currentPageNumber = pageNumber;
            final bool isClickable = onChapterSelected != null;

            return Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: isClickable
                      ? () {
                          debugPrint('Capitolo selezionato: $line');
                          onChapterSelected!(line);
                        }
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  splashColor: levelColor.withOpacity(0.25),
                  highlightColor: levelColor.withOpacity(0.12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 8.0,
                      horizontal: 8.0,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: isClickable
                          ? Border.all(
                              color: levelColor.withOpacity(0.08),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Row(
                      children: [
                        // Titolo argomento
                        Expanded(
                          child: Text(
                            line,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                              height: 1.4,
                              fontWeight: isClickable ? FontWeight.w400 : FontWeight.w400,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Linea punteggiata
                        Expanded(
                          flex: 0,
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: CustomPaint(
                              painter: DottedLinePainter(),
                              child: const SizedBox(width: 16, height: 1),
                            ),
                          ),
                        ),
                        // Numero pagina
                        Text(
                          currentPageNumber.toString(),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.black54,
                          ),
                        ),
                        // Freccia indicatore (solo se cliccabile)
                        if (isClickable) ...[
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right,
                            size: 16,
                            color: levelColor.withOpacity(0.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          }
        }),
      ),
    );
  }
}
