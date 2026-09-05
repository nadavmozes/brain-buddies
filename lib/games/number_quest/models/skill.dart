/// The math skills tracked for the parent progress view and adaptive difficulty.
enum Skill {
  addition,
  subtraction,
  multiplication,
  division,
}

extension SkillInfo on Skill {
  /// Human label, matches the [MathProblem.operatorLabel] strings.
  String get label {
    switch (this) {
      case Skill.addition:
        return 'Addition';
      case Skill.subtraction:
        return 'Subtraction';
      case Skill.multiplication:
        return 'Multiplication';
      case Skill.division:
        return 'Division';
    }
  }

  String get emoji {
    switch (this) {
      case Skill.addition:
        return '➕';
      case Skill.subtraction:
        return '➖';
      case Skill.multiplication:
        return '✖️';
      case Skill.division:
        return '➗';
    }
  }

  /// Persistence key prefix.
  String get key => 'skill_$name';

  /// Resolves a [MathProblem.operatorLabel] back to a [Skill].
  static Skill fromLabel(String label) {
    switch (label) {
      case 'Addition':
        return Skill.addition;
      case 'Subtraction':
        return Skill.subtraction;
      case 'Multiplication':
        return Skill.multiplication;
      case 'Division':
        return Skill.division;
      default:
        return Skill.addition;
    }
  }
}

/// Running accuracy stats for a single skill.
class SkillStat {
  SkillStat({this.correct = 0, this.attempts = 0});

  int correct;
  int attempts;

  double get accuracy => attempts == 0 ? 0 : correct / attempts;
  int get percent => (accuracy * 100).round();

  /// A friendly mastery label for the parent view.
  String get masteryLabel {
    if (attempts < 5) return 'Just starting';
    if (percent >= 90) return 'Mastered';
    if (percent >= 70) return 'Strong';
    if (percent >= 50) return 'Practicing';
    return 'Needs practice';
  }
}
