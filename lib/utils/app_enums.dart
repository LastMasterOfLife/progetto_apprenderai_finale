// =============================================================================
// app_enums.dart — Enum e utility condivisi tra le schermate
// =============================================================================

import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// SchoolLevel — livello scolastico selezionato dall'utente
// ---------------------------------------------------------------------------
//
// Sostituisce i tre booleani (isSelectedMedia / isSelectedSuperior /
// isSelectedUniversity) di StartScreen e le stringhe hardcoded sparse
// nel codebase. Tutte le proprietà derivate (colore, immagine, query API)
// vivono qui — un solo posto da modificare se cambiano le risorse.
// ---------------------------------------------------------------------------

enum SchoolLevel {
  media,
  superior,
  university;

  /// Stringa passata come argomento di rotta (e ricevuta in LessonScreen)
  String get routeArgument {
    switch (this) {
      case SchoolLevel.media:       return 'media';
      case SchoolLevel.superior:    return 'superior';
      case SchoolLevel.university:  return 'university';
    }
  }

  /// Nome leggibile per la copertina del libro
  String get displayName {
    switch (this) {
      case SchoolLevel.media:       return 'Scuole medie';
      case SchoolLevel.superior:    return 'Scuole superiori';
      case SchoolLevel.university:  return 'Università';
    }
  }

  /// Sfondo di StartScreen associato al livello
  String get backgroundImage {
    switch (this) {
      case SchoolLevel.media:       return 'assets/backgrounds/green_nature.jpg';
      case SchoolLevel.superior:    return 'assets/backgrounds/blue_study.jpg';
      case SchoolLevel.university:  return 'assets/backgrounds/red_sunset.jpg';
    }
  }

  /// Colore tematico del livello (usato in BookStackWidget, titoli, segnalibri)
  Color get color {
    switch (this) {
      case SchoolLevel.media:       return Colors.green;
      case SchoolLevel.superior:    return Colors.blue;
      case SchoolLevel.university:  return Colors.red;
    }
  }

  /// Suffisso query per il backend RAG
  String get apiLevelQuery {
    switch (this) {
      case SchoolLevel.media:       return 'LIVELLO=MEDIE';
      case SchoolLevel.superior:    return 'LIVELLO=SUPERIORI';
      case SchoolLevel.university:  return 'LIVELLO=UNIVERSITA';
    }
  }

  /// Copertina del libro
  String get coverImagePath {
    switch (this) {
      case SchoolLevel.media:       return 'assets/image/cover_book_verde.jpg';
      case SchoolLevel.superior:    return 'assets/image/cover_book_blu.png';
      case SchoolLevel.university:  return 'assets/image/cover_book_rosso.png';
    }
  }

  /// Costruisce un SchoolLevel dalla stringa di rotta (case-insensitive).
  /// Ritorna [SchoolLevel.media] come fallback sicuro.
  static SchoolLevel fromRouteArgument(String value) {
    switch (value.toLowerCase()) {
      case 'media':      return SchoolLevel.media;
      case 'superior':   return SchoolLevel.superior;
      case 'university': return SchoolLevel.university;
      default:           return SchoolLevel.media;
    }
  }
}

// ---------------------------------------------------------------------------
// BookmarkTab — tab del pannello destro del libro
// ---------------------------------------------------------------------------
//
// Sostituisce la stringa nullable 'notes' | 'chat' | null usata in
// BookStackWidget e RightPageLayer. Un typo non può più rompere la logica.
// ---------------------------------------------------------------------------

enum BookmarkTab { notes, chat }

// ---------------------------------------------------------------------------
// parseChaptersIndex — parsing della risposta /recupera_indice
// ---------------------------------------------------------------------------
//
// Centralizza la trasformazione del formato raw `MATERIA|ARGOMENTO|SOTTO`
// in una stringa gerarchica con marcatori `SUBJECT:`.
// Prima viveva inline in LessonScreen — ora è riutilizzabile e testabile.
// ---------------------------------------------------------------------------

String parseChaptersIndex(String rawResponse) {
  final lines = rawResponse.split('\n');
  final Map<String, List<String>> grouped = {};

  // Salta la prima riga (header della risposta)
  for (int i = 1; i < lines.length; i++) {
    final parts = lines[i].split('|');
    if (parts.length != 3) continue;

    final materia = parts[0].trim();
    String sottoArgomento = parts[2].trim();

    // Prende solo la prima parte prima dei ":" (es. "Gioconda: Desc" → "Gioconda")
    if (sottoArgomento.contains(':')) {
      sottoArgomento = sottoArgomento.split(':').first.trim();
    }

    grouped.putIfAbsent(materia, () => []);
    if (!grouped[materia]!.contains(sottoArgomento)) {
      grouped[materia]!.add(sottoArgomento);
    }
  }

  final formatted = <String>[];
  grouped.forEach((materia, argomenti) {
    formatted.add('SUBJECT:$materia');
    formatted.addAll(argomenti);
  });

  return formatted.join('\n');
}
