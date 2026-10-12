/// Describes one Times Tables level's teaching window.
///
/// Early levels use a visual dot ARRAY to "build the fact" (small factors),
/// later levels drop the array for plain multiple-choice recall with larger
/// factors, and the boss is mixed recall across the full 1-12 range.
class MultLevelSpec {
  const MultLevelSpec({
    required this.minFactor,
    required this.maxFactor,
    required this.useArray,
    this.isMixedRecall = false,
  });

  /// Smallest factor used for either operand (>= 1).
  final int minFactor;

  /// Largest factor used for either operand (<= 12).
  final int maxFactor;

  /// Whether this level shows the visual dot-array teaching aid.
  final bool useArray;

  /// Boss / recall level that mixes the whole 1-12 range.
  final bool isMixedRecall;
}
