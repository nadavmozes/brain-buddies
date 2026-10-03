import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/timer_chip.dart';
import '../models/clock_question.dart';
import '../models/clock_time.dart';
import '../models/time_world.dart';
import '../services/clock_generator.dart';
import '../services/clock_state.dart';
import '../widgets/clock_face.dart';
import '../widgets/clock_setter.dart';
import 'clock_result_screen.dart';

/// Clock Hero gameplay for a single trail level, timed for a record. Supports
/// read-the-clock, find-the-clock, set-the-clock (interactive), and elapsed.
class ClockGameScreen extends StatefulWidget {
  const ClockGameScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.level,
  });

  final ClockState state;
  final PlayerProfile profile;
  final ClockLevel level;

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
  bool _lastWasRight = false;

  // Working value for the "set the clock" question.
  ClockTime _setValue = const ClockTime(12, 0);

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  int _elapsed = 0;

  ClockQuestion get _q => _questions[_current];

  int get _minuteStep {
    // Step by the world's finest minute granularity.
    final pool = widget.level.world.minutePool;
    if (pool.contains(5)) return 5;
    if (pool.contains(15)) return 15;
    return 30;
  }

  @override
  void initState() {
    super.initState();
    _questions = ClockQuestionGenerator.forLevel(widget.level);
    _resetSetValue();
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsed.inSeconds);
    });
  }

  void _resetSetValue() {
    // Start the dial at 12:00 so the child always adjusts to the target.
    _setValue = const ClockTime(12, 0);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _registerResult(bool isRight, String rightText) {
    final fb = FeedbackService(enabled: widget.state.soundOn);
    setState(() {
      _answered = true;
      _lastWasRight = isRight;
      if (isRight) {
        _correct++;
        _feedback = 'Right on time! ⏰';
        fb.correct();
      } else {
        _feedback = rightText;
        fb.wrong();
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), _advance);
  }

  void _onPickAnswer(int index) {
    if (_answered) return;
    _selectedIndex = index;
    final isRight = index == _q.correctIndex;
    final right = _q.textChoices != null
        ? _q.textChoices![_q.correctIndex]
        : _q.clockChoices![_q.correctIndex].label;
    _registerResult(isRight, 'It was $right');
  }

  void _onCheckSetClock() {
    if (_answered) return;
    final target = _q.targetTime!;
    final isRight = _setValue == target;
    _registerResult(isRight, 'It was ${target.label}');
  }

  Future<void> _advance() async {
    if (!mounted) return;
    if (_current + 1 < _questions.length) {
      setState(() {
        _current++;
        _selectedIndex = null;
        _answered = false;
        _feedback = '';
        _resetSetValue();
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
    if (outcome.stars == 3 || outcome.isNewFastest || outcome.guardianGreeted) {
      FeedbackService(enabled: widget.state.soundOn).celebrate();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => ClockResultScreen(
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
                        const SizedBox(height: 12),
                        _buildPromptAndChoices(),
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
                                color: _lastWasRight
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

  Widget _buildPromptAndChoices() {
    switch (_q.type) {
      case ClockQuestionType.readClock:
      case ClockQuestionType.elapsed:
        return Column(
          children: [
            if (_q.promptTime != null)
              ComicPanel(
                color: Colors.white,
                padding: const EdgeInsets.all(16),
                child: ClockFace(time: _q.promptTime!, size: 150),
              ),
            const SizedBox(height: 16),
            _TextChoices(
              question: _q,
              selectedIndex: _selectedIndex,
              answered: _answered,
              onAnswer: _onPickAnswer,
            ),
          ],
        );
      case ClockQuestionType.findClock:
        return _ClockChoices(
          question: _q,
          selectedIndex: _selectedIndex,
          answered: _answered,
          onAnswer: _onPickAnswer,
        );
      case ClockQuestionType.setClock:
        return Column(
          children: [
            ComicPanel(
              color: Colors.white,
              padding: const EdgeInsets.all(14),
              child: ClockSetter(
                value: _setValue,
                minuteStep: _minuteStep,
                enabled: !_answered,
                onChanged: (t) => setState(() => _setValue = t),
              ),
            ),
            const SizedBox(height: 14),
            ComicButton(
              label: _answered ? 'Checked' : 'Check',
              icon: Icons.check_rounded,
              fontSize: 22,
              onPressed: _answered ? null : _onCheckSetClock,
            ),
          ],
        );
    }
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
