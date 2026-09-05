import 'difficulty.dart';

/// Summary of a completed adventure round.
class RoundResult {
  RoundResult({
    required this.difficulty,
    required this.correct,
    required this.total,
    this.score = 0,
  });

  final Difficulty difficulty;
  final int correct;
  final int total;

  /// Points earned this round, including streak bonuses.
  final int score;

  /// Score as a percentage 0-100.
  int get percent => total == 0 ? 0 : ((correct / total) * 100).round();

  /// Stars earned this round: 0-3 based on accuracy.
  int get stars {
    final p = percent;
    if (p >= 90) return 3;
    if (p >= 70) return 2;
    if (p >= 50) return 1;
    return 0;
  }

  /// A comic-style congratulatory line based on performance.
  String get message {
    switch (stars) {
      case 3:
        return 'SUPER HERO! You mastered this quest!';
      case 2:
        return 'GREAT JOB! You are getting stronger!';
      case 1:
        return 'NICE TRY! Keep training, hero!';
      default:
        return 'ADVENTURE AWAITS! Try again, you can do it!';
    }
  }
}
