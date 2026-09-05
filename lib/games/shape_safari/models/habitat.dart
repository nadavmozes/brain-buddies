import 'package:flutter/material.dart';

import 'shape_kind.dart';

/// The safari habitats (worlds) the explorer travels through. Each introduces
/// more shapes and a higher base difficulty.
enum Habitat {
  jungle,
  desert,
  mountain,
}

extension HabitatInfo on Habitat {
  String get label {
    switch (this) {
      case Habitat.jungle:
        return 'Jungle';
      case Habitat.desert:
        return 'Desert';
      case Habitat.mountain:
        return 'Mountain';
    }
  }

  String get subtitle {
    switch (this) {
      case Habitat.jungle:
        return 'Meet the basic shapes among the vines.';
      case Habitat.desert:
        return 'New shapes appear across the dunes.';
      case Habitat.mountain:
        return 'Every shape, and the trickiest patterns.';
    }
  }

  String get emoji {
    switch (this) {
      case Habitat.jungle:
        return '🌿';
      case Habitat.desert:
        return '🏜️';
      case Habitat.mountain:
        return '⛰️';
    }
  }

  Color get color {
    switch (this) {
      case Habitat.jungle:
        return const Color(0xFF43A047);
      case Habitat.desert:
        return const Color(0xFFFFB300);
      case Habitat.mountain:
        return const Color(0xFF5C6BC0);
    }
  }

  /// The base difficulty (0..1) for this habitat, before per-level ramping.
  double get baseDifficulty {
    switch (this) {
      case Habitat.jungle:
        return 0.15;
      case Habitat.desert:
        return 0.45;
      case Habitat.mountain:
        return 0.7;
    }
  }

  /// The shapes that can appear in this habitat.
  List<ShapeKind> get shapePool {
    switch (this) {
      case Habitat.jungle:
        return List.of(ShapeKindInfo.basic);
      case Habitat.desert:
        return [...ShapeKindInfo.basic, ShapeKind.oval, ShapeKind.pentagon];
      case Habitat.mountain:
        return List.of(ShapeKind.values);
    }
  }

  String get storageKey => 'habitat_$name';
}
