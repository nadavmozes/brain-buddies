import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/timer_chip.dart';
import '../models/clock_question.dart';
import '../services/clock_generator.dart';
import '../services/clock_state.dart';
import '../widgets/clock_face.dart';
import 'clock_result_screen.dart';

/// Clock Hero gameplay: 8 time questions, timed for a fastest-run record.
class ClockGameScreen extends StatefulWidget {
  const ClockGameScreen({super.key, required this.state, required this.profile});

  final ClockState state;
  final PlayerProfile profile;

  static const int questionsPerRound = 8;

  @override
  State<ClockGameScreen> createState() => _ClockGameScreenState();
}

class _ClockGameScreenState extends State<ClockGameScreen> {
  late final List<ClockQuestion> _questions;
  int _current = 0;
  int _correct = 0;
  int? _selectedIndex;
  bool _answered = false;
  String _feedback = '';

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  int _elapsed = 0;

  ClockQuestion get _q => _questions[_current];

  @override
  void initState() {
    super.initState();
    _questions = ClockQuestionGenerator()
        .generateRound(ClockGameScreen.questionsPerRound, difficulty: 0.3);
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
        _feedback = 'Right on time! ⏰';
        fb.correct();
      } else {
        _feedback = 'Keep trying!';
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
        builder: (_) => ClockResultScreen(
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
            colors: [Color(0xFFFFCC80), AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('🕒 Clock',
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
                    color: const Color(0xFFFF9800),
                  ),
                ),
                const Spacer(),
                Text(_q.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w900)),
                const SizedBox(height: 12),
                if (_q.type == ClockQuestionType.readClock)
                  ComicPanel(
                    color: Colors.white,
                    padding: const EdgeInsets.all(16),
                    child: ClockFace(time: _q.promptTime!, size: 170),
                  ),
                const SizedBox(height: 8),
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
                const SizedBox(height: 8),
                _q.type == ClockQuestionType.readClock
                    ? _TextChoices(
                        question: _q,
                        selectedIndex: _selectedIndex,
                        answered: _answered,
                        onAnswer: _onAnswer,
                      )
                    : _ClockChoices(
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

Color _bgFor(ClockQuestion q, int index, int? selected, bool answered) {
  if (!answered) return Colors.white;
  if (index == q.correctIndex) return AppTheme.success;
  if (index == selected) return AppTheme.danger;
  return Colors.white;
}

class _TextChoices extends StatelessWidget {
  const _TextChoices({
    required this.question,
    required this.selectedIndex,
    required this.answered,
    required this.onAnswer,
  });

  final ClockQuestion question;
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
                color: _bgFor(question, index, selectedIndex, answered),
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

class _ClockChoices extends StatelessWidget {
  const _ClockChoices({
    required this.question,
    required this.selectedIndex,
    required this.answered,
    required this.onAnswer,
  });

  final ClockQuestion question;
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
          children: List.generate(question.clockChoices!.length, (index) {
            final highlighted = answered &&
                (index == question.correctIndex || index == selectedIndex);
            return GestureDetector(
              onTap: answered ? null : () => onAnswer(index),
              child: Container(
                width: tileWidth,
                height: tileWidth,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _bgFor(question, index, selectedIndex, answered),
                  border: Border.all(color: AppTheme.ink, width: 3.5),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppTheme.comicShadow(offset: highlighted ? 2 : 5),
                ),
                child: ClockFace(
                    time: question.clockChoices![index],
                    size: tileWidth * 0.82),
              ),
            );
          }),
        );
      },
    );
  }
}
