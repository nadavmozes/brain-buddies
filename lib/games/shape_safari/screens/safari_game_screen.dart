import 'package:flutter/material.dart';

import 'dart:async';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/answer_badge.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/game_header.dart';
import '../models/habitat.dart';
import '../models/safari_level.dart';
import '../models/shape_kind.dart';
import '../models/shape_question.dart';
import '../services/question_generator.dart';
import '../services/safari_state.dart';
import '../widgets/shape_view.dart';
import 'safari_result_screen.dart';

/// The Shape Safari gameplay loop for a single trail level. On guardian stops
/// the guardian has hearts you fill by answering correctly ("photographing" it).
class SafariGameScreen extends StatefulWidget {
  const SafariGameScreen(
      {super.key,
      required this.state,
      required this.profile,
      required this.level});

  final SafariState state;
  final PlayerProfile profile;
  final SafariLevel level;

  @override
  State<SafariGameScreen> createState() => _SafariGameScreenState();
}

class _SafariGameScreenState extends State<SafariGameScreen> {
  late final List<ShapeQuestion> _questions;
  // The language resolved once in initState; drives Hebrew vs English question
  // generation.
  late final AppLang _lang;
  int _current = 0;
  int _correct = 0;
  int? _selectedIndex;
  bool _answered = false;
  String _feedback = '';

  // Guardian encounter: fill photos with correct answers.
  late int _photosNeeded;
  int _photos = 0;
  bool get _isGuardian => widget.level.isGuardian;

  // Timer for the fastest-stop record.
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  int _elapsed = 0;

  ShapeQuestion get _q => _questions[_current];

  @override
  void initState() {
    super.initState();
    // Non-listening lookup is safe in initState; falls back to English when no
    // L10n ancestor exists (matches the Money Math pattern).
    _lang = L10n.read(context).lang;
    _questions = ShapeQuestionGenerator.forLevel(widget.level, lang: _lang);
    // Need most answers right to befriend the guardian.
    _photosNeeded = 5;
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
    final l = context.l10n;
    final isRight = index == _q.correctIndex;
    final fb = FeedbackService(enabled: widget.state.soundOn);
    setState(() {
      _selectedIndex = index;
      _answered = true;
      if (isRight) {
        _correct++;
        if (_isGuardian) _photos++;
        _feedback = _isGuardian ? l.safariSnap : _praise(l);
        fb.correct();
      } else {
        _feedback = _correctAnswerText(context, l);
        fb.wrong();
      }
    });
    Future.delayed(const Duration(milliseconds: 1000), _advance);
  }

  String _praise(AppStrings l) {
    final lines = l.safariPraise;
    return lines[_correct % lines.length];
  }

  String _correctAnswerText(BuildContext context, AppStrings l) {
    final c = _q.choices[_q.correctIndex];
    // Localize the shape name for shape choices; text choices (numbers) are
    // already language-neutral.
    final label = c.isShape
        ? context.tr('ss.shape.label', c.shape!.name, c.shape!.label)
        : c.text!;
    return l.safariWrong(label);
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
    final befriended = _isGuardian && _photos >= _photosNeeded;
    final outcome = await widget.state.completeLevel(
      profile: widget.profile,
      level: widget.level,
      correct: _correct,
      total: _questions.length,
      guardianBefriended: befriended,
      elapsedSeconds: _stopwatch.elapsed.inSeconds,
    );
    if (!mounted) return;
    if (outcome.stars == 3 || befriended) {
      FeedbackService(enabled: widget.state.soundOn).celebrate();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => SafariResultScreen(
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
    final habitat = widget.level.habitat;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [habitat.color.withOpacity(0.5), AppTheme.paper],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                GameHeader(
                  title: _isGuardian
                      ? '${widget.level.guardian.emoji} ${context.tr('ss.guardian.name', habitat.name, widget.level.guardian.name)}'
                      : '${habitat.emoji} ${context.l10n.stopN(widget.level.number)}',
                  countLabel: '${_current + 1} / ${_questions.length}',
                  seconds: _elapsed,
                  progress: progress,
                  progressColor: habitat.color,
                ),
                if (_isGuardian) ...[
                  const SizedBox(height: 10),
                  _GuardianBar(
                    guardianEmoji: widget.level.guardian.emoji,
                    photos: _photos,
                    needed: _photosNeeded,
                  ),
                ],
                const Spacer(),
                Text(
                  _q.prompt,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 23, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 14),
                _PromptArea(question: _q),
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

/// Shows how many "photos" of the guardian have been captured.
class _GuardianBar extends StatelessWidget {
  const _GuardianBar({
    required this.guardianEmoji,
    required this.photos,
    required this.needed,
  });

  final String guardianEmoji;
  final int photos;
  final int needed;

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      color: AppTheme.guardianBar,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(guardianEmoji, style: const TextStyle(fontSize: 26)),
          Row(
            children: [
              for (int i = 0; i < needed; i++)
                Text(i < photos ? '📸' : '⬜',
                    style: const TextStyle(fontSize: 16)),
            ],
          ),
        ],
      ),
    );
  }
}

/// The shape or pattern shown above the choices.
class _PromptArea extends StatelessWidget {
  const _PromptArea({required this.question});

  final ShapeQuestion question;

  @override
  Widget build(BuildContext context) {
    if (question.patternSequence != null) {
      return ComicPanel(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (final s in question.patternSequence!) ...[
              ShapeView(shape: s, size: 42),
              const SizedBox(width: 6),
            ],
            const Text('❓', style: TextStyle(fontSize: 38)),
          ],
        ),
      );
    }
    if (question.promptShape != null) {
      return ComicPanel(
        color: Colors.white,
        padding: const EdgeInsets.all(16),
        child: ShapeView(shape: question.promptShape!, size: 104),
      );
    }
    return const SizedBox(height: 50);
  }
}

class _ChoiceGrid extends StatelessWidget {
  const _ChoiceGrid({
    required this.question,
    required this.selectedIndex,
    required this.answered,
    required this.onAnswer,
  });

  final ShapeQuestion question;
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
    // Use the actual available width from constraints (not MediaQuery, which
    // reports the full browser window and ignores the app's phone-width cap).
    return LayoutBuilder(
      builder: (context, constraints) {
        // Two tiles per row with a 14px gap between them.
        final tileWidth = (constraints.maxWidth - 14) / 2;
        // Cap shape-tile height so 2 rows always fit comfortably on screen.
        final tileHeight = tileWidth.clamp(60.0, 120.0);
        return Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: List.generate(question.choices.length, (index) {
            final choice = question.choices[index];
            if (choice.isShape) {
              final highlighted = answered &&
                  (index == question.correctIndex || index == selectedIndex);
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onTap: answered ? null : () => onAnswer(index),
                    child: Container(
                      width: tileWidth,
                      height: tileHeight,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _bg(index),
                        border: Border.all(color: AppTheme.ink, width: 3.5),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow:
                            AppTheme.comicShadow(offset: highlighted ? 2 : 5),
                      ),
                      child: ShapeView(
                          shape: choice.shape!, size: tileHeight * 0.62),
                    ),
                  ),
                  Positioned(
                    top: -6,
                    right: -6,
                    child: AnswerBadge(
                      show: highlighted,
                      correct: index == question.correctIndex,
                    ),
                  ),
                ],
              );
            }
            return SizedBox(
              width: tileWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ComicButton(
                    label: choice.text!,
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
                  Positioned(
                    top: -6,
                    right: -6,
                    child: AnswerBadge(
                      show: answered &&
                          (index == question.correctIndex ||
                              index == selectedIndex),
                      correct: index == question.correctIndex,
                    ),
                  ),
                ],
              ),
            );
          }),
        );
      },
    );
  }
}
