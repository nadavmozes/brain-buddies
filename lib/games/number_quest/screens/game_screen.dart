import 'package:flutter/material.dart';

import 'dart:async';

import '../../../core/services/feedback_service.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/timer_chip.dart';
import '../models/level.dart';
import '../models/math_problem.dart';
import '../models/skill.dart';
import '../services/game_state.dart';
import '../services/problem_generator.dart';
import '../widgets/hero_buddy.dart';
import 'result_screen.dart';

/// The core gameplay loop. Handles both regular levels and boss battles.
///
/// In a boss battle the monster has hearts; each correct answer takes one,
/// each wrong answer costs the hero a heart. Defeat the boss by emptying its
/// hearts before the questions run out.
class GameScreen extends StatefulWidget {
  const GameScreen({
    super.key,
    required this.level,
    required this.state,
    required this.profile,
    this.isDaily = false,
  });

  final GameLevel level;
  final GameState state;
  final PlayerProfile profile;
  final bool isDaily;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with SingleTickerProviderStateMixin {
  late final List<MathProblem> _problems;
  int _current = 0;
  int _correct = 0;
  int _score = 0;
  int _streak = 0;
  int _bestStreak = 0;
  int _lastGain = 0;
  int? _selectedIndex;
  bool _answered = false;
  BuddyMood _mood = BuddyMood.idle;
  String _feedbackText = '';

  // Boss state. The boss has one heart per question so every question counts;
  // the hero has a fixed cushion of lives.
  late int _bossHearts;
  late int _bossMaxHearts;
  late int _heroHearts;
  static const int _heroMaxHearts = 3;
  bool get _isBoss => widget.level.isBoss;

  late AnimationController _shakeController;

  // Timer for the fastest-level record.
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  int _elapsed = 0;

  MathProblem get _problem => _problems[_current];

  @override
  void initState() {
    super.initState();
    // Recent accuracy across all skills drives adaptive difficulty.
    _problems = ProblemGenerator.forLevel(
      widget.level,
      recentAccuracy: _recentAccuracy(),
    );
    // One boss heart per question, so beating the boss needs every question.
    _bossMaxHearts = _problems.length;
    _bossHearts = _bossMaxHearts;
    _heroHearts = _heroMaxHearts;
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsed.inSeconds);
    });
  }

  double _recentAccuracy() {
    var correct = 0, attempts = 0;
    for (final s in Skill.values) {
      final stat = widget.state.skillStat(s);
      correct += stat.correct;
      attempts += stat.attempts;
    }
    return attempts == 0 ? 0.7 : correct / attempts;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    _shakeController.dispose();
    super.dispose();
  }

  void _onAnswer(int index) {
    if (_answered) return;
    final chosen = _problem.choices[index];
    final isRight = chosen == _problem.answer;
    final feedback = FeedbackService(enabled: widget.state.soundOn);
    final skill = SkillInfo.fromLabel(_problem.operatorLabel);
    widget.state.recordAnswer(skill, isRight);

    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (isRight) {
        _correct++;
        _streak++;
        if (_streak > _bestStreak) _bestStreak = _streak;
        _lastGain = 10 + (_streak - 1) * 5;
        _score += _lastGain;
        _mood = BuddyMood.happy;
        _feedbackText = _praise();
        if (_isBoss && _bossHearts > 0) _bossHearts--;
        feedback.correct();
      } else {
        _streak = 0;
        _lastGain = 0;
        _mood = BuddyMood.sad;
        _feedbackText = 'The answer was ${_problem.answer}. You got this!';
        if (_isBoss && _heroHearts > 0) _heroHearts--;
        _shakeController.forward(from: 0);
        feedback.wrong();
      }
    });

    Future.delayed(const Duration(milliseconds: 1000), _advance);
  }

  String _praise() {
    const lines = ['Nice!', 'Great!', 'Boom!', 'Yes!', 'Awesome!', 'Pow!'];
    return lines[_correct % lines.length];
  }

  void _advance() {
    if (!mounted) return;
    // Boss can end early: hero out of hearts, or boss defeated.
    if (_isBoss && (_heroHearts <= 0 || _bossHearts <= 0)) {
      _finishRound();
      return;
    }
    if (_current + 1 < _problems.length) {
      setState(() {
        _current++;
        _selectedIndex = null;
        _answered = false;
        _mood = BuddyMood.idle;
        _feedbackText = '';
      });
    } else {
      _finishRound();
    }
  }

  Future<void> _finishRound() async {
    _stopwatch.stop();
    _ticker?.cancel();
    final bossDefeated = _isBoss && _bossHearts <= 0;
    widget.state.reportAnswerStreak(_bestStreak);

    final outcome = await widget.state.completeLevel(
      profile: widget.profile,
      level: widget.level,
      elapsedSeconds: _stopwatch.elapsed.inSeconds,
      correct: _correct,
      total: _problems.length,
      roundScore: _score,
      bestAnswerStreak: _bestStreak,
      bossDefeated: bossDefeated,
    );

    if (!mounted) return;
    if (outcome.stars == 3 || bossDefeated) {
      FeedbackService(enabled: widget.state.soundOn).celebrate();
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ResultScreen(
          state: widget.state,
          profile: widget.profile,
          level: widget.level,
          outcome: outcome,
          correct: _correct,
          total: _problems.length,
          score: _score,
          bossDefeated: bossDefeated,
          heroSurvived: !_isBoss || _heroHearts > 0,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_current + 1) / _problems.length;
    final hero = widget.profile.selectedAvatar;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _isBoss ? const Color(0xFF3A2E5C) : AppTheme.sky,
              AppTheme.paper,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Header(
                  title: widget.isDaily
                      ? '📅 Daily'
                      : (_isBoss
                          ? '${widget.level.boss.emoji} ${widget.level.boss.name}'
                          : widget.level.title),
                  world: widget.level.world,
                  current: _current + 1,
                  total: _problems.length,
                  progress: progress,
                  score: _score,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TimerChip(seconds: _elapsed),
                ),
                const SizedBox(height: 8),
                if (_isBoss)
                  _BossBar(
                    bossHearts: _bossHearts,
                    bossMaxHearts: _bossMaxHearts,
                    heroHearts: _heroHearts,
                    heroMaxHearts: _heroMaxHearts,
                    bossEmoji: widget.level.boss.emoji,
                    heroEmoji: hero.emoji,
                  ),
                const Spacer(),
                HeroBuddy(
                  mood: _mood,
                  heroEmoji: hero.emoji,
                  baseColor: hero.color,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 28,
                  child: AnimatedOpacity(
                    opacity: _answered ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: Text(
                      _answered && _lastGain > 0
                          ? (_streak > 1
                              ? '$_feedbackText  +$_lastGain  🔥x$_streak'
                              : '$_feedbackText  +$_lastGain')
                          : _feedbackText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: _mood == BuddyMood.happy
                            ? AppTheme.success
                            : AppTheme.danger,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _QuestionCard(
                  problem: _problem,
                  shakeController: _shakeController,
                ),
                const SizedBox(height: 20),
                _ChoiceGrid(
                  problem: _problem,
                  selectedIndex: _selectedIndex,
                  answered: _answered,
                  onAnswer: _onAnswer,
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────── Sub-widgets ───────────────────────

class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.world,
    required this.current,
    required this.total,
    required this.progress,
    required this.score,
  });

  final String title;
  final dynamic world;
  final int current;
  final int total;
  final double progress;
  final int score;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(title,
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const Spacer(),
            const Text('⚡', style: TextStyle(fontSize: 18)),
            Text('$score',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
            const SizedBox(width: 12),
            Text('$current / $total',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 12,
            backgroundColor: Colors.white,
            color: AppTheme.primary,
          ),
        ),
      ],
    );
  }
}

class _BossBar extends StatelessWidget {
  const _BossBar({
    required this.bossHearts,
    required this.bossMaxHearts,
    required this.heroHearts,
    required this.heroMaxHearts,
    required this.bossEmoji,
    required this.heroEmoji,
  });

  final int bossHearts;
  final int bossMaxHearts;
  final int heroHearts;
  final int heroMaxHearts;
  final String bossEmoji;
  final String heroEmoji;

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      color: const Color(0xFF4A3A6E),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Boss hearts (one per question). Wrap so 8 fit on small screens.
          Flexible(
            child: Row(
              children: [
                Text(bossEmoji, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 6),
                Flexible(
                  child: Wrap(
                    children: [
                      for (int i = 0; i < bossMaxHearts; i++)
                        Text(i < bossHearts ? '💜' : '🖤',
                            style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            children: [
              for (int i = 0; i < heroMaxHearts; i++)
                Text(i < heroHearts ? '❤️' : '🤍',
                    style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(heroEmoji, style: const TextStyle(fontSize: 22)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard({required this.problem, required this.shakeController});

  final MathProblem problem;
  final AnimationController shakeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: shakeController,
      builder: (context, child) {
        final v = shakeController.value;
        final dx = shakeController.isAnimating
            ? 12 *
                (v < 0.25
                    ? v * 4
                    : v < 0.75
                        ? (0.5 - v) * 4
                        : (v - 1) * 4)
            : 0.0;
        return Transform.translate(offset: Offset(dx, 0), child: child);
      },
      child: ComicPanel(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
        child: Column(
          children: [
            Text(
              problem.operatorLabel.toUpperCase(),
              style: TextStyle(
                color: AppTheme.primary.withOpacity(0.7),
                fontSize: 16,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              problem.question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 46,
                fontWeight: FontWeight.w900,
                color: AppTheme.ink,
                shadows: [Shadow(color: AppTheme.accent, offset: Offset(2, 2))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.problem,
    required this.selectedIndex,
    required this.answered,
    required this.onAnswer,
  });

  final MathProblem problem;
  final int? selectedIndex;
  final bool answered;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    // Use the actual available width (not MediaQuery, which reports the full
    // browser window and ignores the app's phone-width cap).
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          children: List.generate(problem.choices.length, (index) {
            final value = problem.choices[index];
            final isCorrect = value == problem.answer;
            final isSelected = index == selectedIndex;

            Color bgColor;
            if (!answered) {
              bgColor = Colors.white;
            } else if (isCorrect) {
              bgColor = AppTheme.success;
            } else if (isSelected) {
              bgColor = AppTheme.danger;
            } else {
              bgColor = Colors.white;
            }

            return SizedBox(
              width: tileWidth,
              child: ComicButton(
                label: '$value',
                fontSize: 28,
                color: bgColor,
                textColor: answered && (isCorrect || isSelected)
                    ? Colors.white
                    : AppTheme.ink,
                expand: true,
                onPressed: answered ? null : () => onAnswer(index),
              ),
            );
          }),
        );
      },
    );
  }
}
