// =============================================================================
// SplashScreen — Schermata di avvio con animazione logo e typewriter
// =============================================================================
//
// Prima schermata mostrata all'avvio. Gestisce tre casi:
//   1. Login disabilitato (AppConfig.enableLogin = false) → va direttamente
//      a StartScreen, bypassa completamente il flusso di autenticazione.
//   2. Utente non autenticato → naviga a LoginScreen.
//   3. Utente autenticato con livello salvato → naviga direttamente a
//      LessonScreen, saltando StartScreen.
//   4. Utente autenticato senza livello → naviga a StartScreen.
//
// Visualizza:
//   - Gradient background + video in loop (FullScreenVideo)
//   - Logo animato con fade-in e scale (AnimationController)
//   - Testo typewriter animato (bidirezionale, loop infinito)
//   - Cursore lampeggiante sincronizzato con _particleController
//   - Pulsante CTA principale con gradiente brand cyan→purple
//   - Icona "Cambia profilo" in alto a destra (solo se autenticato)
//
// Classe esportata: SplashScreen
// =============================================================================

import 'package:flutter/material.dart';
import '../widgets/full_screen_video.dart';
import '../utils/user_preferences.dart';
import '../utils/app_enums.dart';
import '../config/app_config.dart';

/// Schermata di avvio con animazione logo, typewriter e CTA.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
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

  /// Profilo salvato — null = primo avvio
  SchoolLevel? _savedLevel;
  bool _isAuthenticated = false;

  /// true mentre leggiamo le preferenze all'avvio (evita flash di UI)
  bool _isCheckingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadSavedProfile();

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

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _typewriterController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _fullText.length * 50),
    );

    _typewriterController.addListener(() {
      final charCount =
          (_fullText.length * _typewriterController.value).floor();
      setState(() => _displayedText = _fullText.substring(0, charCount));
    });

    _typewriterController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) _typewriterController.reverse();
        });
      } else if (status == AnimationStatus.dismissed) {
        Future.delayed(const Duration(milliseconds: 500), () {
          if (mounted) _typewriterController.forward();
        });
      }
    });

    _logoController.forward().then((_) => _typewriterController.forward());
  }

  @override
  void dispose() {
    _logoController.dispose();
    _particleController.dispose();
    _typewriterController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedProfile() async {
    final level = await UserPreferences.getSavedSchoolLevel();
    final loggedIn = await UserPreferences.isLoggedIn();
    final guest = await UserPreferences.isGuest();
    if (mounted) {
      setState(() {
        _savedLevel = level;
        _isAuthenticated = loggedIn || guest;
        _isCheckingProfile = false;
      });
    }
  }

  /// Naviga in base allo stato. Se [AppConfig.enableLogin] è false,
  /// va direttamente a StartScreen bypassando il login.
  Future<void> _onStartPressed() async {
    if (_isCheckingProfile) return;

    if (!AppConfig.enableLogin) {
      Navigator.pushNamed(context, '/start');
      return;
    }

    if (!_isAuthenticated) {
      Navigator.pushNamed(context, '/login');
    } else if (_savedLevel != null) {
      Navigator.pushNamed(
        context,
        '/lesson',
        arguments: {'schoolLevel': _savedLevel!.routeArgument},
      );
    } else {
      Navigator.pushNamed(context, '/start');
    }
  }

  Future<void> _resetProfile() async {
    await UserPreferences.clearLoginState();
    if (mounted) {
      setState(() {
        _savedLevel = null;
        _isAuthenticated = false;
      });
      Navigator.pushNamed(context, '/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
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

          // Logo + typewriter
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
                                color: Colors.white.withOpacity(
                                    0.3 * _logoFadeAnimation.value),
                                blurRadius: 30,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Image.asset("assets/image/logo.png",
                              scale: 2.0),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
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
                        AnimatedBuilder(
                          animation: _particleController,
                          builder: (context, child) {
                            return Opacity(
                              opacity:
                                  (_particleController.value * 2) % 1.0 > 0.5
                                      ? 1.0
                                      : 0.0,
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

          // CTA pulsante principale
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(bottom: sizeHeight(0.08)),
              child: GestureDetector(
                onTap: _onStartPressed,
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
                          vertical: 12, horizontal: 50),
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

          // Icona "Cambia profilo" — visibile solo se autenticato
          if (_isAuthenticated)
            Positioned(
              top: 48,
              right: 16,
              child: SafeArea(
                child: Tooltip(
                  message: 'Cambia profilo',
                  child: Material(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      onTap: _resetProfile,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.swap_horiz,
                                color: Colors.white, size: 18),
                            const SizedBox(width: 6),
                            Text(
                              'Cambia profilo',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
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
