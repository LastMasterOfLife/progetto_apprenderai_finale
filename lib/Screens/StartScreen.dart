import 'package:flutter/material.dart';
import 'package:progetto_finale/widget/BookSelectionWidget.dart';

class Startscreen extends StatefulWidget {
  const Startscreen({super.key});

  @override
  State<Startscreen> createState() => _StartscreenState();
}

class _StartscreenState extends State<Startscreen> with TickerProviderStateMixin {
  sizeHeight(double percentage) {
    return MediaQuery.of(context).size.height * percentage;
  }

  sizeWidth(double percentage) {
    return MediaQuery.of(context).size.width * percentage;
  }

  bool isSelectedMedia = true;
  bool isSelectedSuperior = false;
  bool isSelectedUniversity = false;

  late AnimationController _backgroundController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();

    // Animazione background animato
    _backgroundController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Animazione pulse per il pulsante
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _backgroundController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _getBackgroundImage() {
    if (isSelectedMedia) {
      return 'assets/backgrounds/green_nature.jpg';
    } else if (isSelectedSuperior) {
      return 'assets/backgrounds/blue_study.jpg';
    } else if (isSelectedUniversity) {
      return 'assets/backgrounds/red_sunset.jpg';
    }
    return 'assets/backgrounds/green_nature.jpg';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image dinamico basato sul livello selezionato
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            child: Container(
              key: ValueKey<String>(_getBackgroundImage()),
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(_getBackgroundImage()),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),

          // Overlay scuro per migliorare la leggibilità
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.3),
                  Colors.black.withOpacity(0.5),
                ],
              ),
            ),
          ),

          // Contenuto principale
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: sizeWidth(0.01)),

              // Titolo
              Text(
                'che tipo di studente sei?',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.8),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                    Shadow(
                      color: isSelectedMedia
                          ? Colors.green
                          : isSelectedSuperior
                              ? Colors.blue
                              : isSelectedUniversity
                                  ? Colors.red
                                  : Colors.white,
                      blurRadius: 40,
                      offset: const Offset(0, 0),
                    ),
                  ],
                ),
              ),

              // Libri selezionabili
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  BookSelectionWidget(
                    isSelected: isSelectedMedia,
                    bookColor: const Color(0xFF4CAF50), // Verde
                    label: 'Medie',
                    onTap: () {
                      setState(() {
                        isSelectedMedia = true;
                        isSelectedSuperior = false;
                        isSelectedUniversity = false;
                      });
                    },
                  ),
                  BookSelectionWidget(
                    isSelected: isSelectedSuperior,
                    bookColor: const Color(0xFF2196F3), // Blu
                    label: 'Superiori',
                    onTap: () {
                      setState(() {
                        isSelectedMedia = false;
                        isSelectedSuperior = true;
                        isSelectedUniversity = false;
                      });
                    },
                  ),
                  BookSelectionWidget(
                    isSelected: isSelectedUniversity,
                    bookColor: const Color(0xFFE53935), // Rosso
                    label: 'Università',
                    onTap: () {
                      setState(() {
                        isSelectedMedia = false;
                        isSelectedSuperior = false;
                        isSelectedUniversity = true;
                      });
                    },
                  ),
                ],
              ),

              // Pulsante con animazione pulse
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 0.8 +(_pulseController.value * 0.25),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/lesson', arguments: {
                          'schoolLevel': isSelectedMedia
                              ? 'media'
                              : isSelectedSuperior
                                  ? 'superior'
                                  : isSelectedUniversity
                                      ? 'university'
                                      : 'none',
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00B8DB), Color(0xFFAD46FF)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: const BorderRadius.all(Radius.circular(40)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10 + (_pulseController.value * 10),
                              offset: const Offset(0, 4),
                              spreadRadius: _pulseController.value * 2,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 50),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                "ApprenderAI",
                                style: TextStyle(
                                  fontSize: 35,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: sizeWidth(0.02)),
                              const Icon(
                                Icons.star_outline_outlined,
                                size: 35,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),

              SizedBox(height: sizeWidth(0.01)),
            ],
          ),
        ],
      ),
    );
  }

}
