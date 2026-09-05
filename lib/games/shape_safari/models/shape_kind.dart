import 'package:flutter/material.dart';

/// The shapes taught in Shape Safari.
enum ShapeKind {
  circle,
  oval,
  triangle,
  square,
  rectangle,
  pentagon,
  hexagon,
  star,
}

extension ShapeKindInfo on ShapeKind {
  /// Kid-friendly display name.
  String get label {
    switch (this) {
      case ShapeKind.circle:
        return 'Circle';
      case ShapeKind.oval:
        return 'Oval';
      case ShapeKind.triangle:
        return 'Triangle';
      case ShapeKind.square:
        return 'Square';
      case ShapeKind.rectangle:
        return 'Rectangle';
      case ShapeKind.pentagon:
        return 'Pentagon';
      case ShapeKind.hexagon:
        return 'Hexagon';
      case ShapeKind.star:
        return 'Star';
    }
  }

  /// Number of sides. Round shapes report 0 (used for the "how many sides"
  /// question, which only draws from straight-sided shapes).
  int get sides {
    switch (this) {
      case ShapeKind.circle:
      case ShapeKind.oval:
        return 0;
      case ShapeKind.triangle:
        return 3;
      case ShapeKind.square:
        return 4;
      case ShapeKind.rectangle:
        return 4;
      case ShapeKind.pentagon:
        return 5;
      case ShapeKind.hexagon:
        return 6;
      case ShapeKind.star:
        return 5; // a 5-pointed star has 5 "points"
    }
  }

  /// A cheerful fill color for the shape.
  Color get color {
    switch (this) {
      case ShapeKind.circle:
        return const Color(0xFF4FC3F7);
      case ShapeKind.oval:
        return const Color(0xFF9575CD);
      case ShapeKind.triangle:
        return const Color(0xFF4CAF50);
      case ShapeKind.square:
        return const Color(0xFFFF9800);
      case ShapeKind.rectangle:
        return const Color(0xFFEC407A);
      case ShapeKind.pentagon:
        return const Color(0xFF26A69A);
      case ShapeKind.hexagon:
        return const Color(0xFF7E57C2);
      case ShapeKind.star:
        return const Color(0xFFFFD23F);
    }
  }

  /// Whether the shape has straight sides (used for "count the sides").
  bool get hasStraightSides => sides > 0 && this != ShapeKind.star;

  /// The "easy" set introduced first (grade 1 friendly).
  static const List<ShapeKind> basic = [
    ShapeKind.circle,
    ShapeKind.triangle,
    ShapeKind.square,
    ShapeKind.rectangle,
    ShapeKind.star,
  ];
}
