// =============================================================================
// main.dart — Punto di ingresso dell'applicazione ApprenderAI
// =============================================================================
//
// Inizializza MediaKit, carica il tema salvato (ThemeNotifier) e avvia
// MaterialApp con routing dichiarativo.
//
// Route map:
//   /         → SplashScreen  (schermata di avvio con animazione)
//   /login    → LoginScreen   (form email + password o accesso ospite)
//   /start    → StartScreen   (dashboard selezione livello scolastico)
//   /lesson   → LessonScreen  (libro interattivo, richiede args schoolLevel)
//
// Funzionalità aggiuntive:
//   - Badge DEV sovrapposto a tutto lo schermo in modalità sviluppo
//     (AppConfig.isDev = true), che mostra la versione e la build mode.
//   - ThemeMode reattivo: ValueListenableBuilder ricostruisce MaterialApp
//     ogni volta che l'utente cambia tema (chiaro / scuro / sistema).
// =============================================================================

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/start_screen.dart';
import 'screens/lesson_screen.dart';
import 'config/app_config.dart';
import 'config/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  // Carica il tema salvato prima di mostrare qualsiasi schermata
  themeNotifier = await ThemeNotifier.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Ricostruisce MaterialApp ogni volta che l'utente cambia tema
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (_, mode, __) {
        return MaterialApp(
          title: 'ApprenderAI',
          debugShowCheckedModeBanner: AppConfig.isDev,

          // ── Temi ─────────────────────────────────────────────────────────
          themeMode: mode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,

          // Rotta iniziale
          initialRoute: '/',

          // Mappa delle rotte
          routes: {
            '/':       (context) => const SplashScreen(),
            '/login':  (context) => const LoginScreen(),
            '/start':  (context) => const StartScreen(),
            '/lesson': (context) => const LessonScreen(),
          },

          // Badge DEV sovrapposto a tutto lo schermo (solo in isDev)
          builder: AppConfig.isDev
              ? (context, child) => Stack(
                    children: [
                      child!,
                      Positioned(
                        top: 0,
                        left: 0,
                        child: IgnorePointer(
                          child: SafeArea(
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                '⚙ ${AppConfig.buildMode} v${AppConfig.version}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
              : null,
        );
      },
    );
  }
}
