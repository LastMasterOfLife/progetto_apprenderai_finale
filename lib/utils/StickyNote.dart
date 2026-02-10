import 'package:flutter/material.dart';

/// Data model for a sticky note
class StickyNote {
  final String title;
  final String content;
  final Color color;
  final double rotation;

  const StickyNote({
    required this.title,
    required this.content,
    required this.color,
    required this.rotation,
  });

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
