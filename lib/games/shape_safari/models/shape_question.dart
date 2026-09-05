import 'shape_kind.dart';

/// The kinds of questions Shape Safari asks.
enum ShapeQuestionType {
  /// A shape is shown; pick its name from text options.
  identify,

  /// A shape name is given; pick the matching shape from visual options.
  find,

  /// A shape is shown; pick how many sides it has (number options).
  countSides,

  /// A repeating pattern is shown; pick the shape that comes next.
  pattern,
}

/// A single answer option, which is either a shape (drawn) or a label
/// (text/number). Exactly one of [shape] / [text] is non-null.
class ShapeChoice {
  const ShapeChoice.shape(this.shape) : text = null;
  const ShapeChoice.text(this.text) : shape = null;

  final ShapeKind? shape;
  final String? text;

  bool get isShape => shape != null;
}

/// A fully-built Shape Safari question with a prompt, choices, and the index
/// of the correct choice.
class ShapeQuestion {
  ShapeQuestion({
    required this.type,
    required this.prompt,
    required this.choices,
    required this.correctIndex,
    this.promptShape,
    this.patternSequence,
    required this.skillLabel,
  });

  final ShapeQuestionType type;

  /// The text shown above the choices, e.g. "What shape is this?".
  final String prompt;

  /// The shape drawn in the prompt area (identify / countSides).
  final ShapeKind? promptShape;

  /// For pattern questions, the shapes shown as the repeating sequence.
  final List<ShapeKind>? patternSequence;

  final List<ShapeChoice> choices;
  final int correctIndex;

  /// Short label for stats, e.g. "Identify", "Sides", "Pattern".
  final String skillLabel;
}
