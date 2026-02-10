// =============================================================================
// BookSelectionWidget — Libro selezionabile nella schermata iniziale
// =============================================================================
//
// Rappresenta un singolo libro nella schermata di selezione livello
// (StartScreen). Ogni libro corrisponde a un livello scolastico
// (Medie, Superiori, Università).
//
// Funzionalità principali:
//   - Effetto 3D con sollevamento quando selezionato (rotazione X e
//     traslazione verso l'alto con animazione TweenAnimationBuilder).
//   - Ombra dinamica che si intensifica alla selezione.
//   - Texture personalizzata del libro con gradiente, dorso scuro,
//     imperfezioni e riflesso lucido (CustomPaint _BookTexturePainter).
//   - Icona decorativa centrale specifica per ogni livello scolastico.
//   - Icona mano animata sotto il libro selezionato per invitare al tap.
//
// Usato in: StartScreen (tre istanze, una per livello)
// =============================================================================

import 'package:flutter/material.dart';
import 'dart:math' as math;

/// Widget che rappresenta un libro selezionabile nella StartScreen
class BookSelectionWidget extends StatelessWidget {
  final bool isSelected;
  final Color bookColor;
  final String label;
  final VoidCallback onTap;

  const BookSelectionWidget({
    super.key,
    required this.isSelected,
    required this.bookColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return GestureDetector(
          onTap: onTap,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Libro con effetto 3D
              Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..translate(0.0, isSelected ? -20.0 : 0.0)
                  ..rotateX(value * 0.1),
                alignment: Alignment.center,
                child: Container(
                  width: 200,
                  height: 280,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: isSelected ? 25 : 15,
                        offset: Offset(0, isSelected ? 15 : 8),
                        spreadRadius: isSelected ? 3 : 0,
                      ),
                      BoxShadow(
                        color: bookColor.withOpacity(isSelected ? 0.4 : 0.2),
                        blurRadius: isSelected ? 30 : 15,
                        offset: Offset(0, isSelected ? 10 : 5),
                        spreadRadius: isSelected ? 5 : 0,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      children: [
                        // Background del libro con gradiente
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                bookColor,
                                bookColor.withOpacity(0.8),
                                bookColor.withOpacity(0.6),
                              ],
                            ),
                          ),
                        ),

                        // Texture libro
                        CustomPaint(
                          painter: _BookTexturePainter(color: bookColor),
                          child: Container(),
                        ),

                        // Dorso del libro (bordo sinistro scuro)
                        Positioned(
                          left: 0,
                          top: 0,
                          bottom: 0,
                          child: Container(
                            width: 25,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                                colors: [
                                  Colors.black.withOpacity(0.6),
                                  Colors.black.withOpacity(0.4),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Titolo del libro nella parte superiore
                        Positioned(
                          top: 40,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: Text(
                                label.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 2.0,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Decorazione centrale
                        Center(
                          child: SizedBox(
                            width: 100,
                            height: 100,
                            child: Image.asset(label.toLowerCase()=='medie' ? "assets/icons/icona_medie.png" : label.toLowerCase()=='superiori' ? "assets/icons/icona_superiori.png" : "assets/icons/icona_university.png",
                                scale: 8,
                                color: Colors.white.withOpacity(0.8)),
                          ),
                        ),

                        // Riflesso lucido
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white.withOpacity(0.2),
                                  Colors.transparent,
                                  Colors.transparent,
                                ],
                                stops: const [0.0, 0.3, 1.0],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Icona mano sotto il libro selezionato con animazione
              AnimatedOpacity(
                opacity: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: AnimatedScale(
                  scale: isSelected ? 1.0 : 0.5,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOutBack,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: isSelected ? 1.0 : 0.0),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeInOut,
                    builder: (context, animValue, child) {
                      return Transform.translate(
                        offset: Offset(0, math.sin(animValue * math.pi * 4) * 5),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: bookColor.withOpacity(0.4),
                                blurRadius: 15,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Image.asset(
                            'assets/image/open-hand.png',
                            width: 50,
                            height: 50,
                            fit: BoxFit.contain,
                            color: bookColor,
                          ),
                        ),
                      );
                    },
                    onEnd: () {},
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter per la texture del libro
class _BookTexturePainter extends CustomPainter {
  final Color color;

  _BookTexturePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(42);
    final paint = Paint()..style = PaintingStyle.fill;

    // Aggiungi piccole imperfezioni alla texture
    for (int i = 0; i < 30; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 2 + 0.5;
      final opacity = random.nextDouble() * 0.1 + 0.02;

      paint.color = Colors.white.withOpacity(opacity);
      canvas.drawCircle(Offset(x, y), radius, paint);
    }

    // Aggiungi linee decorative sottili
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withOpacity(0.1);

    for (int i = 0; i < 5; i++) {
      final x = random.nextDouble() * size.width;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
