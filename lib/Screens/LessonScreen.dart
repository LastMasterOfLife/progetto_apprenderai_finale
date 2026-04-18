import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:progetto_finale/widget/BookStackWidget.dart';
import '../utils/app_enums.dart';
import '../utils/constants.dart';
import 'dart:math' as math;

class Lessonscreen extends StatefulWidget {
  const Lessonscreen({super.key});

  @override
  State<Lessonscreen> createState() => _LessonscreenState();
}

class _LessonscreenState extends State<Lessonscreen> {
  /// Indice capitoli formattato, passato a BookStackWidget
  String _chaptersIndex = "";

  /// true mentre è in corso il fetch dell'indice iniziale
  bool _isLoadingIndex = false;

  double sizeHeight(double percentage) =>
      MediaQuery.of(context).size.height * percentage;

  double sizeWidth(double percentage) =>
      MediaQuery.of(context).size.width * percentage;

  // ---------------------------------------------------------------------------
  // API: recupera indice capitoli
  // ---------------------------------------------------------------------------

  Future<void> _fetchChaptersIndex() async {
    if (_isLoadingIndex) return;
    setState(() => _isLoadingIndex = true);

    try {
      final response = await http.get(
        Uri.parse(ApiConstants.recuperaIndiceEndpoint),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String raw = data['answer'] ?? '';
        setState(() => _chaptersIndex = parseChaptersIndex(raw));
      } else {
        setState(() => _chaptersIndex = '');
        debugPrint('Indice capitoli: risposta HTTP ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _chaptersIndex = '');
      debugPrint('Errore fetch indice capitoli: $e');
    } finally {
      setState(() => _isLoadingIndex = false);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String schoolLevel = args['schoolLevel'] as String;

    // Carica l'indice una sola volta al primo build
    if (_chaptersIndex.isEmpty && !_isLoadingIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchChaptersIndex();
      });
    }

    return Scaffold(
      body: Stack(
        children: [
          // Sfondo carta vintage
          CustomPaint(
            size: Size.infinite,
            painter: _VintagePaperPainter(),
          ),

          Center(
            child: BookStackWidget(
              bookWidth: sizeWidth(0.40),
              bookHeight: sizeHeight(0.90),
              titleBook: schoolLevel.toLowerCase(),
              chaptersIndex: _chaptersIndex,
              isLoadingIndex: _isLoadingIndex,
            ),
          ),

          // Freccia back in alto a sinistra
          Positioned(
            top: 40,
            left: 16,
            child: SafeArea(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter per la texture carta vintage
// ---------------------------------------------------------------------------

class _VintagePaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      final opacity = random.nextDouble() * 0.1 + 0.02;
      paint.color = const Color(0xFF8B7355).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 30; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + random.nextDouble() * 100 - 50;
      final endY = startY + random.nextDouble() * 100 - 50;
      final opacity = random.nextDouble() * 0.05 + 0.01;
      linePaint.color = const Color(0xFF8B7355).withOpacity(opacity);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
    }

    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          const Color(0xFF8B7355).withOpacity(0.15),
        ],
        stops: const [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
