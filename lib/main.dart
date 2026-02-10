import 'package:flutter/material.dart';
import 'package:progetto_finale/Screens/LessonScreen.dart';
import 'package:progetto_finale/Screens/SplashScreen.dart';
import 'package:progetto_finale/Screens/StartScreen.dart';
import 'package:media_kit/media_kit.dart';

void main() {
  MediaKit.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),

      // rotta iniziale
      initialRoute: '/',

      // mappa delle rotte
      routes: {
        '/': (context) => const Splashscreen(),
        '/start': (context) => const Startscreen(),
        '/lesson': (context) => const Lessonscreen(),
      },
    );
  }
}
