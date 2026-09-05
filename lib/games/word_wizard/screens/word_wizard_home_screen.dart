import 'package:flutter/material.dart';

import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coin_pill.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/timer_chip.dart';
import '../services/wizard_state.dart';
import 'wizard_game_screen.dart';

/// Word Wizard landing screen.
class WordWizardHome extends StatelessWidget {
  const WordWizardHome({super.key, required this.state, required this.profile});

  final WizardState state;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).maybePop(),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.arrow_back_rounded, color: AppTheme.ink),
                          Text('All Games',
                              style: TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink)),
                        ],
                      ),
                    ),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: profile,
                      builder: (_, __) => CoinPill(amount: profile.coins),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _TitleBanner(),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: state,
                  builder: (_, __) => ComicPanel(
                    color: AppTheme.accent,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _stat('Best',
                            '${state.bestCorrect}/${WizardGameScreen.questionsPerRound}'),
                        _fastest(),
                        _stat('Rounds', '${state.roundsPlayed}'),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ComicButton(
                  label: 'PLAY',
                  icon: Icons.play_arrow_rounded,
                  fontSize: 26,
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => WizardGameScreen(
                            state: state, profile: profile),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),
                AnimatedBuilder(
                  animation: profile,
                  builder: (_, __) => ComicButton(
                    label: profile.soundOn ? 'Sound: On' : 'Sound: Off',
                    icon: profile.soundOn
                        ? Icons.volume_up_rounded
                        : Icons.volume_off_rounded,
                    color: Colors.white,
                    textColor: AppTheme.ink,
                    fontSize: 16,
                    onPressed: () {
                      final v = !profile.soundOn;
                      profile.setSoundOn(v);
                      state.setSoundOn(v);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style:
                const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        Text(label,
            style:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _fastest() {
    return Column(
      children: [
        state.hasFastest
            ? TimerChip(seconds: state.fastestSeconds)
            : const Text('—',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const Text('Fastest',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _TitleBanner extends StatelessWidget {
  const _TitleBanner();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: ComicPanel(
        color: const Color(0xFFEC407A),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: const [
            Text('WORD',
                style: TextStyle(
                  fontSize: 46,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.accent,
                  letterSpacing: 2,
                  shadows: [Shadow(color: AppTheme.ink, offset: Offset(3, 3))],
                )),
            Text('WIZARD',
                style: TextStyle(
                  fontSize: 40,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [Shadow(color: AppTheme.ink, offset: Offset(3, 3))],
                )),
          ],
        ),
      ),
    );
  }
}
