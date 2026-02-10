// =============================================================================
// BookPainters — Painter personalizzati per gli elementi grafici del libro
// =============================================================================
//
// Contiene i CustomPainter e widget di supporto per il rendering visivo:
//
//   - DottedLinePainter: disegna una linea punteggiata orizzontale, usata
//     nell'indice tra il titolo del capitolo e il numero di pagina.
//
//   - BookmarkTabPainter: disegna la linguetta del segnalibro con forma
//     a chevron (V invertita) sul fondo, ombra e highlight quando attivo.
//     Usato da RightPageLayer per i tab Note e Chat.
//
//   - FoldedCornerPainter: effetto angolo piegato sulle note adesive
//     (sticky notes), simula un foglietto con l'angolo ripiegato.
//
//   - TypingDotsWidget: widget animato con tre pallini che pulsano,
//     usato come indicatore "sta scrivendo..." nella chat con Hooty.
//
// Usato in: BookLayer, RightPageLayer
// =============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Custom painter per disegnare linea punteggiata tra titolo e numero pagina
class DottedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 2.0;
    const dashSpace = 2.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Custom painter for bookmark tab with inverted V (chevron) bottom
class BookmarkTabPainter extends CustomPainter {
  final Color color;
  final bool isActive;
  final Color shadowColor;

  BookmarkTabPainter({
    required this.color,
    required this.isActive,
    required this.shadowColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = shadowColor
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    final vHeight = 14.0;
    final bodyHeight = size.height - vHeight;

    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, bodyHeight)
      ..lineTo(size.width / 2, bodyHeight + vHeight)
      ..lineTo(0, bodyHeight)
      ..close();

    canvas.drawPath(path.shift(const Offset(1, 2)), shadowPaint);
    canvas.drawPath(path, paint);

    if (isActive) {
      final highlightPaint = Paint()
        ..color = Colors.white.withOpacity(0.4)
        ..style = PaintingStyle.fill;
      final highlightPath = Path()
        ..moveTo(2, 0)
        ..lineTo(size.width - 2, 0)
        ..lineTo(size.width - 2, 3)
        ..lineTo(2, 3)
        ..close();
      canvas.drawPath(highlightPath, highlightPaint);
    }
  }

  @override
  bool shouldRepaint(covariant BookmarkTabPainter oldDelegate) =>
      color != oldDelegate.color || isActive != oldDelegate.isActive;
}

/// Custom painter for folded corner effect on sticky notes
class FoldedCornerPainter extends CustomPainter {
  final Color color;

  FoldedCornerPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final foldColor = Color.lerp(color, Colors.black, 0.15)!;

    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(path, Paint()..color = foldColor);

    final shadowPath = Path()
      ..moveTo(0, size.height)
      ..lineTo(size.width, 0)
      ..lineTo(size.width - 2, 2)
      ..lineTo(2, size.height)
      ..close();

    canvas.drawPath(
      shadowPath,
      Paint()
        ..color = Colors.black.withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );
  }

  @override
  bool shouldRepaint(covariant FoldedCornerPainter oldDelegate) =>
      color != oldDelegate.color;
}

/// Animated typing dots widget
class TypingDotsWidget extends StatefulWidget {
  final Color color;
  const TypingDotsWidget({super.key, required this.color});

  @override
  State<TypingDotsWidget> createState() => _TypingDotsWidgetState();
}

class _TypingDotsWidgetState extends State<TypingDotsWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = (_controller.value + i * 0.3) % 1.0;
            final opacity = (math.sin(phase * math.pi)).clamp(0.3, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Opacity(
                opacity: opacity,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: widget.color, shape: BoxShape.circle),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
