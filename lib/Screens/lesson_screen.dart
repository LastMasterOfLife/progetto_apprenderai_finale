// =============================================================================
// LessonScreen — Schermata principale della lezione interattiva
// =============================================================================
//
// Contiene il libro interattivo (BookStackWidget) su sfondo carta vintage.
// Riceve il livello scolastico come argomento di route e lo passa al widget.
//
// Al build iniziale avvia il fetch dell'indice tramite ApiService (nessun
// http.post diretto in questo file). L'indice viene passato a BookStackWidget
// che lo visualizza nella pagina indice del libro.
//
// Struttura:
//   - AppSidebar a sinistra (navigazione)
//   - Area destra: texture carta vintage (solo in light mode) + BookStackWidget
//
// Classe esportata: LessonScreen
// =============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../widgets/book_stack_widget.dart';
import '../utils/app_stats.dart';
import '../utils/user_preferences.dart';
import '../widgets/app_sidebar.dart';
import '../services/api_service.dart';

/// Schermata della lezione interattiva con libro 3D e chat AI.
class LessonScreen extends StatefulWidget {
  const LessonScreen({super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  /// Punto di accesso unico al backend.
  final _api = const ApiService();

  String _chaptersIndex = "";
  bool _isLoadingIndex = false;

  // ---------------------------------------------------------------------------
  // API: recupera indice capitoli
  // ---------------------------------------------------------------------------

  Future<void> _fetchChaptersIndex() async {
    if (_isLoadingIndex) return;
    setState(() => _isLoadingIndex = true);

    try {
      final index = await _api.fetchChaptersIndex();
      setState(() => _chaptersIndex = index);
    } on ApiException catch (e) {
      debugPrint(
          'Indice capitoli: risposta HTTP ${e.statusCode} — ${e.message}');
      setState(() => _chaptersIndex = '');
    } catch (e) {
      debugPrint('Errore fetch indice capitoli: $e');
      setState(() => _chaptersIndex = '');
    } finally {
      setState(() => _isLoadingIndex = false);
    }
  }

  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Impostazioni'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading:
                  const Icon(Icons.arrow_back, color: Color(0xFF6366F1)),
              title: const Text('Torna alla selezione livello'),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Esci / Cambia profilo',
                  style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(ctx);
                await UserPreferences.clearLoginState();
                if (!context.mounted) return;
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Chiudi'),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String schoolLevel = args['schoolLevel'] as String;

    // Avvia il fetch dell'indice al primo build (una sola volta)
    if (_chaptersIndex.isEmpty && !_isLoadingIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _fetchChaptersIndex();
      });
    }

    return Scaffold(
      body: Row(
        children: [
          AppSidebar(
            currentRoute: SidebarRoute.dashboard,
            onNavigate: (route) {
              switch (route) {
                case SidebarRoute.dashboard:
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacementNamed(context, '/start');
                  }
                case SidebarRoute.groups:
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                          'Sezione Gruppi — disponibile prossimamente'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                case SidebarRoute.settings:
                  _showSettingsDialog(context);
              }
            },
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isDark =
                    Theme.of(context).brightness == Brightness.dark;
                return Stack(
                  children: [
                    // Texture carta vintage solo in light mode
                    if (!isDark)
                      CustomPaint(
                        size: Size.infinite,
                        painter: _VintagePaperPainter(),
                      ),
                    Center(
                      child: BookStackWidget(
                        bookWidth: constraints.maxWidth * 0.40,
                        bookHeight: constraints.maxHeight * 0.90,
                        titleBook: schoolLevel.toLowerCase(),
                        chaptersIndex: _chaptersIndex,
                        isLoadingIndex: _isLoadingIndex,
                        onChapterSelected: (chapter) =>
                            AppStats.recordTopicSearch(chapter),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _VintagePaperPainter — texture carta invecchiata (light mode only)
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
