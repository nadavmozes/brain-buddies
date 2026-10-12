import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/feedback_service.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/answer_badge.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/game_header.dart';
import '../models/word_question.dart';
import '../models/wizard_level.dart';
import '../services/word_generator.dart';
import '../services/wizard_state.dart';
import 'wizard_result_screen.dart';

/// Word Wizard gameplay for a single spellbook level, timed for a record.
class WizardGameScreen extends StatefulWidget {
  const WizardGameScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.level,
  });

  final WizardState state;
  final PlayerProfile profile;
  final WizardLevel level;

  @override
  State<WizardGameScreen> createState() => _WizardGameScreenState();
}

class _WizardGameScreenState extends State<WizardGameScreen> {
  late final List<WordQuestion> _questions;
  // The language resolved once in initState; drives Hebrew vs English question
  // generation and the text-to-speech voice.
  late final AppLang _lang;
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
    // Non-listening lookup is safe in initState; falls back to English when no
    // L10n ancestor exists (e.g. the plain English speaker test).
    _lang = L10n.read(context).lang;
    _questions = WordQuestionGenerator.forLevel(widget.level, lang: _lang);
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

  // Reads the current question's correct word aloud. Routes through
  // FeedbackService so it respects the sound toggle; a no-op where
  // text-to-speech is unavailable.
  void _speakWord() {
    final word = _q.spokenWord;
    if (word.isEmpty) return;
    // Speak in the round's language. Hebrew speech needs an OS/browser he-IL
    // voice; where none is installed the JS layer stays silent (never throws,
    // never gates correctness).
    final ttsLang = _lang == AppLang.he ? 'he-IL' : 'en-US';
    FeedbackService(enabled: widget.state.soundOn).speak(word, lang: ttsLang);
  }

  void _onAnswer(int index) {
    if (_answered) return;
    final isRight = index == _q.correctIndex;
    final fb = FeedbackService(enabled: widget.state.soundOn);
    setState(() {
      _selectedIndex = index;
      _answered = true;
      final l = context.l10n;
      if (isRight) {
        _correct++;
        _feedback = l.wwCorrectFeedback;
        fb.correct();
      } else {
        _feedback = l.wwWrongFeedback(_q.choices[_q.correctIndex]);
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
        builder: (_) => WizardResultScreen(
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
                GameHeader(
                  title: widget.level.isBoss
                      ? '${widget.level.boss.emoji} ${widget.level.boss.name}'
                      : '${widget.level.chapter.emoji} ${widget.level.title}',
                  countLabel: '${_current + 1} / ${_questions.length}',
                  seconds: _elapsed,
                  progress: progress,
                  progressColor: const Color(0xFFEC407A),
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
                      const SizedBox(height: 10),
                      _SpeakerButton(
                        enabled: widget.state.soundOn,
                        onTap: _speakWord,
                      ),
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
                      // Bilingual helper: in Hebrew mode show the English
                      // meaning on a small LTR line so the panel stays an LTR
                      // island for the Latin text under an RTL layout.
                      if (_q.translation != null) ...[
                        const SizedBox(height: 8),
                        Directionality(
                          textDirection: TextDirection.ltr,
                          child: Text(
                            _q.translation!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.ink.withValues(alpha: 0.6),
                            ),
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

/// A big comic-style speaker button that reads the word aloud. Stays visible
/// for a stable layout; when sound is off it is greyed out and inert.
class _SpeakerButton extends StatelessWidget {
  const _SpeakerButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: enabled ? AppTheme.sky : Colors.grey.shade400,
          border: AppTheme.comicBorder,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppTheme.comicShadow(offset: 4),
        ),
        child: const Icon(
          Icons.volume_up_rounded,
          color: Colors.white,
          size: 36,
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
    // Shrink the label font for long Hebrew words so RTL choices (which can be
    // 6-7 letters) never overflow the 2-column tiles. English rendering is
    // left untouched (always 22pt) so the English game stays byte-identical.
    final isHebrew =
        question.choices.any((c) => RegExp(r'[\u0590-\u05FF]').hasMatch(c));
    final longest = question.choices.fold<int>(
      0,
      (max, c) => c.length > max ? c.length : max,
    );
    final fontSize = !isHebrew || longest <= 5
        ? 22.0
        : longest <= 7
            ? 19.0
            : 17.0;
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
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ComicButton(
                    label: question.choices[index],
                    fontSize: fontSize,
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
