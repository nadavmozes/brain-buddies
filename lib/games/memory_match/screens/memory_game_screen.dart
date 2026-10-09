import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../core/services/feedback_service.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/timer_chip.dart';
import '../models/memory_level.dart';
import '../services/memory_state.dart';
import 'memory_result_screen.dart';

/// One card on the board.
class _Card {
  _Card(this.emoji);
  final String emoji;
  bool revealed = false;
  bool matched = false;
}

/// Memory Match gameplay: flip two cards to find pairs. Finishing the board
/// scores stars by how few wrong flips were made.
class MemoryGameScreen extends StatefulWidget {
  const MemoryGameScreen({
    super.key,
    required this.state,
    required this.profile,
    required this.level,
  });

  final MemoryState state;
  final PlayerProfile profile;
  final MemoryLevel level;

  @override
  State<MemoryGameScreen> createState() => _MemoryGameScreenState();
}

class _MemoryGameScreenState extends State<MemoryGameScreen> {
  late final List<_Card> _cards;
  int _matchedPairs = 0;
  int _wrongFlips = 0;
  bool _busy = false; // locked while a mismatched pair is shown
  int? _firstIndex;

  final Stopwatch _stopwatch = Stopwatch();
  Timer? _ticker;
  int _elapsed = 0;

  @override
  void initState() {
    super.initState();
    _cards = _buildDeck();
    _stopwatch.start();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = _stopwatch.elapsed.inSeconds);
    });
  }

  List<_Card> _buildDeck() {
    final rng = Random();
    final deck = List<String>.from(widget.level.world.deck)..shuffle(rng);
    final chosen = deck.take(widget.level.pairs).toList();
    final cards = <_Card>[];
    for (final e in chosen) {
      cards.add(_Card(e));
      cards.add(_Card(e));
    }
    cards.shuffle(rng);
    return cards;
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  void _onTap(int index) {
    if (_busy) return;
    final card = _cards[index];
    if (card.revealed || card.matched) return;
    final fb = FeedbackService(enabled: widget.state.soundOn);

    setState(() => card.revealed = true);

    if (_firstIndex == null) {
      _firstIndex = index;
      fb.click();
      return;
    }

    // Second card flipped.
    final first = _cards[_firstIndex!];
    if (first.emoji == card.emoji) {
      // Match!
      fb.correct();
      setState(() {
        first.matched = true;
        card.matched = true;
        _matchedPairs++;
        _firstIndex = null;
      });
      if (_matchedPairs == widget.level.pairs) {
        _finish();
      }
    } else {
      // Mismatch: briefly show, then flip both back.
      _wrongFlips++;
      fb.wrong();
      _busy = true;
      final firstIdx = _firstIndex!;
      _firstIndex = null;
      Future.delayed(const Duration(milliseconds: 800), () {
        if (!mounted) return;
        setState(() {
          _cards[firstIdx].revealed = false;
          card.revealed = false;
          _busy = false;
        });
      });
    }
  }

  Future<void> _finish() async {
    _stopwatch.stop();
    _ticker?.cancel();
    final outcome = await widget.state.completeLevel(
      profile: widget.profile,
      level: widget.level,
      wrongFlips: _wrongFlips,
      elapsedSeconds: _stopwatch.elapsed.inSeconds,
    );
    if (!mounted) return;
    if (outcome.stars == 3 || outcome.isNewFastest || outcome.bossBeaten) {
      FeedbackService(enabled: widget.state.soundOn).celebrate();
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MemoryResultScreen(
          state: widget.state,
          profile: widget.profile,
          level: widget.level,
          outcome: outcome,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final world = widget.level.world;
    final progress = _matchedPairs / widget.level.pairs;
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
                    Text('$_matchedPairs / ${widget.level.pairs}',
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
                const SizedBox(height: 16),
                Expanded(
                  child: _CardGrid(
                    cards: _cards,
                    columns: widget.level.columns,
                    worldColor: world.color,
                    onTap: _onTap,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CardGrid extends StatelessWidget {
  const _CardGrid({
    required this.cards,
    required this.columns,
    required this.worldColor,
    required this.onTap,
  });

  final List<_Card> cards;
  final int columns;
  final Color worldColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.zero,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.82,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) {
        final card = cards[i];
        final showFace = card.revealed || card.matched;
        return GestureDetector(
          onTap: () => onTap(i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: card.matched
                  ? AppTheme.success
                  : (showFace ? Colors.white : worldColor),
              border: Border.all(color: AppTheme.ink, width: 3),
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppTheme.comicShadow(offset: showFace ? 2 : 4),
            ),
            child: Text(
              showFace ? card.emoji : '❓',
              style: TextStyle(
                fontSize: 34,
                color: showFace ? null : Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}
