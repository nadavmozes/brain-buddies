import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/timer_chip.dart';
import '../models/word_question.dart';
import '../services/word_generator.dart';
import '../services/wizard_state.dart';
import 'wizard_result_screen.dart';

/// Word Wizard gameplay: 8 word questions, timed for a fastest-run record.
class WizardGameScreen extends StatefulWidget {
  const WizardGameScreen(
      {super.key, required this.state, required this.profile});

  final WizardState state;
  final PlayerProfile profile;

  static const int questionsPerRound = 8;

  @override
  State<WizardGameScreen> createState() => _WizardGameScreenState();
}

class _WizardGameScreenState extends State<WizardGameScreen> {
  late final List<WordQuestion> _questions;
  int _current = 0;
  int _correct = 0;
  int? _selectedIndex;
  bool _answered = false;
  String _feedback = '';

  // Timer for the fastest-run record.
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  int _elapsed = 0;

  WordQuestion get _q => _questions[_current];

  @override
  void initState() {
    super.initState();
    _questions = WordQuestionGenerator()
        .generateRound(WizardGameScreen.questionsPerRound, difficulty: 0.3);
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
      if (isRight) {
        _correct++;
        _feedback = 'Magic! ✨';
        fb.correct();
      } else {
        _feedback = 'It was "${_q.choices[_q.correctIndex]}"';
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
    final outcome = await widget.state.completeRound(
      profile: widget.profile,
      correct: _correct,
      total: _questions.length,
      elapsedSeconds: _stopwatch.elapsed.inSeconds,
    );
    if (!mounted) return;
    if (outcome.stars == 3 || outcome.isNewFastest) {
      FeedbackService(enabled: widget.state.soundOn).celebrate();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => WizardResultScreen(
          state: widget.state,
          profile: widget.profile,
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
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF48FB1), AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('🔤 Wizard',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w900)),
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
                    color: const Color(0xFFEC407A),
                  ),
                ),
                const Spacer(),
                Text(_q.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                ComicPanel(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 20),
                  child: Column(
                    children: [
                      Text(_q.emoji, style: const TextStyle(fontSize: 72)),
                      if (_q.display.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          _q.display,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
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
                        color: _selectedIndex == _q.correctIndex
                            ? AppTheme.success
                            : AppTheme.danger,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _ChoiceGrid(
                  question: _q,
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

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.question,
    required this.selectedIndex,
    required this.answered,
    required this.onAnswer,
  });

  final WordQuestion question;
  final int? selectedIndex;
  final bool answered;
  final ValueChanged<int> onAnswer;

  Color _bg(int index) {
    if (!answered) return Colors.white;
    if (index == question.correctIndex) return AppTheme.success;
    if (index == selectedIndex) return AppTheme.danger;
    return Colors.white;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final tileWidth = (constraints.maxWidth - 14) / 2;
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: List.generate(question.choices.length, (index) {
            return SizedBox(
              width: tileWidth,
              child: ComicButton(
                label: question.choices[index],
                fontSize: 22,
                color: _bg(index),
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
