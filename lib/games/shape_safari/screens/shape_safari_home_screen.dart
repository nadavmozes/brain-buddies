import 'package:flutter/material.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/player_profile.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/all_games_back_button.dart';
import '../../../core/widgets/comic_panel.dart';
import '../../../core/widgets/sound_toggle_button.dart';
import '../../../core/widgets/star_coin_hud.dart';
import '../models/habitat.dart';
import '../models/safari_level.dart';
import '../services/safari_state.dart';
import 'trail_map_screen.dart';

/// Shape Safari landing screen: title, HUD, and the habitat (world) select.
class ShapeSafariHome extends StatelessWidget {
  const ShapeSafariHome({super.key, required this.state, required this.profile});

  final SafariState state;
  final PlayerProfile profile;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF80CBC4), AppTheme.paper],
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
                _TitleBanner(),
                const SizedBox(height: 16),
                Text(
                  context.l10n.pickHabitat,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                for (final habitat in Habitat.values) ...[
                  _HabitatCard(
                      state: state, profile: profile, habitat: habitat),
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

class _HabitatCard extends StatelessWidget {
  const _HabitatCard(
      {required this.state, required this.profile, required this.habitat});

  final SafariState state;
  final PlayerProfile profile;
  final Habitat habitat;

  int _habitatStars() {
    final trail = SafariMap.trail(habitat);
    return trail.levels.fold(0, (sum, l) => sum + state.stars(l.id));
  }

  @override
  Widget build(BuildContext context) {
    final maxStars = SafariMap.levelsPerTrail * 3;
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TrailMapScreen(
                state: state, profile: profile, habitat: habitat),
          ),
        );
      },
      child: ComicPanel(
        color: habitat.color,
        child: Row(
          children: [
            Text(habitat.emoji, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                      context.l10n.trailLabel(context.tr(
                          'ss.habitat.label', habitat.name, habitat.label)),
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
                      context.tr('ss.habitat.subtitle', habitat.name,
                          habitat.subtitle),
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
                        Text(' ${_habitatStars()} / $maxStars',
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
  _TitleBanner();

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.03,
      child: ComicPanel(
        color: const Color(0xFF26A69A),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Column(
          children: [
            Text(context.l10n.ssLogoLine1,
                style: const TextStyle(
                  fontSize: 42,
                  height: 1.0,
                  fontWeight: FontWeight.w900,
                  color: AppTheme.accent,
                  letterSpacing: 2,
                  shadows: [Shadow(color: AppTheme.ink, offset: Offset(3, 3))],
                )),
            Text(context.l10n.ssLogoLine2,
                style: const TextStyle(
                  fontSize: 38,
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

