import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/timer_chip.dart';
import '../models/money_level.dart';
import '../models/money_question.dart';
import '../services/money_generator.dart';
import '../services/money_state.dart';
import 'money_result_screen.dart';

/// Money Math gameplay for a single trail level, timed for a record.
class MoneyGameScreen extends StatefulWidget {
  const MoneyGameScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.level,
  });

  final MoneyState state;
  final PlayerProfile profile;
  final MoneyLevel level;

  @override
  State<MoneyGameScreen> createState() => _MoneyGameScreenState();
}

class _MoneyGameScreenState extends State<MoneyGameScreen> {
  late final List<MoneyQuestion> _questions;
  int _current = 0;
  int _correct = 0;
  int? _selectedIndex;
  bool _answered = false;
  String _feedback = '';
  bool _lastRight = false;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  int _elapsed = 0;

  MoneyQuestion get _q => _questions[_current];

  @override
  void initState() {
    super.initState();
    _questions = MoneyQuestionGenerator.forLevel(widget.level);
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsed.inSeconds);
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _onAnswer(int index) {
    if (_answered) return;
    final isRight = index == _q.correctIndex;
    final fb = FeedbackService(enabled: widget.state.soundOn);
    setState(() {
      _selectedIndex = index;
      _answered = true;
      _lastRight = isRight;
      if (isRight) {
        _correct++;
        _feedback = 'Cha-ching! 💰';
        fb.correct();
      } else {
        _feedback = 'Not quite!';
        fb.wrong();
      }
    });
    Future.delayed(const Duration(milliseconds: 950), _advance);
  }

  Future<void> _advance() async {
    if (!mounted) return;
    if (_current + 1 < _questions.length) {
      setState(() {
        _current++;
        _selectedIndex = null;
        _answered = false;
        _feedback = '';
      });
      return;
    }
    _stopwatch.stop();
    _ticker?.cancel();
    final outcome = await widget.state.completeLevel(
      profile: widget.profile,
      level: widget.level,
      correct: _correct,
      total: _questions.length,
      elapsedSeconds: _stopwatch.elapsed.inSeconds,
    );
    if (!mounted) return;
    if (outcome.stars == 3 || outcome.isNewFastest || outcome.bossBeaten) {
      FeedbackService(enabled: widget.state.soundOn).celebrate();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MoneyResultScreen(
          state: widget.state,
          profile: widget.profile,
          level: widget.level,
          outcome: outcome,
          correct: _correct,
          total: _questions.length,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_current + 1) / _questions.length;
    final world = widget.level.world;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [world.color.withOpacity(0.5), AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(
                      widget.level.isBoss
                          ? '${widget.level.guardian.emoji} ${widget.level.guardian.name}'
                          : '${world.emoji} ${widget.level.title}',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const Spacer(),
                    TimerChip(seconds: _elapsed),
                    const SizedBox(width: 10),
                    Text('${_current + 1} / ${_questions.length}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w800)),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: Colors.white,
                    color: world.color,
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        Text(_q.prompt,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 22, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 14),
                        _buildBody(),
                        SizedBox(
                          height: 26,
                          child: AnimatedOpacity(
                            opacity: _answered ? 1 : 0,
                            duration: const Duration(milliseconds: 150),
                            child: Text(
                              _feedback,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                                color: _lastRight
                                    ? AppTheme.success
                                    : AppTheme.danger,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_q.type) {
      case MoneyQuestionType.countCoins:
        return Column(
          children: [
            _CoinPanel(emojiRow: _q.pile!.emojiRow),
            const SizedBox(height: 16),
            _TextChoices(
              question: _q,
              selectedIndex: _selectedIndex,
              answered: _answered,
              onAnswer: _onAnswer,
            ),
          ],
        );
      case MoneyQuestionType.whichMore:
        return _TwoPiles(
          question: _q,
          selectedIndex: _selectedIndex,
          answered: _answered,
          onAnswer: _onAnswer,
        );
      case MoneyQuestionType.makeAmount:
        return _PileChoices(
          question: _q,
          selectedIndex: _selectedIndex,
          answered: _answered,
          onAnswer: _onAnswer,
        );
    }
  }
}

Color _bg(MoneyQuestion q, int index, int? selected, bool answered) {
  if (!answered) return Colors.white;
  if (index == q.correctIndex) return AppTheme.success;
  if (index == selected) return AppTheme.danger;
  return Colors.white;
}

class _CoinPanel extends StatelessWidget {
  const _CoinPanel({required this.emojiRow});
  final String emojiRow;

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Text(
        emojiRow,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 40),
      ),
    );
  }
}

class _TextChoices extends StatelessWidget {
  const _TextChoices({
    required this.question,
    required this.selectedIndex,
    required this.answered,
    required this.onAnswer,
  });

  final MoneyQuestion question;
  final int? selectedIndex;
  final bool answered;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: List.generate(question.textChoices!.length, (index) {
            return SizedBox(
              width: tileWidth,
              child: ComicButton(
                label: question.textChoices![index],
                fontSize: 24,
                color: _bg(question, index, selectedIndex, answered),
                textColor: answered &&
                        (index == question.correctIndex ||
                            index == selectedIndex)
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

class _TwoPiles extends StatelessWidget {
  const _TwoPiles({
    required this.question,
    required this.selectedIndex,
    required this.answered,
    required this.onAnswer,
  });

  final MoneyQuestion question;
  final int? selectedIndex;
  final bool answered;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    final piles = [question.pileA!, question.pileB!];
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: List.generate(2, (index) {
            return GestureDetector(
              onTap: answered ? null : () => onAnswer(index),
              child: Container(
                width: tileWidth,
                constraints: const BoxConstraints(minHeight: 90),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _bg(question, index, selectedIndex, answered),
                  border: Border.all(color: AppTheme.ink, width: 3.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.comicShadow(offset: 5),
                ),
                child: Text(piles[index].emojiRow,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 28)),
              ),
            );
          }),
        );
      },
    );
  }
}

class _PileChoices extends StatelessWidget {
  const _PileChoices({
    required this.question,
    required this.selectedIndex,
    required this.answered,
    required this.onAnswer,
  });

  final MoneyQuestion question;
  final int? selectedIndex;
  final bool answered;
  final ValueChanged<int> onAnswer;

  @override
  Widget build(BuildContext context) {
    final piles = question.pileChoices!;
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: List.generate(piles.length, (index) {
            return GestureDetector(
              onTap: answered ? null : () => onAnswer(index),
              child: Container(
                width: tileWidth,
                constraints: const BoxConstraints(minHeight: 80),
                alignment: Alignment.center,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _bg(question, index, selectedIndex, answered),
                  border: Border.all(color: AppTheme.ink, width: 3.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.comicShadow(offset: 5),
                ),
                child: Text(piles[index].emojiRow,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24)),
              ),
            );
          }),
        );
      },
    );
  }
}
