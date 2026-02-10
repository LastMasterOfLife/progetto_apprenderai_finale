// =============================================================================
// FullScreenVideo — Video di sfondo a schermo intero per la SplashScreen
// =============================================================================
//
// Riproduce il video "libri_volanti.mp4" a schermo intero come sfondo
// animato della schermata di caricamento (SplashScreen).
//
// Caratteristiche:
//   - Il video si avvia automaticamente in loop senza audio (volume = 0).
//   - Nessun controllo video visibile (NoVideoControls).
//   - IgnorePointer attivo per evitare che tap o click interferiscano
//     con la UI sovrapposta.
//   - Usa media_kit per la riproduzione multipiattaforma.
//
// Usato in: SplashScreen
// =============================================================================

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class FullScreenVideo extends StatefulWidget {
  const FullScreenVideo({super.key});

  @override
  State<FullScreenVideo> createState() => _FullScreenVideoState();
}

class _FullScreenVideoState extends State<FullScreenVideo> {
  late final Player player;
  late final VideoController controller;

  @override
  void initState() {
    super.initState();
    // se il player esiste già, deve solo far ripartire l'audio e il video

    player = Player();
    controller = VideoController(player);

    player.open(Media('asset:///assets/video/libri_volanti.mp4'));
    player.setPlaylistMode(PlaylistMode.loop);
    player.setVolume(0);
    player.play();
  }

  @override
  void dispose() {
    player.pause();
    player.setVolume(0);
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child: IgnorePointer( // 🔥 evita click/tap e overlay che appare al mouse
              ignoring: true,
              child: Video(
                controller: controller,
                fit: BoxFit.cover,
                // 🔥 forza “nessun controllo”
                controls: NoVideoControls,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
