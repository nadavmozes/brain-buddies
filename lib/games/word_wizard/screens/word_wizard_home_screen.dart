import 'package:flutter/material.dart';

import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/coin_pill.dart';
import '../../../core/widgets/comic_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../models/wizard_level.dart';
import '../services/wizard_state.dart';
import 'spellbook_map_screen.dart';

/// Word Wizard landing screen: title, HUD, and the chapter (spellbook) select.
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
                      animation: Listenable.merge([state, profile]),
                      builder: (_, __) => Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppTheme.accent, size: 22),
                          Text(' ${state.totalStars} ',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w900)),
                          const SizedBox(width: 8),
                          CoinPill(amount: profile.coins),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _TitleBanner(),
                const SizedBox(height: 16),
                const Text(
                  'Pick a chapter to cast spells!',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                for (final chapter in WizardChapter.values) ...[
                  _ChapterCard(
                      state: state, profile: profile, chapter: chapter),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 4),
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
}

class _ChapterCard extends StatelessWidget {
  const _ChapterCard(
      {required this.state, required this.profile, required this.chapter});

  final WizardState state;
  final PlayerProfile profile;
  final WizardChapter chapter;

  int _chapterStars() {
    final path = WizardMap.path(chapter);
    return path.levels.fold(0, (sum, l) => sum + state.stars(l.id));
  }

  @override
  Widget build(BuildContext context) {
    final maxStars = WizardMap.levelsPerChapter * 3;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SpellbookMapScreen(
                state: state, profile: profile, chapter: chapter),
          ),
        );
      },
      child: ComicPanel(
        color: chapter.color,
        child: Row(
          children: [
            Text(chapter.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${chapter.label} Chapter',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: AppTheme.ink, offset: Offset(2, 2)),
                        ],
                      )),
                  const SizedBox(height: 2),
                  Text(chapter.subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white)),
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: state,
                    builder: (_, __) => Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppTheme.accent, size: 20),
                        Text(' ${_chapterStars()} / $maxStars',
                            style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.white, size: 34),
          ],
        ),
      ),
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
