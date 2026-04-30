// =============================================================================
// StickyNote — Modello dati per le note adesive
// =============================================================================
//
// Rappresenta una nota adesiva creata dall'utente nel pannello Note
// del libro interattivo. Ogni nota ha un titolo, un contenuto, un colore
// di sfondo scelto casualmente e un angolo di rotazione per l'effetto
// "nota appiccicata".
//
// Usato in: BookStackWidget, RightPageLayer
// =============================================================================

import 'package:flutter/material.dart';

/// Dato immutabile di una nota adesiva.
///
/// Per aggiornare i campi usa [copyWith] — non modificare le proprietà
/// direttamente (sono `final`).
class StickyNote {
  /// Titolo breve della nota (può essere vuoto).
  final String title;

  /// Corpo della nota.
  final String content;

  /// Colore di sfondo della nota (giallo pastello di default).
  final Color color;

  /// Angolo di rotazione in radianti (piccolo valore per look "appiccicato").
  final double rotation;

  const StickyNote({
    required this.title,
    required this.content,
    required this.color,
    required this.rotation,
  });

  /// Restituisce una copia con i campi specificati sostituiti.
  StickyNote copyWith({
    String? title,
    String? content,
    Color? color,
    double? rotation,
  }) {
    return StickyNote(
      title: title ?? this.title,
      content: content ?? this.content,
      color: color ?? this.color,
      rotation: rotation ?? this.rotation,
    );
  }
}
