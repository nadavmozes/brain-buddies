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
import '../models/money_level.dart';
import '../models/money_question.dart';
import '../services/money_generator.dart';
import '../services/money_state.dart';
import '../widgets/coin_chip.dart';
import '../widgets/coin_info_map.dart';
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
  late final AppLang _lang;
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
    // Non-listening lookup is safe in initState; falls back to English when no
    // L10n ancestor exists (matches the Word Wizard pattern).
    _lang = L10n.read(context).lang;
    _questions = MoneyQuestionGenerator.forLevel(widget.level, lang: _lang);
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
      _lastRight = isRight;
      if (isRight) {
        _correct++;
        _feedback = l.moneyCorrect;
        fb.correct();
      } else {
        _feedback = l.moneyWrong;
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
                GameHeader(
                  title: widget.level.isBoss
                      ? '${widget.level.guardian.emoji} ${widget.level.guardian.name}'
                      : '${world.emoji} ${widget.level.title}',
                  countLabel: '${_current + 1} / ${_questions.length}',
                  seconds: _elapsed,
                  progress: progress,
                  progressColor: world.color,
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
                        const SizedBox(height: 8),
                        _CoinsHelpButton(
                          currency: _lang == AppLang.he
                              ? Currency.ils
                              : Currency.usd,
                        ),
                        const SizedBox(height: 10),
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
            _CoinPanel(coins: _q.pile!.coins),
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
      case MoneyQuestionType.makeChange:
        return _TextChoices(
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
  const _CoinPanel({required this.coins});
  final List<Coin> coins;

  @override
  Widget build(BuildContext context) {
    return ComicPanel(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: CoinChipRow(coins: coins),
    );
  }
}

/// A small "?" affordance that opens the Coin Info Map for the current currency.
class _CoinsHelpButton extends StatelessWidget {
  const _CoinsHelpButton({required this.currency});
  final Currency currency;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: GestureDetector(
        onTap: () => CoinInfoMap.show(context, currency),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.accent,
            border: AppTheme.comicBorder,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppTheme.comicShadow(offset: 3),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.help_outline_rounded,
                  color: AppTheme.ink, size: 20),
              const SizedBox(width: 6),
              Text(
                context.l10n.coinsButton,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.ink,
                ),
              ),
            ],
          ),
        ),
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
        // Coin/number amounts (e.g. "30¢") read left-to-right even in Hebrew.
        return Directionality(
          textDirection: TextDirection.ltr,
          child: Wrap(
          spacing: 14,
          runSpacing: 14,
          alignment: WrapAlignment.center,
          children: List.generate(question.textChoices!.length, (index) {
            return SizedBox(
              width: tileWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  ComicButton(
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
          ),
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
            return Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
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
                    child: CoinChipRow(
                        coins: piles[index].coins, chipSize: 42),
                  ),
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
            return Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
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
                    child: CoinChipRow(
                        coins: piles[index].coins, chipSize: 40),
                  ),
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
            );
          }),
        );
      },
    );
  }
}
