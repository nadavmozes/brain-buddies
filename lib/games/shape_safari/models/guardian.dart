import 'package:flutter/material.dart';

import 'habitat.dart';

/// A friendly shape guardian animal at the end of a habitat trail. Instead of
/// "defeating" it, the explorer photographs it by answering correctly.
class SafariGuardian {
  const SafariGuardian({
    required this.name,
    required this.emoji,
    required this.color,
    required this.intro,
  });

  final String name;
  final String emoji;
  final Color color;

  /// A playful line shown when the guardian encounter begins.
  final String intro;
}

/// One guardian per habitat.
class Guardians {
  Guardians._();

  static const Map<Habitat, SafariGuardian> _byHabitat = {
    Habitat.jungle: SafariGuardian(
      name: 'Leo the Lion',
      emoji: '🦁',
      color: Color(0xFF43A047),
      intro: 'Snap my photo by naming the shapes!',
    ),
    Habitat.desert: SafariGuardian(
      name: 'Cami the Camel',
      emoji: '🐫',
      color: Color(0xFFFFB300),
      intro: 'Keep up across the dunes, explorer!',
    ),
    Habitat.mountain: SafariGuardian(
      name: 'Rocky the Eagle',
      emoji: '🦅',
      color: Color(0xFF5C6BC0),
      intro: 'Only the sharpest eyes reach the peak!',
    ),
  };

  static SafariGuardian forHabitat(Habitat h) => _byHabitat[h]!;
}
