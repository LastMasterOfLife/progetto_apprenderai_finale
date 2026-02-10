import 'package:flutter/material.dart';
import 'package:progetto_finale/widget/FullScreenVideo.dart';
import 'dart:math' as math;

class Splashscreen extends StatefulWidget {
  const Splashscreen({super.key});

  @override
  State<Splashscreen> createState() => _SplashscreenState();
}

class _SplashscreenState extends State<Splashscreen> with TickerProviderStateMixin {
  double sizeHeight(double percentage) =>
      MediaQuery.of(context).size.height * percentage;

  double sizeWidth(double percentage) =>
      MediaQuery.of(context).size.width * percentage;

  bool _isHovering = false;

  late AnimationController _logoController;
  late AnimationController _particleController;
  late AnimationController _typewriterController;

  late Animation<double> _logoFadeAnimation;
  late Animation<double> _logoScaleAnimation;

  String _displayedText = "";
  final String _fullText = "Ti AIutiamo a superare i tuoi limiti";

  @override
  void initState() {
    super.initState();

    // Animazione logo: fade-in + scale
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _logoScaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    // Animazione particelle luminose
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Animazione typewriter per il testo (con loop e reverse)
    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _fullText.length * 50),
    );

    _typewriterController.addListener(() {
      final progress = _typewriterController.value;
      final charCount = (_fullText.length * progress).floor();
      setState(() {
        _displayedText = _fullText.substring(0, charCount);
      });
    });

    _typewriterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Quando l'animazione completa, aspetta un po' e poi torna indietro
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) {
            _typewriterController.reverse();
          }
        });
      } else if (status == AnimationStatus.dismissed) {
        // Quando torna all'inizio, aspetta un po' e riparte
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) {
            _typewriterController.forward();
          }
        });
      }
    });

    // Avvia le animazioni in sequenza
    _logoController.forward().then((_) {
      _typewriterController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1️⃣ BACKGROUND VIDEO
          Container(
            height: double.infinity,
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFFDA5D5),
                  Color(0xFF53EAFD),
                  Color(0xFF7BF1A8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          const Align(
            alignment: Alignment.center,
            child: FullScreenVideo(),
          ),

          // 2️⃣ LOGO CON ANIMAZIONE FADE-IN + SCALE
          Align(
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _logoController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _logoFadeAnimation.value,
                      child: Transform.scale(
                        scale: _logoScaleAnimation.value,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.3 * _logoFadeAnimation.value),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset(
                            "assets/image/logo.png",
                            scale: 2.0,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),

                // 3️⃣ TESTO CON TYPEWRITER EFFECT
                AnimatedBuilder(
                  animation: _typewriterController,
                  builder: (context, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _displayedText,
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            shadows: [
                              Shadow(
                                offset: Offset(2.0, 2.0),
                                blurRadius: 8.0,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                        ),
                        // Cursore lampeggiante (sempre visibile durante l'animazione)
                        AnimatedBuilder(
                          animation: _particleController,
                          builder: (context, child) {
                            return Opacity(
                              opacity: (_particleController.value * 2) % 1.0 > 0.5 ? 1.0 : 0.0,
                              child: Container(
                                width: 2,
                                height: 24,
                                color: Colors.white,
                                margin: const EdgeInsets.only(left: 2),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),

          // 4️⃣ PULSANTE IN BASSO AL CENTRO
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: sizeHeight(0.08)),
              child: GestureDetector(
                onTap: () {
                  Navigator.pushNamed(context, '/start');
                },
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovering = true),
                  onExit: (_) => setState(() => _isHovering = false),
                  child: AnimatedScale(
                    scale: _isHovering ? 1.08 : 1.0,
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 50,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF00B8DB), Color(0xFFAD46FF)],
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                        ),
                        borderRadius: BorderRadius.circular(40),
                        boxShadow: [
                          BoxShadow(
                            color: _isHovering
                                ? Colors.white.withOpacity(0.6)
                                : Colors.black26,
                            blurRadius: _isHovering ? 20 : 6,
                            spreadRadius: _isHovering ? 2 : 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "Clicca qui per iniziare",
                            style: TextStyle(
                              fontSize: 28,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(
                            Icons.star_outline_outlined,
                            size: 30,
                            color: Colors.white,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
