import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:progetto_finale/widget/BookStackWidget.dart';
import 'package:progetto_finale/widget/OwlFaceWidget.dart';
import '../utils/ChatMessage.dart';
import 'dart:math' as math;

class Lessonscreen extends StatefulWidget {
  const Lessonscreen({super.key});

  @override
  State<Lessonscreen> createState() => _LessonscreenState();
}

class _LessonscreenState extends State<Lessonscreen> with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scroll = ScrollController();
  final OwlEyeController _owlController = OwlEyeController();

  bool _isTyping = false;
  bool _isBookOpen = false;
  String _chaptersIndex = ""; // Indice capitoli dalla API (formato MATERIA|ARGOMENTO|SOTTO_ARGOMENTO)

  late AnimationController _animationController;
  late Animation<double> _openAnimation;

  double sizeHeight(double percentage) =>
      MediaQuery.of(context).size.height * percentage;

  double sizeWidth(double percentage) =>
      MediaQuery.of(context).size.width * percentage;

  @override
  void initState() {
    super.initState();

    // Inizializza l'animazione di apertura del libro
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _openAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    // Listener per movimento occhi
    _controller.addListener(() {
      _owlController.updateEyeOffset(
        ((_controller.text.length % 10 - 5) / 5).clamp(-0.8, 0.8),
      );
    });
  }

  void _openBook() {
    setState(() {
      _isBookOpen = true;
    });
    _animationController.forward();
  }

  void _closeBook() {
    _animationController.reverse().then((_) {
      setState(() {
        _isBookOpen = false;
      });
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _scroll.dispose();
    _owlController.dispose();
    super.dispose();
  }

  Future<void> apiCallIndicecapitoli(String schoolLevel) async {
    setState(() {
      _isTyping = true;
    });

    try {
      // Chiamata GET all'endpoint /recupera_indice
      var url = Uri.parse('http://127.0.0.1:5000/recupera_indice');
      var response = await http.get(url);

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String rawResponse = data['answer'] ?? "";

        // Parse del formato MATERIA|ARGOMENTO|SOTTO_ARGOMENTO e raggruppa per materia
        final lines = rawResponse.split('\n');
        final Map<String, List<String>> groupedBySubject = {};

        // Salta la prima riga (header)
        for (int i = 1; i < lines.length; i++) {
          final parts = lines[i].split('|');
          if (parts.length == 3) {
            final materia = parts[0].trim();
            // final argomento = parts[1].trim(); // Non più usato nell'indice
            String sottoArgomento = parts[2].trim();

            // Estrai solo la prima parte prima dei ":" (es. "Gioconda: Descrizione..." -> "Gioconda")
            if (sottoArgomento.contains(':')) {
              sottoArgomento = sottoArgomento.split(':').first.trim();
            }

            // Raggruppa per materia - mostra solo il sotto-argomento pulito
            if (!groupedBySubject.containsKey(materia)) {
              groupedBySubject[materia] = [];
            }
            // Aggiungi solo se non è già presente (evita duplicati)
            if (!groupedBySubject[materia]!.contains(sottoArgomento)) {
              groupedBySubject[materia]!.add(sottoArgomento);
            }
          }
        }

        // Formatta in modo gerarchico con marcatori speciali
        final List<String> formattedChapters = [];
        groupedBySubject.forEach((materia, argomenti) {
          formattedChapters.add('SUBJECT:$materia'); // Marcatore per materia
          formattedChapters.addAll(argomenti);
        });

        setState(() {
          _chaptersIndex = formattedChapters.join('\n');
        });
      }

    } catch (e) {
      debugPrint('Errore nella chiamata API: $e');
    } finally {
      setState(() {
        _isTyping = false;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: MessageRole.user,
        text: text,
        createdAt: DateTime.now(),
      ));
      _isTyping = true;
    });

    _scrollToBottom();

    // Simula risposta AI
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _messages.add(ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: MessageRole.assistant,
        text: "Grazie per il tuo messaggio! Sto elaborando la risposta...",
        createdAt: DateTime.now(),
      ));
      _isTyping = false;
    });

    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String schoolLevel = args['schoolLevel'].toUpperCase();

    // Carica l'indice dei capitoli all'avvio (solo la prima volta)
    if (_chaptersIndex.isEmpty && !_isTyping) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        apiCallIndicecapitoli(schoolLevel);
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
          //Container(
          //  decoration: BoxDecoration(
          //    image: DecorationImage(
          //      image: AssetImage("assets/backgrounds/library.jpg"),
          //      fit: BoxFit.cover,
          //    ),
          //  ),
          //),
          Center(
              child: BookStackWidget(
                bookWidth: sizeWidth(0.40),
                bookHeight: sizeHeight(0.90),
                titleBook: schoolLevel.toLowerCase(),
                chaptersIndex: _chaptersIndex,
              )
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
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
          ),

        ],
      )

    );
  }
}

/// Custom painter per creare texture carta vintage
class _VintagePaperPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Disegna macchie casuali per effetto carta invecchiata
    for (int i = 0; i < 100; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 3 + 1;
      final opacity = random.nextDouble() * 0.1 + 0.02;

      paint.color = Color(0xFF8B7355).withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Aggiungi linee sottili per texture fibre della carta
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    for (int i = 0; i < 30; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final endX = startX + random.nextDouble() * 100 - 50;
      final endY = startY + random.nextDouble() * 100 - 50;
      final opacity = random.nextDouble() * 0.05 + 0.01;

      linePaint.color = Color(0xFF8B7355).withOpacity(opacity);
      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), linePaint);
    }

    // Aggiungi vignettatura ai bordi
    final vignettePaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          Color(0xFF8B7355).withOpacity(0.15),
        ],
        stops: [0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), vignettePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
