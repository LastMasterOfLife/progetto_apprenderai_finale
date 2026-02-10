// =============================================================================
// OwlFaceWidget — Faccia del gufo Hooty con occhi animati
// =============================================================================
//
// Disegna la faccia della mascotte Hooty (gufo) con occhi che seguono il
// testo digitato dall'utente e battito di palpebre periodico.
//
// Componenti:
//   - Immagine di sfondo del gufo (assets/image/gufo.png).
//   - Due occhi bianchi circolari con pupille nere che si spostano
//     orizzontalmente in base al parametro eyeOffset (-0.8 a 0.8).
//   - Effetto battito palpebre (isBlinking): sovrappone un cerchio
//     color pelle che copre l'occhio, simulando la chiusura.
//   - Dimensione parametrizzabile (headSize) per uso in diversi contesti
//     (header chat, indicatore typing, messaggio vuoto).
//
// Include anche OwlEyeController (ChangeNotifier) che gestisce:
//   - Offset degli occhi aggiornato in base alla lunghezza del testo.
//   - Battito palpebre periodico ogni 3-6 secondi.
//
// Usato in: RightPageLayer (chat), LessonScreen, BookStackWidget
// =============================================================================

import 'package:flutter/material.dart';

/// Widget che visualizza la faccia del gufo mascotte con occhi animati
class OwlFaceWidget extends StatelessWidget {
  final double eyeOffset;
  final double headSize;
  final bool isBlinking;

  const OwlFaceWidget({
    super.key,
    required this.eyeOffset,
    this.headSize = 150,
    this.isBlinking = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: headSize,
      height: headSize,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // Testa del gufo con immagine
          Container(
            width: headSize,
            height: headSize,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage( 'assets/image/gufo.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Occhi animati
          Positioned(
            top: headSize * 0.3,
            left: headSize * 0.187,
            child: _buildOwlEye(),
          ),
          Positioned(
            top: headSize * 0.3,
            right: headSize * 0.187,
            child: _buildOwlEye(),
          ),

          // Effetto battito palpebre (se abilitato)
          if (isBlinking) ...[
            Positioned(
              top: headSize * 0.3,
              left: headSize * 0.187,
              child: _buildEyelid(),
            ),
            Positioned(
              top: headSize * 0.3,
              right: headSize * 0.187,
              child: _buildEyelid(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildOwlEye() {
    return Container(
      width: headSize * 0.267,
      height: headSize * 0.267,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
      child: AnimatedAlign(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment(eyeOffset, 0),
        child: Container(
          width: headSize * 0.093,
          height: headSize * 0.093,
          decoration: const BoxDecoration(
            color: Colors.black,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }

  Widget _buildEyelid() {
    return Container(
      width: headSize * 0.267,
      height: headSize * 0.267,
      decoration: BoxDecoration(
        color: const Color(0xFFD2691E),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );
  }
}

/// Controller per gestire lo stato degli occhi del gufo
class OwlEyeController extends ChangeNotifier {
  double _eyeOffset = 0.4;
  bool _isBlinking = false;

  double get eyeOffset => _eyeOffset;
  bool get isBlinking => _isBlinking;

  void updateEyeOffset(double offset) {
    _eyeOffset = offset.clamp(-0.8, 0.8);
    notifyListeners();
  }

  void blink() async {
    _isBlinking = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 150));

    _isBlinking = false;
    notifyListeners();
  }

  void startPeriodicBlinking() {
    Future.delayed(Duration(seconds: 3 + (DateTime.now().millisecond % 3)), () {
      if (_isBlinking) return;
      blink();
      startPeriodicBlinking();
    });
  }
}
