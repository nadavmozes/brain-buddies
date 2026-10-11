import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/all_games_back_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/sound_toggle_button.dart';
import '../../../core/widgets/star_coin_hud.dart';
import '../models/time_world.dart';
import '../services/clock_state.dart';
import 'clock_trail_screen.dart';

/// Clock Hero landing screen: title, HUD, and the time-of-day world select.
class ClockHeroHome extends StatelessWidget {
  const ClockHeroHome({super.key, required this.state, required this.profile});

  final ClockState state;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    const AllGamesBackButton(),
                    const Spacer(),
                    AnimatedBuilder(
                      animation: Listenable.merge([state, profile]),
                      builder: (_, __) => StarCoinHud(
                        stars: state.totalStars,
                        coins: profile.coins,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const _TitleBanner(),
                const SizedBox(height: 16),
                Text(
                  context.l10n.pickTimeOfDay,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                for (final world in TimeWorld.values) ...[
                  _WorldCard(state: state, profile: profile, world: world),
                  const SizedBox(height: 14),
                ],
                const SizedBox(height: 4),
                AnimatedBuilder(
                  animation: profile,
                  builder: (_, __) => SoundToggleButton(
                    soundOn: profile.soundOn,
                    onToggle: () {
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

class _WorldCard extends StatelessWidget {
  const _WorldCard(
      {required this.state, required this.profile, required this.world});

  final ClockState state;
  final PlayerProfile profile;
  final TimeWorld world;

  int _worldStars() {
    final trail = ClockMap.trail(world);
    return trail.levels.fold(0, (sum, l) => sum + state.stars(l.id));
  }

  @override
  Widget build(BuildContext context) {
    final maxStars = ClockMap.levelsPerTrail * 3;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ClockTrailScreen(state: state, profile: profile, world: world),
          ),
        );
      },
      child: ComicPanel(
        color: world.color,
        child: Row(
          children: [
            Text(world.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      context.l10n.trailLabel(context.tr(
                          'ch.world.label', world.name, world.label)),
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        shadows: [
                          Shadow(color: AppTheme.ink, offset: Offset(2, 2)),
                        ],
                      )),
                  const SizedBox(height: 2),
                  Text(
                      context.tr(
                          'ch.world.subtitle', world.name, world.subtitle),
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
                        Text(' ${_worldStars()} / $maxStars',
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
            Transform.flip(
              flipX: Directionality.of(context) == TextDirection.rtl,
              child: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white, size: 34),
            ),
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
        color: const Color(0xFFFF9800),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          children: const [
            Text('CLOCK',
                style: TextStyle(
                  fontSize: 46,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  // Match the other games' banner strategy: white text + ink
                  // drop shadow. Legible on the orange panel (the "HERO" word
                  // below already uses this same white-on-orange + ink shadow).
                  color: Colors.white,
                  letterSpacing: 2,
                  shadows: [Shadow(color: AppTheme.ink, offset: Offset(3, 3))],
                )),
            Text('HERO',
                style: TextStyle(
                  fontSize: 42,
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
